// Espacio de nombres de claves: paseo:<entidad>:<id>[:<subestructura>]
const P = 'paseo';

export const keys = {
  walker: (id) => `${P}:walker:${id}`, //                HASH   perfil y contadores
  walkerByName: `${P}:walker:byname`, //                 HASH   nombre(minúsculas) -> id (unicidad)
  walkerWalks: (id) => `${P}:walker:${id}:walks`, //     ZSET   walkId, score = timestamp
  walkerBadges: (id) => `${P}:walker:${id}:badges`, //   SET    insignias ganadas
  streak: (id) => `${P}:walker:${id}:streak`, //         HASH   {count, lastDay} con TTL 48 h
  walk: (id) => `${P}:walk:${id}`, //                    HASH   un paseo
  session: (token) => `${P}:session:${token}`, //        STRING token -> walkerId, TTL 30 d
  cooldown: (id) => `${P}:cooldown:${id}`, //            STRING anti-farmeo, TTL corto
  leaderboardGlobal: `${P}:lb:global`, //                ZSET   walkerId, score = XP total
  leaderboardWeek: (week) => `${P}:lb:week:${week}`, //  ZSET   XP de la semana ISO, TTL 21 d
  challenge: (day) => `${P}:challenge:${day}`, //        HASH   reto del día, TTL 36 h
  challengeDone: (day) => `${P}:challenge:${day}:done`, // SET   quién lo completó
};
