import { config } from './config.js';
import { getRedis } from './redis.js';
import { buildApp } from './app.js';

await getRedis(); // falla pronto si la URL de la nube es incorrecta
buildApp().listen(config.port, '0.0.0.0', () => console.log(`API lista en http://0.0.0.0:${config.port}`));
