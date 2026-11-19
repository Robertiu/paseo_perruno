import { randomUUID, randomBytes } from 'node:crypto';
import { getRedis } from '../redis.js';
import { keys } from '../keys.js';
import { config } from '../config.js';
import { HttpError } from '../errors.js';

/** Alta de usuario: reserva el nombre con HSETNX y abre una sesión con TTL. */
export async function createWalker(rawName) {
  const name = String(rawName ?? '').trim();
  if (name.length < 2 || name.length > 20) throw new HttpError(400, 'El nombre debe tener entre 2 y 20 caracteres.');

  const redis = await getRedis();
  const id = randomUUID();
  const reserved = await redis.hSetNX(keys.walkerByName, name.toLowerCase(), id);
  if (!reserved) throw new HttpError(409, 'Ese nombre ya está en uso.');

  await redis.hSet(keys.walker(id), {
    id, name, xp: 0, walks: 0, minutes: 0, photos: 0, locations: 0, createdAt: new Date().toISOString(),
  });
  // Entra al ranking global desde el inicio con 0 XP.
  await redis.zAdd(keys.leaderboardGlobal, { score: 0, value: id });
  return { walker: await getWalker(id), token: await openSession(id) };
}

/** Inicio de sesión por nombre (sin contraseña: es un proyecto académico). */
export async function loginWalker(rawName) {
  const redis = await getRedis();
  const id = await redis.hGet(keys.walkerByName, String(rawName ?? '').trim().toLowerCase());
  if (!id) throw new HttpError(404, 'No existe un usuario con ese nombre.');
  return { walker: await getWalker(id), token: await openSession(id) };
}

export async function openSession(walkerId) {
  const redis = await getRedis();
  const token = randomBytes(24).toString('hex');
  await redis.set(keys.session(token), walkerId, { EX: config.sessionTtlSeconds });
  return token;
}

/** Resuelve el token y renueva su TTL (sesión deslizante). */
export async function resolveSession(token) {
  const redis = await getRedis();
  const id = await redis.getEx(keys.session(token), { EX: config.sessionTtlSeconds });
  return id ?? null;
}

export async function closeSession(token) {
  const redis = await getRedis();
  await redis.del(keys.session(token));
}

export async function getWalker(id) {
  const redis = await getRedis();
  const h = await redis.hGetAll(keys.walker(id));
  if (!h.id) return null;
  return {
    id: h.id,
    name: h.name,
    xp: Number(h.xp),
    walks: Number(h.walks),
    minutes: Number(h.minutes),
    photos: Number(h.photos),
    locations: Number(h.locations),
  };
}
