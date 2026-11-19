import { HttpError } from './errors.js';
import { resolveSession } from './services/walkers.js';

export async function requireAuth(req, _res, next) {
  const token = (req.get('authorization') ?? '').replace(/^Bearer\s+/i, '');
  if (!token) throw new HttpError(401, 'Falta el token de sesión.');
  const walkerId = await resolveSession(token);
  if (!walkerId) throw new HttpError(401, 'Sesión expirada. Inicia sesión de nuevo.');
  req.walkerId = walkerId;
  req.token = token;
  next();
}

/** Día local del cliente (yyyy-MM-dd) o, si no lo manda, el día UTC del servidor. */
export const dayOf = (req) => (/^\d{4}-\d{2}-\d{2}$/.test(req.query.day ?? '') ? req.query.day : new Date().toISOString().slice(0, 10));
