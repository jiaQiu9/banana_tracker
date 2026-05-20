import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'preferences_service.dart';

class BadgeService {
  static const _unlockedBadgesKey = 'unlocked_badges';

  BadgeService._();
  static final BadgeService _instance = BadgeService._();
  factory BadgeService() => _instance;

  Future<Set<String>> getUnlockedTags() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_unlockedBadgesKey) ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> _saveUnlockedTags(Set<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unlockedBadgesKey, tags.join(','));
  }

  Future<List<String>> checkAndUnlock(
    DatabaseService db,
    PreferencesService prefs,
    int currentStreak, {
    bool hasEverReachedGoal = false,
    int goalStreakDays = 0,
  }) async {
    final unlocked = await getUnlockedTags();
    final newlyUnlocked = <String>[];

    final needsTotal = !unlocked.contains('total_10') ||
        !unlocked.contains('total_100') ||
        !unlocked.contains('total_365') ||
        !unlocked.contains('first_banana');
    final needsToday = !unlocked.contains('first_banana');

    final double totalCount =
        needsTotal ? await db.getTotalBananaCount() : 0.0;
    final double todayCount =
        needsToday ? await db.getTodayCount() : 0.0;

    void unlock(String tag) {
      unlocked.add(tag);
      newlyUnlocked.add(tag);
      debugPrint('[BadgeService] Unlocked: $tag');
    }

    // first_banana
    if (!unlocked.contains('first_banana')) {
      if (todayCount > 0 || totalCount >= 1) {
        unlock('first_banana');
      }
    }

    // streak_7
    if (!unlocked.contains('streak_7') && currentStreak >= 7) {
      unlock('streak_7');
    }

    // streak_30
    if (!unlocked.contains('streak_30') && currentStreak >= 30) {
      unlock('streak_30');
    }

    // total_10
    if (!unlocked.contains('total_10') && totalCount >= 10) {
      unlock('total_10');
    }

    // total_100
    if (!unlocked.contains('total_100') && totalCount >= 100) {
      unlock('total_100');
    }

    // total_365
    if (!unlocked.contains('total_365') && totalCount >= 365) {
      unlock('total_365');
    }

    // goal_reached
    if (!unlocked.contains('goal_reached') && hasEverReachedGoal) {
      unlock('goal_reached');
    }

    // goal_week
    if (!unlocked.contains('goal_week') && goalStreakDays >= 7) {
      unlock('goal_week');
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveUnlockedTags(unlocked);
    }

    return newlyUnlocked;
  }
}
