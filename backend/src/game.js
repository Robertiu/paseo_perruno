// Reglas de gamificación: funciones puras, sin Redis, fáciles de probar.

export const XP = { base: 10, perMinute: 1, maxMinutes: 120, photo: 5, notes: 5, location: 5, streakStep: 2, streakCap: 10 };

export const BADGES = [
  { id: 'primer-paseo', name: 'Primer paseo', emoji: '🐾', description: 'Registra tu primer paseo', test: (s) => s.walks >= 1 },
  { id: 'paseador-5', name: 'Paseador', emoji: '🦮', description: '5 paseos registrados', test: (s) => s.walks >= 5 },
  { id: 'paseador-25', name: 'Paseador experto', emoji: '🏅', description: '25 paseos registrados', test: (s) => s.walks >= 25 },
  { id: 'racha-3', name: 'Constante', emoji: '🔥', description: 'Racha de 3 días', test: (s) => s.streak >= 3 },
  { id: 'racha-7', name: 'Imparable', emoji: '⚡', description: 'Racha de 7 días', test: (s) => s.streak >= 7 },
  { id: 'fotografo', name: 'Fotógrafo', emoji: '📸', description: '5 paseos con foto', test: (s) => s.photos >= 5 },
  { id: 'explorador', name: 'Explorador', emoji: '🧭', description: '5 paseos con ubicación', test: (s) => s.locations >= 5 },
  { id: 'maraton', name: 'Maratonista', emoji: '🏃', description: 'Un paseo de 60 min o más', test: (s) => s.longestWalk >= 60 },
  { id: 'nivel-5', name: 'Nivel 5', emoji: '⭐', description: 'Llega al nivel 5', test: (s) => levelFor(s.xp) >= 5 },
];

export const CHALLENGES = [
  { id: 'largo', title: 'Pasea 30 minutos o más', type: 'minutes', target: 30, bonusXp: 25 },
  { id: 'foto', title: 'Toma una foto de tu perro', type: 'photo', target: 1, bonusXp: 20 },
  { id: 'ubicacion', title: 'Guarda la ubicación de un paseo', type: 'location', target: 1, bonusXp: 15 },
  { id: 'notas', title: 'Escribe notas del paseo', type: 'notes', target: 1, bonusXp: 15 },
  { id: 'maraton', title: 'Pasea 45 minutos o más', type: 'minutes', target: 45, bonusXp: 35 },
];

/** Nivel = raíz del XP: cada nivel exige más que el anterior. */
export const levelFor = (xp) => Math.floor(Math.sqrt(Math.max(xp, 0) / 100)) + 1;
export const xpForLevel = (level) => (level - 1) ** 2 * 100;

export function walkXp({ durationMinutes, hasPhoto, hasNotes, hasLocation }, streak) {
  const minutes = Math.min(durationMinutes, XP.maxMinutes) * XP.perMinute;
  const streakBonus = Math.min(streak, XP.streakCap) * XP.streakStep;
  return XP.base + minutes + (hasPhoto ? XP.photo : 0) + (hasNotes ? XP.notes : 0) + (hasLocation ? XP.location : 0) + streakBonus;
}

const dayNumber = (day) => Date.parse(`${day}T00:00:00Z`) / 86_400_000;

/** Racha tras un paseo en `today`, dado el estado previo {count, lastDay}. */
export function nextStreak(prev, today) {
  if (!prev || !prev.lastDay) return 1;
  const gap = dayNumber(today) - dayNumber(prev.lastDay);
  if (gap === 0) return Math.max(prev.count, 1);
  if (gap === 1) return prev.count + 1;
  return 1;
}

/** Racha vigente a mostrar hoy: se pierde si pasó un día completo sin pasear. */
export function activeStreak(prev, today) {
  if (!prev || !prev.lastDay) return 0;
  return dayNumber(today) - dayNumber(prev.lastDay) <= 1 ? prev.count : 0;
}

export function isoWeek(day) {
  const d = new Date(`${day}T00:00:00Z`);
  const dow = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dow);
  const yearStart = Date.UTC(d.getUTCFullYear(), 0, 1);
  const week = Math.ceil(((d - yearStart) / 86_400_000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

export function challengeFor(day) {
  const n = [...day].reduce((sum, c) => sum + c.charCodeAt(0), 0);
  return CHALLENGES[n % CHALLENGES.length];
}

export function meetsChallenge(challenge, walk) {
  switch (challenge.type) {
    case 'minutes': return walk.durationMinutes >= challenge.target;
    case 'photo': return walk.hasPhoto;
    case 'location': return walk.hasLocation;
    case 'notes': return walk.hasNotes;
    default: return false;
  }
}

export const earnedBadges = (stats) => BADGES.filter((b) => b.test(stats));
