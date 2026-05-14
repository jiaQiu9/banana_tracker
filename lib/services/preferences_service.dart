import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _dailyGoalKey = 'daily_goal';
  static const double _defaultGoal = 2.0;

  PreferencesService._();
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;

  Future<double> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dailyGoalKey) ?? _defaultGoal;
  }

  Future<void> setDailyGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyGoalKey, goal);
  }
}
