import 'dotenv/config';

export const config = {
  redisUrl: process.env.REDIS_URL,
  port: Number(process.env.PORT ?? 3000),
  walkCooldownSeconds: Number(process.env.WALK_COOLDOWN_SECONDS ?? 20),
  sessionTtlSeconds: 60 * 60 * 24 * 30,
};

export function assertConfig() {
  if (!config.redisUrl) {
    throw new Error('Falta REDIS_URL. Copia .env.example a .env y pega la URL de tu instancia en la nube.');
  }
}
