import { createClient } from 'redis';
import { assertConfig, config } from './config.js';

let client;

/** Conexión única al servicio administrado (driver oficial node-redis). */
export async function getRedis() {
  if (client) return client;
  assertConfig();
  client = createClient({
    url: config.redisUrl,
    socket: { reconnectStrategy: (retries) => Math.min(retries * 200, 3000) },
  });
  client.on('error', (e) => console.error('[redis]', e.message));
  await client.connect();
  return client;
}

export async function closeRedis() {
  if (client) await client.quit().catch(() => client.destroy());
  client = undefined;
}
