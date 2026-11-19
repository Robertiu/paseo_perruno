import { getRedis } from '../redis.js';
import { keys } from '../keys.js';
import { levelFor, isoWeek } from '../game.js';

const WEEK_TTL_SECONDS = 21 * 24 * 3600;

const boardKey = (scope, day) => (scope === 'week' ? keys.leaderboardWeek(isoWeek(day)) : keys.leaderboardGlobal);

export async function addXp(walkerId, delta, day) {
  const redis = await getRedis();
  const week = keys.leaderboardWeek(isoWeek(day));
  await redis
    .multi()
    .zIncrBy(keys.leaderboardGlobal, delta, walkerId)
    .zIncrBy(week, delta, walkerId)
    .expire(week, WEEK_TTL_SECONDS)
    .exec();
}

/** Resta XP de la semana solo si esa tabla sigue viva (no resucita claves expiradas). */
export async function removeXp(walkerId, delta, day) {
  const redis = await getRedis();
  const week = keys.leaderboardWeek(isoWeek(day));
  const multi = redis.multi().zIncrBy(keys.leaderboardGlobal, -delta, walkerId);
  if (await redis.exists(week)) multi.zIncrBy(week, -delta, walkerId);
  await multi.exec();
}

/** Top N con nombre y nivel, más la posición del usuario que consulta. */
export async function getLeaderboard(scope, day, walkerId, limit = 20) {
  const redis = await getRedis();
  const key = boardKey(scope, day);
  const top = await redis.zRangeWithScores(key, 0, limit - 1, { REV: true });

  const pipe = redis.multi();
  for (const { value } of top) pipe.hGet(keys.walker(value), 'name');
  const names = top.length ? await pipe.exec() : [];

  const entries = top.map(({ value, score }, i) => ({
    rank: i + 1,
    walkerId: value,
    name: names[i] ?? 'Anónimo',
    xp: score,
    level: levelFor(score),
    isMe: value === walkerId,
  }));

  const [rank, score] = await Promise.all([redis.zRevRank(key, walkerId), redis.zScore(key, walkerId)]);
  return { scope, entries, me: rank === null ? null : { rank: rank + 1, xp: score ?? 0 } };
}

export async function globalRank(walkerId) {
  const redis = await getRedis();
  const rank = await redis.zRevRank(keys.leaderboardGlobal, walkerId);
  return rank === null ? null : rank + 1;
}
