import 'dart:async';

import 'package:flutter/material.dart';
import '../models/banana_entry.dart';
import '../services/database_service.dart';
import '../services/nutrition_service.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService db;

  const HomeScreen({super.key, required this.db});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _todayCount = 0.0;
  List<BananaEntry> _todayTimestamps = [];
  double _dailyGoal = 2.0;
  bool _loading = true;
  String? _error;
  Timer? _undoTimer;
  final _nutritionService = NutritionService();

  NutritionTotals get _nutrition => _nutritionService.calculate(_todayCount);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await widget.db.cleanupOldEntries();
      _dailyGoal = await PreferencesService().getDailyGoal();
      await _loadToday();
    } catch (e) {
      print('[HomeScreen] Init error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadToday() async {
    final count = await widget.db.getTodayCount();
    final timestamps = await widget.db.getTodayTimestamps();
    if (mounted) {
      setState(() {
        _todayCount = count;
        _todayTimestamps = timestamps;
        _loading = false;
      });
    }
  }

  Future<void> _handleUndo() async {
    await widget.db.undoLastLog();
    final count = await widget.db.getTodayCount();
    final timestamps = await widget.db.getTodayTimestamps();
    if (mounted) {
      setState(() {
        _todayCount = count;
        _todayTimestamps = timestamps;
      });
    }
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Daily Goal'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(width: 16),
                  Text(
                    _formatBananaCount(tempGoal),
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
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

  Future<void> _logBanana(double amount) async {
    _showUndoSnackBar();

    try {
      await widget.db.logBanana(amount);
      final count = await widget.db.getTodayCount();
      final timestamps = await widget.db.getTodayTimestamps();

      if (!mounted) return;

      setState(() {
        _todayCount = count;
        _todayTimestamps = timestamps;
      });
    } catch (e) {
      print('[HomeScreen] Log banana error: $e');
    }
  }

  String _formatBananaCount(double count) {
    if (count == count.truncateToDouble()) {
      return count.toInt().toString();
    }
    return count.toStringAsFixed(2);
  }

  Widget _buildGoalProgress() {
    final progress = (_todayCount / _dailyGoal).clamp(0.0, 1.0);
    final reached = _todayCount >= _dailyGoal;

    return Builder(
      builder: (context) {
        final w = MediaQuery.of(context).size.width;
        final theme = Theme.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: w * 0.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: reached ? Colors.green : const Color(0xFFFFC107),
                  backgroundColor:
                      const Color(0xFFFFC107).withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reached
                  ? '🎉 Goal reached!'
                  : '${_formatBananaCount(_todayCount)} / ${_formatBananaCount(_dailyGoal)} bananas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: reached ? Colors.green : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutritionCard() {
    final n = _nutrition;
    final percent = _nutritionService.potassiumPercent(n.potassium);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Today's Nutrition",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _nutritionStat('Calories', '${n.calories.toStringAsFixed(0)} kcal')),
                const SizedBox(width: 12),
                Expanded(child: _nutritionStat('Potassium', '${n.potassium.toStringAsFixed(0)} mg\n($percent% DV)')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _nutritionStat('Carbs', '${n.carbs.toStringAsFixed(0)} g')),
                const SizedBox(width: 12),
                Expanded(child: _nutritionStat('Sugar', '${n.sugar.toStringAsFixed(0)} g')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionStat(String label, String value) {
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
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedCount(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFC107),
          ),
        ),
      ],
    );
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
            icon: const Icon(Icons.settings),
            tooltip: 'Daily Goal',
            onPressed: _showGoalDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error)),
            )
          else ...[
            _buildOutlinedCount(
                _loading ? '...' : _formatBananaCount(_todayCount)),
            const SizedBox(height: 12),
            if (!_loading) _buildGoalProgress(),
            if (!_loading) ...[
              const SizedBox(height: 14),
              _buildNutritionCard(),
            ],
            const SizedBox(height: 48),
            Builder(
              builder: (context) {
                final w = MediaQuery.of(context).size.width;
                final iconSize = w * 0.35;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScaleTap(
                          onTap: () => _logBanana(0.5),
                          child: Image.asset('assets/images/half.png',
                              width: iconSize, height: iconSize, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 40),
                        _ScaleTap(
                          onTap: () => _logBanana(0.25),
                          child: Image.asset('assets/images/quarter.png',
                              width: iconSize, height: iconSize, fit: BoxFit.contain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: _ScaleTap(
                        onTap: () => _logBanana(1.0),
                        child: Image.asset('assets/images/full.png',
                            width: iconSize, height: iconSize, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          ],
        ),
      ),
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