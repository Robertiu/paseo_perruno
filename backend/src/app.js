import express from 'express';
import { getRedis } from './redis.js';
import { HttpError } from './errors.js';
import { requireAuth, dayOf } from './middleware.js';
import { createWalker, loginWalker, closeSession } from './services/walkers.js';
import { createWalk, deleteWalk, getProfile, getWalk, listWalks, updateWalk } from './services/walks.js';
import { getLeaderboard } from './services/leaderboard.js';
import { getChallenge } from './services/challenge.js';

export function buildApp() {
  const app = express();
  app.use(express.json({ limit: '100kb' }));

  app.get('/api/health', async (_req, res) => {
    const t = Date.now();
    await (await getRedis()).ping();
    res.json({ ok: true, redisLatencyMs: Date.now() - t });
  });

  // Sesiones
  app.post('/api/walkers', async (req, res) => res.status(201).json(await createWalker(req.body.name)));
  app.post('/api/login', async (req, res) => res.json(await loginWalker(req.body.name)));
  app.post('/api/logout', requireAuth, async (req, res) => {
    await closeSession(req.token);
    res.status(204).end();
  });

  // Todo lo demás exige sesión
  app.use('/api', requireAuth);

  app.get('/api/me', async (req, res) => res.json(await getProfile(req.walkerId, dayOf(req))));
  app.get('/api/challenge/today', async (req, res) => res.json(await getChallenge(dayOf(req), req.walkerId)));
  app.get('/api/leaderboard', async (req, res) => {
    const scope = req.query.scope === 'week' ? 'week' : 'global';
    res.json(await getLeaderboard(scope, dayOf(req), req.walkerId, Math.min(Number(req.query.limit) || 20, 50)));
  });

  // CRUD de paseos
  app.get('/api/walks', async (req, res) => res.json(await listWalks(req.walkerId)));
  app.get('/api/walks/:id', async (req, res) => res.json(await getWalk(req.walkerId, req.params.id)));
  app.post('/api/walks', async (req, res) => res.status(201).json(await createWalk(req.walkerId, req.body)));
  app.put('/api/walks/:id', async (req, res) => res.json(await updateWalk(req.walkerId, req.params.id, req.body)));
  app.delete('/api/walks/:id', async (req, res) => {
    await deleteWalk(req.walkerId, req.params.id);
    res.status(204).end();
  });

  app.use((_req, _res, next) => next(new HttpError(404, 'Ruta no encontrada.')));
  app.use((err, _req, res, _next) => {
    if (!(err instanceof HttpError)) console.error(err);
    res.status(err.status ?? 500).json({ error: err.status ? err.message : 'Error interno del servidor.' });
  });
  return app;
}
