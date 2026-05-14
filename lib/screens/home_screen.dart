import 'dart:async';

import 'package:flutter/material.dart';

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
    if (mounted) {
      setState(() {
        _todayCount = count;
        _loading = false;
      });
    }
  }

  Future<void> _handleUndo() async {
    await widget.db.undoLastLog();
    final count = await widget.db.getTodayCount();
    if (mounted) {
      setState(() {
        _todayCount = count;
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

      if (!mounted) return;

      setState(() {
        _todayCount = count;
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
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Count number
            Text(
              countText,
              style: TextStyle(
                fontSize: h * 0.12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFC107),
              ),
            ),

            // 2. "X bananas today" subtitle
            Text(
              '$_todayCount bananas today',
              style: TextStyle(
                fontSize: h * 0.022,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            // 3. Progress bar
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

            // 4. "X / Y bananas" label
            Text(
              goalLabel,
              style: TextStyle(
                fontSize: h * 0.018,
                color: reached ? Colors.green : null,
              ),
            ),

            // 5. Nutrition card
            SizedBox(
              height: h * 0.19,
              child: _buildNutritionCard(theme),
            ),

            // 6. Half + Quarter row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScaleTap(
                  onTap: () => _logBanana(0.5),
                  child: Image.asset(
                    'assets/images/half.png',
                    width: w * 0.30,
                    height: w * 0.30,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: w * 0.14),
                _ScaleTap(
                  onTap: () => _logBanana(0.25),
                  child: Image.asset(
                    'assets/images/quarter.png',
                    width: w * 0.30,
                    height: w * 0.30,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),

            // 7. Full banana
            _ScaleTap(
              onTap: () => _logBanana(1.0),
              child: Image.asset(
                'assets/images/full.png',
                width: w * 0.38,
                height: w * 0.38,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutritionCard(ThemeData theme) {
    final n = _nutrition;
    final percent = _nutritionService.potassiumPercent(n.potassium);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _nutritionStat(
                      'Calories', '${n.calories.toStringAsFixed(0)} kcal'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _nutritionStat('Potassium',
                      '${n.potassium.toStringAsFixed(0)} mg\n($percent% DV)'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _nutritionStat(
                      'Carbs', '${n.carbs.toStringAsFixed(0)} g'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _nutritionStat(
                      'Sugar', '${n.sugar.toStringAsFixed(0)} g'),
                ),
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
