// Lista las conexiones abiertas a Redis. Uso: npm run clientes
import { getRedis, closeRedis } from '../src/redis.js';

const redis = await getRedis();
const rows = (await redis.sendCommand(['CLIENT', 'LIST'])).split('\n').filter(Boolean);
const get = (line, key) => (line.match(new RegExp(`(?:^| )${key}=([^ ]*)`)) || [])[1] || '-';

console.log(`Conexiones abiertas: ${rows.length} (una es esta consulta)\n`);
for (const l of rows) {
  const who = get(l, 'lib-name') !== '-' ? get(l, 'lib-name') : get(l, 'name').split('-')[0];
  console.log(`${who.padEnd(14)} ${get(l, 'addr').padEnd(24)} abierta ${get(l, 'age')}s · inactiva ${get(l, 'idle')}s · último: ${get(l, 'cmd')}`);
}
await closeRedis();
