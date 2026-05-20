import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _dailyGoalKey = 'daily_goal';
  static const _onboardingKey = 'has_seen_onboarding';
  static const _themeModeKey = 'theme_mode';
  static const _reminderTimeKey = 'reminder_time';
  static const _hasEverReachedGoalKey = 'has_ever_reached_goal';
  static const _goalStreakDaysKey = 'goal_streak_days';
  static const _lastGoalMetDateKey = 'last_goal_met_date';
  static const double _defaultGoal = 2.0;

  PreferencesService._();
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<double> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dailyGoalKey) ?? _defaultGoal;
  }

  Future<void> setDailyGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyGoalKey, goal);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<TimeOfDay?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_reminderTimeKey);
    if (val == null) return null;
    final parts = val.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _reminderTimeKey, '${time.hour}:${time.minute}');
  }

  Future<void> clearReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reminderTimeKey);
  }

  Future<bool> getHasEverReachedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasEverReachedGoalKey) ?? false;
  }

  Future<void> setHasEverReachedGoal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasEverReachedGoalKey, value);
  }

  Future<int> getGoalStreakDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalStreakDaysKey) ?? 0;
  }

  Future<void> setGoalStreakDays(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalStreakDaysKey, value);
  }

  Future<String?> getLastGoalMetDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastGoalMetDateKey);
  }

  Future<void> setLastGoalMetDate(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastGoalMetDateKey, value);
  }
}
