import { randomUUID } from 'node:crypto';
import { getRedis } from '../redis.js';
import { keys } from '../keys.js';
import { config } from '../config.js';
import { HttpError } from '../errors.js';
import { BADGES, earnedBadges, levelFor, meetsChallenge, nextStreak, activeStreak, walkXp } from '../game.js';
import { getWalker } from './walkers.js';
import { addXp, removeXp, globalRank } from './leaderboard.js';
import { getChallenge, markCompleted } from './challenge.js';

const STREAK_TTL_SECONDS = 48 * 3600; // un día sin pasear y la racha caduca sola
const DAY_RE = /^\d{4}-\d{2}-\d{2}$/;

const toWalk = (h) => ({
  id: h.id,
  dogName: h.dogName,
  notes: h.notes,
  durationMinutes: Number(h.durationMinutes),
  createdAt: h.createdAt,
  localDay: h.localDay,
  imagePath: h.imagePath || null,
  latitude: h.latitude ? Number(h.latitude) : null,
  longitude: h.longitude ? Number(h.longitude) : null,
  xp: Number(h.xp),
});

function validate(input, { partial = false } = {}) {
  const out = {};
  if (!partial || input.dogName !== undefined) {
    const dogName = String(input.dogName ?? '').trim();
    if (!dogName) throw new HttpError(400, 'El nombre del perro es obligatorio.');
    out.dogName = dogName.slice(0, 40);
  }
  if (!partial || input.durationMinutes !== undefined) {
    const minutes = Number(input.durationMinutes);
    if (!Number.isInteger(minutes) || minutes <= 0 || minutes > 600) throw new HttpError(400, 'La duración debe estar entre 1 y 600 minutos.');
    out.durationMinutes = minutes;
  }
  if (!partial || input.notes !== undefined) out.notes = String(input.notes ?? '').trim().slice(0, 1000);
  return out;
}

// ---- Lectura ----------------------------------------------------------------

export async function listWalks(walkerId) {
  const redis = await getRedis();
  const ids = await redis.zRange(keys.walkerWalks(walkerId), 0, -1, { REV: true });
  if (!ids.length) return [];
  const pipe = redis.multi();
  for (const id of ids) pipe.hGetAll(keys.walk(id));
  const rows = await pipe.exec();
  return rows.filter((h) => h.id).map(toWalk);
}

async function ownedWalk(walkerId, walkId) {
  const redis = await getRedis();
  const h = await redis.hGetAll(keys.walk(walkId));
  if (!h.id || h.walkerId !== walkerId) throw new HttpError(404, 'Paseo no encontrado.');
  return h;
}

export async function getWalk(walkerId, walkId) {
  return toWalk(await ownedWalk(walkerId, walkId));
}

// ---- Alta con recompensas ---------------------------------------------------

/**
 * Crea el paseo y calcula la recompensa: XP, racha, insignias, reto del día
 * y ranking. El paseo y los contadores se escriben en una transacción MULTI.
 */
export async function createWalk(walkerId, input, { skipCooldown = false } = {}) {
  const redis = await getRedis();
  const data = validate(input);
  const localDay = DAY_RE.test(input.localDay ?? '') ? input.localDay : new Date().toISOString().slice(0, 10);
  const createdAt = input.createdAt ? new Date(input.createdAt) : new Date();
  if (Number.isNaN(createdAt.getTime())) throw new HttpError(400, 'Fecha inválida.');

  if (!skipCooldown) {
    const ok = await redis.set(keys.cooldown(walkerId), '1', { EX: config.walkCooldownSeconds, NX: true });
    if (!ok) throw new HttpError(429, `Espera ${config.walkCooldownSeconds} s antes de registrar otro paseo.`);
  }

  const before = await getWalker(walkerId);
  if (!before) throw new HttpError(404, 'Usuario no encontrado.');

  const hasPhoto = Boolean(input.imagePath);
  const hasLocation = input.latitude != null && input.longitude != null;
  const hasNotes = data.notes.length > 0;
  const flags = { durationMinutes: data.durationMinutes, hasPhoto, hasNotes, hasLocation };

  // Racha: HASH con TTL de 48 h; si el hueco es mayor a un día, reinicia.
  const prevStreak = await redis.hGetAll(keys.streak(walkerId));
  const streak = nextStreak(
    prevStreak.lastDay ? { count: Number(prevStreak.count), lastDay: prevStreak.lastDay } : null,
    localDay,
  );

  // Reto diario: el bono se otorga solo la primera vez que se cumple.
  const challenge = await getChallenge(localDay, walkerId);
  let challengeBonus = 0;
  let challengeCompleted = false;
  if (!challenge.completed && meetsChallenge(challenge, flags) && (await markCompleted(localDay, walkerId))) {
    challengeBonus = challenge.bonusXp;
    challengeCompleted = true;
  }

  const xp = walkXp(flags, streak) + challengeBonus;
  const id = randomUUID();
  const fields = {
    id, walkerId, dogName: data.dogName, notes: data.notes, durationMinutes: data.durationMinutes,
    createdAt: createdAt.toISOString(), localDay, xp,
    ...(hasPhoto && { imagePath: input.imagePath }),
    ...(hasLocation && { latitude: input.latitude, longitude: input.longitude }),
  };

  await redis
    .multi()
    .hSet(keys.walk(id), fields)
    .zAdd(keys.walkerWalks(walkerId), { score: createdAt.getTime(), value: id })
    .hIncrBy(keys.walker(walkerId), 'walks', 1)
    .hIncrBy(keys.walker(walkerId), 'minutes', data.durationMinutes)
    .hIncrBy(keys.walker(walkerId), 'xp', xp)
    .hIncrBy(keys.walker(walkerId), 'photos', hasPhoto ? 1 : 0)
    .hIncrBy(keys.walker(walkerId), 'locations', hasLocation ? 1 : 0)
    .hSet(keys.streak(walkerId), { count: streak, lastDay: localDay })
    .expire(keys.streak(walkerId), STREAK_TTL_SECONDS)
    .exec();
  await addXp(walkerId, xp, localDay);

  // Insignias nuevas: SADD de todas las merecidas; las que devuelven 1 son nuevas.
  const after = await getWalker(walkerId);
  const stats = { ...after, streak, longestWalk: data.durationMinutes };
  const newBadges = [];
  for (const badge of earnedBadges(stats)) {
    if ((await redis.sAdd(keys.walkerBadges(walkerId), badge.id)) === 1) newBadges.push(publicBadge(badge));
  }

  return {
    walk: toWalk({ ...fields, imagePath: fields.imagePath ?? '', latitude: fields.latitude ?? '', longitude: fields.longitude ?? '' }),
    reward: {
      xp,
      challengeBonus,
      challengeCompleted,
      streak,
      newBadges,
      levelUp: levelFor(after.xp) > levelFor(before.xp) ? levelFor(after.xp) : null,
      totalXp: after.xp,
      rank: await globalRank(walkerId),
    },
  };
}

// ---- Edición y baja ---------------------------------------------------------

/** Edita nombre, duración o notas. El XP ya otorgado no se recalcula. */
export async function updateWalk(walkerId, walkId, input) {
  const redis = await getRedis();
  const current = await ownedWalk(walkerId, walkId);
  const changes = validate(input, { partial: true });
  const multi = redis.multi().hSet(keys.walk(walkId), changes);
  if (changes.durationMinutes !== undefined) {
    multi.hIncrBy(keys.walker(walkerId), 'minutes', changes.durationMinutes - Number(current.durationMinutes));
  }
  await multi.exec();
  return getWalk(walkerId, walkId);
}

/** Borra el paseo y revierte sus contadores y el XP que dio. */
export async function deleteWalk(walkerId, walkId) {
  const redis = await getRedis();
  const w = await ownedWalk(walkerId, walkId);
  await redis
    .multi()
    .del(keys.walk(walkId))
    .zRem(keys.walkerWalks(walkerId), walkId)
    .hIncrBy(keys.walker(walkerId), 'walks', -1)
    .hIncrBy(keys.walker(walkerId), 'minutes', -Number(w.durationMinutes))
    .hIncrBy(keys.walker(walkerId), 'xp', -Number(w.xp))
    .hIncrBy(keys.walker(walkerId), 'photos', w.imagePath ? -1 : 0)
    .hIncrBy(keys.walker(walkerId), 'locations', w.latitude ? -1 : 0)
    .exec();
  await removeXp(walkerId, Number(w.xp), w.localDay);
}

// ---- Perfil -----------------------------------------------------------------

const publicBadge = ({ id, name, emoji, description }) => ({ id, name, emoji, description });

export async function getProfile(walkerId, today) {
  const redis = await getRedis();
  const walker = await getWalker(walkerId);
  if (!walker) throw new HttpError(404, 'Usuario no encontrado.');
  const [streakHash, earned, challenge, rank] = await Promise.all([
    redis.hGetAll(keys.streak(walkerId)),
    redis.sMembers(keys.walkerBadges(walkerId)),
    getChallenge(today, walkerId),
    globalRank(walkerId),
  ]);
  const level = levelFor(walker.xp);
  const floor = (level - 1) ** 2 * 100;
  const ceiling = level ** 2 * 100;
  return {
    ...walker,
    level,
    xpIntoLevel: walker.xp - floor,
    xpForNextLevel: ceiling - floor,
    rank,
    streak: activeStreak(streakHash.lastDay ? { count: Number(streakHash.count), lastDay: streakHash.lastDay } : null, today),
    badges: BADGES.map((b) => ({ ...publicBadge(b), earned: earned.includes(b.id) })),
    challenge,
  };
}
