// Datos iniciales: paseadores de ejemplo con paseos, rachas, insignias y ranking.
// Uso: npm run seed          (agrega datos)
//      npm run seed:reset    (borra todo paseo:* antes de poblar)
import { getRedis, closeRedis } from '../src/redis.js';
import { createWalker } from '../src/services/walkers.js';
import { createWalk } from '../src/services/walks.js';

const redis = await getRedis();

if (process.argv.includes('--reset')) {
  let deleted = 0;
  for await (const batch of redis.scanIterator({ MATCH: 'paseo:*', COUNT: 200 })) {
    const list = Array.isArray(batch) ? batch : [batch];
    if (list.length) deleted += await redis.del(list);
  }
  console.log(`Eliminadas ${deleted} claves paseo:*`);
}

const dayAgo = (n) => new Date(Date.now() - n * 86_400_000).toISOString().slice(0, 10);

const DOGS = ['Firulais', 'Luna', 'Max', 'Toby', 'Nala', 'Rocky', 'Coco', 'Bruno'];
const NOTES = ['Mucho sol y mucha energía.', 'Se portó increíble con otros perros.', '', 'Persiguió palomas en el parque.', 'Paseo tranquilo por la colonia.'];
// nombre, días con paseo seguidos hasta hoy, minutos base
const WALKERS = [
  ['Ana', 9, 55], ['Beto', 6, 40], ['Carla', 4, 35], ['Diego', 3, 30],
  ['Elena', 2, 25], ['Fer', 1, 20], ['Gabo', 5, 45],
];

let tokenDemo;
for (const [name, days, base] of WALKERS) {
  let created;
  try {
    created = await createWalker(name);
  } catch (e) {
    console.log(`- ${name}: ${e.message} (se omite)`);
    continue;
  }
  const { walker, token } = created;
  for (let d = days - 1; d >= 0; d--) {
    const i = d + name.length;
    const withLocation = i % 2 === 0;
    await createWalk(walker.id, {
      dogName: DOGS[i % DOGS.length],
      durationMinutes: base + (i % 4) * 5,
      notes: NOTES[i % NOTES.length],
      createdAt: new Date(Date.now() - d * 86_400_000).toISOString(),
      localDay: dayAgo(d),
      imagePath: i % 3 === 0 ? `/seed/${name}-${d}.jpg` : undefined,
      latitude: withLocation ? 19.43 + (i % 5) * 0.003 : undefined,
      longitude: withLocation ? -99.13 - (i % 5) * 0.003 : undefined,
    }, { skipCooldown: true });
  }
  if (name === 'Ana') tokenDemo = token;
  console.log(`+ ${name}: ${days} paseos`);
}

if (tokenDemo) console.log(`\nToken de demo (usuario Ana):\n${tokenDemo}`);
await closeRedis();
