import { getRedis } from '../redis.js';
import { keys } from '../keys.js';
import { challengeFor } from '../game.js';

const TTL_SECONDS = 36 * 3600; // el reto desaparece solo al día siguiente

/** Crea el reto del día si no existe (idempotente) y lo devuelve. */
export async function getChallenge(day, walkerId) {
  const redis = await getRedis();
  const c = challengeFor(day);
  const [, , done] = await redis
    .multi()
    .hSet(keys.challenge(day), { id: c.id, title: c.title, type: c.type, target: c.target, bonusXp: c.bonusXp })
    .expire(keys.challenge(day), TTL_SECONDS)
    .sIsMember(keys.challengeDone(day), walkerId)
    .exec();
  return { ...c, day, completed: Boolean(done) };
}

/** SADD devuelve 1 solo la primera vez: así el bono se otorga una única vez. */
export async function markCompleted(day, walkerId) {
  const redis = await getRedis();
  const [added] = await redis.multi().sAdd(keys.challengeDone(day), walkerId).expire(keys.challengeDone(day), TTL_SECONDS).exec();
  return added === 1;
}
