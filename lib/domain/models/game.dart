// Modelos de gamificación devueltos por la API.

class GameBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool earned;

  const GameBadge({required this.id, required this.name, required this.emoji, required this.description, this.earned = true});

  factory GameBadge.fromJson(Map<String, dynamic> j) => GameBadge(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        description: j['description'] as String,
        earned: j['earned'] as bool? ?? true,
      );
}

class DailyChallenge {
  final String title;
  final int bonusXp;
  final bool completed;

  const DailyChallenge({required this.title, required this.bonusXp, required this.completed});

  factory DailyChallenge.fromJson(Map<String, dynamic> j) => DailyChallenge(
        title: j['title'] as String,
        bonusXp: (j['bonusXp'] as num).toInt(),
        completed: j['completed'] as bool? ?? false,
      );
}

class Profile {
  final String id;
  final String name;
  final int xp;
  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final int? rank;
  final int streak;
  final int walks;
  final int minutes;
  final List<GameBadge> badges;
  final DailyChallenge challenge;

  const Profile({
    required this.id,
    required this.name,
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.rank,
    required this.streak,
    required this.walks,
    required this.minutes,
    required this.badges,
    required this.challenge,
  });

  double get levelProgress => xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0, 1).toDouble();

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String,
        xp: (j['xp'] as num).toInt(),
        level: (j['level'] as num).toInt(),
        xpIntoLevel: (j['xpIntoLevel'] as num).toInt(),
        xpForNextLevel: (j['xpForNextLevel'] as num).toInt(),
        rank: (j['rank'] as num?)?.toInt(),
        streak: (j['streak'] as num).toInt(),
        walks: (j['walks'] as num).toInt(),
        minutes: (j['minutes'] as num).toInt(),
        badges: (j['badges'] as List).map((b) => GameBadge.fromJson(b as Map<String, dynamic>)).toList(),
        challenge: DailyChallenge.fromJson(j['challenge'] as Map<String, dynamic>),
      );
}

/// Recompensa que el servidor calcula al guardar un paseo.
class Reward {
  final int xp;
  final int challengeBonus;
  final bool challengeCompleted;
  final int streak;
  final int? levelUp;
  final int totalXp;
  final int? rank;
  final List<GameBadge> newBadges;

  const Reward({
    required this.xp,
    required this.challengeBonus,
    required this.challengeCompleted,
    required this.streak,
    required this.levelUp,
    required this.totalXp,
    required this.rank,
    required this.newBadges,
  });

  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
        xp: (j['xp'] as num).toInt(),
        challengeBonus: (j['challengeBonus'] as num).toInt(),
        challengeCompleted: j['challengeCompleted'] as bool,
        streak: (j['streak'] as num).toInt(),
        levelUp: (j['levelUp'] as num?)?.toInt(),
        totalXp: (j['totalXp'] as num).toInt(),
        rank: (j['rank'] as num?)?.toInt(),
        newBadges: (j['newBadges'] as List).map((b) => GameBadge.fromJson(b as Map<String, dynamic>)).toList(),
      );
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int xp;
  final int level;
  final bool isMe;

  const LeaderboardEntry({required this.rank, required this.name, required this.xp, required this.level, required this.isMe});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: (j['rank'] as num).toInt(),
        name: j['name'] as String,
        xp: (j['xp'] as num).toInt(),
        level: (j['level'] as num).toInt(),
        isMe: j['isMe'] as bool,
      );
}

class Leaderboard {
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final int myXp;

  const Leaderboard({required this.entries, this.myRank, this.myXp = 0});

  factory Leaderboard.fromJson(Map<String, dynamic> j) {
    final me = j['me'] as Map<String, dynamic>?;
    return Leaderboard(
      entries: (j['entries'] as List).map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList(),
      myRank: (me?['rank'] as num?)?.toInt(),
      myXp: (me?['xp'] as num?)?.toInt() ?? 0,
    );
  }
}
