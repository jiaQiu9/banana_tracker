import 'dart:async';

import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/nutrition_service.dart';
import '../services/preferences_service.dart';
import '../utils/sizing.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService db;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.db,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  double _todayCount = 0.0;
  double _dailyGoal = 2.0;
  int _streak = 0;
  bool _loading = true;
  String? _error;
  Timer? _undoTimer;
  Timer? _midnightTimer;
  String _lastLoadedDate = '';
  TimeOfDay? _reminderTime;
  double _thisWeekTotal = 0;
  double _lastWeekTotal = 0;
  final _nutritionService = NutritionService();

  NutritionTotals get _nutrition => _nutritionService.calculate(_todayCount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    _loadWeeklyTrend();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _undoTimer?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (todayStr == _lastLoadedDate) return;
    _lastLoadedDate = todayStr;

    try {
      await widget.db.cleanupOldEntries();
      _dailyGoal = await PreferencesService().getDailyGoal();
      _reminderTime = await PreferencesService().getReminderTime();
      await _loadToday();

      if (_todayCount > 0) {
        final streak = await widget.db.getStreak(_dailyGoal);
        if (mounted) setState(() => _streak = streak);
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayQualified =
            await widget.db.hadGoalReachedOnDate(yesterday, _dailyGoal);
        if (!yesterdayQualified && _todayCount < _dailyGoal) {
          if (mounted) setState(() => _streak = 0);
        }
      }
    } catch (e) {
      debugPrint('[HomeScreen] Init error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    _midnightTimer = Timer(timeUntilMidnight, () {
      _init();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _loadToday() async {
    final count = await widget.db.getTodayCount();
    if (mounted) {
      setState(() {
        _todayCount = count;
        _loading = false;
      });
    }
  }

  Future<void> _refreshStreak() async {
    final streak = await widget.db.getStreak(_dailyGoal);
    if (mounted) setState(() => _streak = streak);
  }

  Future<void> _loadWeeklyTrend() async {
    final thisMonday = DatabaseService.lastMonday(DateTime.now());
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final thisWeek = await widget.db.getWeekTotal(thisMonday);
    final lastWeek = await widget.db.getWeekTotal(lastMonday);
    if (mounted) {
      setState(() {
        _thisWeekTotal = thisWeek;
        _lastWeekTotal = lastWeek;
      });
    }
  }

  Future<void> _handleUndo() async {
    await widget.db.undoLastLog();
    final count = await widget.db.getTodayCount();
    if (mounted) setState(() => _todayCount = count);
    await _refreshStreak();
    await _loadWeeklyTrend();
  }

  void _showUndoSnackBar() {
    _undoTimer?.cancel();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Logged 🍌'),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFFFC107),
          onPressed: () {
            _undoTimer?.cancel();
            _handleUndo();
          },
        ),
      ),
    );

    _undoTimer = Timer(const Duration(seconds: 5), () {
      messenger.clearSnackBars();
    });
  }

  void _showGoalDialog() {
    final originalGoal = _dailyGoal;
    var tempGoal = _dailyGoal;

    showDialog(
      context: context,
      builder: (context) {
        final s = AppSizing.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              constraints: const BoxConstraints(minWidth: 300),
              title: const Text('Daily Goal'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: tempGoal > 0.25
                        ? () {
                            tempGoal = double.parse(
                                (tempGoal - 0.25).toStringAsFixed(2));
                            setDialogState(() {});
                          }
                        : null,
                  ),
                  SizedBox(
                    width: s.dialogValueWidth,
                    child: Text(
                      _formatBananaCount(tempGoal),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                          fontSize: s.font3xl, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      tempGoal = double.parse(
                          (tempGoal + 0.25).toStringAsFixed(2));
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _dailyGoal = originalGoal;
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _dailyGoal = tempGoal;
                    PreferencesService().setDailyGoal(_dailyGoal);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) {
                    widget.onToggleTheme();
                    Navigator.pop(ctx);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Daily Reminder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReminderDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Daily Goal'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGoalDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('History'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(this.context, '/history');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Daily Reminder'),
              content: _reminderTime != null
                  ? Text(
                      'Current reminder: ${_reminderTime!.format(context)}\nTap to change or remove.')
                  : const Text(
                      'Set a daily time to be reminded to log your bananas.'),
              actions: [
                Visibility(
                  visible: false,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await NotificationService().scheduleTestNotification();
                    },
                    child: const Text('Test (5s)'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                if (_reminderTime != null)
                  TextButton(
                    onPressed: () async {
                      await NotificationService().cancelReminder();
                      await PreferencesService().clearReminderTime();
                      if (mounted) {
                        setState(() => _reminderTime = null);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Remove'),
                  ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final picked = await showTimePicker(
                      context: this.context,
                      initialTime:
                          _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked == null) return;
                    await NotificationService()
                        .scheduleDailyReminder(picked);
                    await PreferencesService().setReminderTime(picked);
                    if (mounted) {
                      setState(() => _reminderTime = picked);
                    }
                  },
                  child: Text(_reminderTime != null ? 'Change' : 'Set Reminder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logBanana(double amount) async {
    _showUndoSnackBar();

    try {
      await widget.db.logBanana(amount);
      final count = await widget.db.getTodayCount();

      if (!mounted) return;

      setState(() {
        _todayCount = count;
      });
      await _refreshStreak();
      await _loadWeeklyTrend();
    } catch (e) {
      debugPrint('[HomeScreen] Log banana error: $e');
    }
  }

  String _formatBananaCount(double count) {
    if (count == count.truncateToDouble()) {
      return count.toInt().toString();
    }
    return count.toStringAsFixed(2);
  }

  String _portionLabel(double amount) {
    if (amount == 0.25) return '1/4';
    if (amount == 0.5) return '1/2';
    if (amount == 1.0) return '1';
    return _formatBananaCount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banana Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final s = AppSizing.of(context);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.spaceLg),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final countText = _formatBananaCount(_todayCount);
        final progress = (_todayCount / _dailyGoal).clamp(0.0, 1.0);
        final reached = _todayCount >= _dailyGoal;
        final goalLabel = reached
            ? '🎉 Goal reached!'
            : '${_formatBananaCount(_todayCount)} / ${_formatBananaCount(_dailyGoal)} bananas';

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1–4. Counter + Progress + Nutrition (grouped)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countText,
                  style: TextStyle(
                    fontSize: h * 0.12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFC107),
                  ),
                ),
                if (_streak > 0) ...[
                  SizedBox(height: h * 0.004),
                  Text(
                    '🔥 $_streak day streak',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: h * 0.022,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                  SizedBox(height: h * 0.004),
                ] else
                  SizedBox(height: h * 0.001),
                SizedBox(height: s.spaceSm),
                _buildWeeklyTrendLine(s),
                SizedBox(
                  width: w * 0.6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(w * 0.01),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: s.progressBarH,
                      color: reached ? Colors.green : const Color(0xFFFFC107),
                      backgroundColor:
                          const Color(0xFFFFC107).withValues(alpha: 0.2),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.002),
                Text(
                  goalLabel,
                  style: TextStyle(
                    fontSize: h * 0.018,
                    color: reached ? Colors.green : null,
                  ),
                ),
                SizedBox(height: h * 0.03),
                _buildNutritionCard(theme, s, w, h),
                SizedBox(height: h * 0.06),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBananaButton(0.25, 'assets/images/quarter.png', s, w, h),
                        SizedBox(width: w * 0.001),
                        _buildBananaButton(0.5, 'assets/images/half.png', s, w, h),
                        SizedBox(width: w * 0.001),
                        _buildBananaButton(1.0, 'assets/images/full.png', s, w, h),
                      ],
                    ),
                    SizedBox(height: h * 0.015),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlaceholderButton(s, w, h),
                        SizedBox(width: w * 0.02),
                        _buildPlaceholderButton(s, w, h),
                        SizedBox(width: w * 0.02),
                        _buildPlaceholderButton(s, w, h),
                      ],
                    ),
                    SizedBox(height: h * 0.015),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlaceholderButton(s, w, h),
                        SizedBox(width: w * 0.02),
                        _buildPlaceholderButton(s, w, h),
                        SizedBox(width: w * 0.02),
                        _buildPlaceholderButton(s, w, h),
                      ],
                    ),
                  ],
                ),
              ],
            ),

          ],
        ));
      },
    );
  }

  Widget _buildBananaButton(double amount, String assetPath, AppSizing s, double w, double h) {
    final theme = Theme.of(context);
    return _ScaleTap(
      onTap: () => _logBanana(amount),
      child: Container(
        width: s.iconXl,
        clipBehavior: Clip.none,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 1.5,
              child: Image.asset(
                assetPath,
                width: s.iconXl,
                height: s.iconXl,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: h * 0.000001),
            Transform.translate(
              offset: Offset(0, -(w * 0.0125)),
              child: Text(
                _portionLabel(amount),
                style: TextStyle(
                  fontSize: h * 0.016,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderButton(AppSizing s, double w, double h) {
    return SizedBox(
      width: s.iconXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: s.iconXl, height: s.iconXl),
          SizedBox(height: h * 0.001),
          Transform.translate(
            offset: Offset(0, -(w * 0.0125)),
            child: SizedBox(height: h * 0.016),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendLine(AppSizing s) {
    final diff = _thisWeekTotal - _lastWeekTotal;
    if (_lastWeekTotal == 0 && _thisWeekTotal == 0) return const SizedBox.shrink();
    final String arrow;
    final Color color;
    final String label;
    if (diff > 0) {
      arrow = '↑';
      color = Colors.green;
      label = '${diff.toStringAsFixed(2)} more than last week';
    } else if (diff < 0) {
      arrow = '↓';
      color = Colors.redAccent;
      label = '${diff.abs().toStringAsFixed(2)} fewer than last week';
    } else {
      arrow = '→';
      color = Colors.grey;
      label = 'Same as last week';
    }
    return Text(
      '$arrow $label',
      style: TextStyle(
        fontSize: s.fontSm,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildNutritionCard(ThemeData theme, AppSizing s, double w, double h) {
    final n = _nutrition;
    final percent = _nutritionService.potassiumPercent(n.potassium);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: w * 0.06),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: h * 0.012),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Today's Nutrition",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: h * 0.007),
            Row(
              children: [
                Expanded(
                  child: _nutritionStat(
                      'Calories', '${n.calories.toStringAsFixed(0)} kcal', h),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: _nutritionStat('Potassium',
                      '${n.potassium.toStringAsFixed(0)} mg\n($percent% DV)', h),
                ),
              ],
            ),
            SizedBox(height: h * 0.005),
            Row(
              children: [
                Expanded(
                  child: _nutritionStat(
                      'Carbs', '${n.carbs.toStringAsFixed(0)} g', h),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: _nutritionStat(
                      'Sugar', '${n.sugar.toStringAsFixed(0)} g', h),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionStat(String label, String value, double h) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: h * 0.001),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.85,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
