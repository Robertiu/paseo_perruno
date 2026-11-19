import test from 'node:test';
import assert from 'node:assert/strict';
import { nextStreak, activeStreak, isoWeek, levelFor, walkXp, challengeFor, earnedBadges } from '../src/game.js';

test('racha: primer paseo, mismo día, día siguiente y hueco', () => {
  assert.equal(nextStreak(null, '2026-11-18'), 1);
  assert.equal(nextStreak({ count: 3, lastDay: '2026-11-18' }, '2026-11-18'), 3);
  assert.equal(nextStreak({ count: 3, lastDay: '2026-11-17' }, '2026-11-18'), 4);
  assert.equal(nextStreak({ count: 3, lastDay: '2026-11-10' }, '2026-11-18'), 1);
  assert.equal(nextStreak({ count: 2, lastDay: '2026-12-31' }, '2027-01-01'), 3);
});

test('racha activa se pierde tras un día sin pasear', () => {
  assert.equal(activeStreak({ count: 5, lastDay: '2026-11-17' }, '2026-11-18'), 5);
  assert.equal(activeStreak({ count: 5, lastDay: '2026-11-16' }, '2026-11-18'), 0);
  assert.equal(activeStreak(null, '2026-11-18'), 0);
});

test('semana ISO', () => {
  assert.equal(isoWeek('2026-11-18'), '2026-W47');
  assert.equal(isoWeek('2027-01-01'), '2026-W53');
});

test('niveles crecen con raíz cuadrada', () => {
  assert.equal(levelFor(0), 1);
  assert.equal(levelFor(100), 2);
  assert.equal(levelFor(400), 3);
});

test('XP: base + minutos + extras + racha (con topes)', () => {
  assert.equal(walkXp({ durationMinutes: 30, hasPhoto: true, hasNotes: true, hasLocation: true }, 3), 10 + 30 + 15 + 6);
  assert.equal(walkXp({ durationMinutes: 500, hasPhoto: false, hasNotes: false, hasLocation: false }, 99), 10 + 120 + 20);
});

test('reto del día es determinista', () => {
  assert.equal(challengeFor('2026-11-18').id, challengeFor('2026-11-18').id);
});

test('insignias según estadísticas', () => {
  const ids = earnedBadges({ walks: 5, streak: 3, photos: 0, locations: 0, longestWalk: 60, xp: 0 }).map((b) => b.id);
  assert.deepEqual(ids, ['primer-paseo', 'paseador-5', 'racha-3', 'maraton']);
});
