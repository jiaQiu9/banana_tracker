import 'package:flutter/material.dart';
import '../models/banana_entry.dart';
import '../services/database_service.dart';
import '../services/nutrition_service.dart';

class HistoryScreen extends StatefulWidget {
  final DatabaseService db;

  const HistoryScreen({super.key, required this.db});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, double>? _weeklyTotals;
  List<BananaEntry>? _monthEntries;
  String? _error;
  late DateTime _selectedMonth;
  final _nutritionService = NutritionService();

  double get _monthTotalCount {
    if (_monthEntries == null) return 0.0;
    double total = 0.0;
    for (final entry in _monthEntries!) {
      total += entry.amount;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    try {
      final entries = await widget.db.getMonthEntries(
          _selectedMonth.year, _selectedMonth.month);
      if (mounted) {
        setState(() {
          _monthEntries = entries;
          _weeklyTotals = _computeWeeklyTotals(entries);
          _error = null;
        });
      }
    } catch (e) {
      print('[HistoryScreen] Load month error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Map<String, double> _computeWeeklyTotals(List<BananaEntry> entries) {
    final weekly = <String, double>{};
    for (final entry in entries) {
      final weekStart =
          entry.eatenAt.subtract(Duration(days: entry.eatenAt.weekday - 1));
      final key = '${weekStart.month}/${weekStart.day}';
      weekly[key] = (weekly[key] ?? 0.0) + entry.amount;
    }
    return weekly;
  }

  void _goToMonth(int year, int month) {
    setState(() => _selectedMonth = DateTime(year, month, 1));
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error)),
              ),
            )
          : _monthEntries == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadMonthData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWeeklySummary(theme),
                      if (_monthEntries != null) ...[
                        const SizedBox(height: 10),
                        _buildNutritionRow(theme),
                      ],
                      const SizedBox(height: 24),
                      _buildMonthlyCalendar(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWeeklySummary(ThemeData theme) {
    final totals = _weeklyTotals!;
    final monthLabel =
        '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}';

    if (totals.isEmpty) {
      return _emptyCard(
        theme,
        'Weekly Summary',
        'No bananas logged in $monthLabel.',
        Icons.calendar_today,
      );
    }

    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    DateTime parseWeekKey(String key) {
      final parts = key.split('/');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      var date = DateTime(_selectedMonth.year, month, day);
      if (date.isAfter(lastDayOfMonth)) {
        date = DateTime(_selectedMonth.year - 1, month, day);
      }
      return date;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => parseWeekKey(b.key).compareTo(parseWeekKey(a.key)));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Weekly Summary',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...sorted.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Week of ${e.key}',
                          style: theme.textTheme.bodyMedium),
                      Row(
                        children: [
                          const Text('🍌'),
                          const SizedBox(width: 4),
                          Text(_formatAmount(e.value),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(ThemeData theme) {
    final n = _nutritionService.calculate(_monthTotalCount);

    return Text(
      '🔥 ${n.calories.toStringAsFixed(0)} kcal'
      '  |  ⚡ ${n.potassium.toStringAsFixed(0)} mg K'
      '  |  🌾 ${n.carbs.toStringAsFixed(1)} g carbs'
      '  |  🍬 ${n.sugar.toStringAsFixed(1)} g sugar',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildMonthlyCalendar(ThemeData theme) {
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    final monthLabel =
        '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}';
    final isCurrentMonth = _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    final countByDate = <String, double>{};
    for (final entry in _monthEntries!) {
      final key = '${entry.eatenAt.year}-${entry.eatenAt.month}-${entry.eatenAt.day}';
      countByDate[key] = (countByDate[key] ?? 0.0) + entry.amount;
    }

    const dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final totalCells = firstWeekday - 1 + daysInMonth;
    final numWeeks = (totalCells / 7).ceil();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _goToMonth(
                      _selectedMonth.year, _selectedMonth.month - 1),
                ),
                Text(monthLabel,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isCurrentMonth
                      ? null
                      : () => _goToMonth(
                          _selectedMonth.year, _selectedMonth.month + 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: dayHeaders.map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(150))),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 8),
            for (var week = 0; week < numWeeks; week++)
              Row(
                children: List.generate(7, (col) {
                  final day = week * 7 + col - (firstWeekday - 1) + 1;
                  final inMonth = day >= 1 && day <= daysInMonth;
                  final isToday = inMonth &&
                      isCurrentMonth &&
                      day == now.day;

                  return Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: inMonth
                          ? _buildDayCell(
                              theme: theme,
                              year: _selectedMonth.year,
                              month: _selectedMonth.month,
                              day: day,
                              count: countByDate[
                                  '${_selectedMonth.year}-${_selectedMonth.month}-$day'],
                              isToday: isToday,
                              onTap: isToday ? () => _showTodayLogs() : null,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required ThemeData theme,
    required int year,
    required int month,
    required int day,
    required double? count,
    required bool isToday,
    VoidCallback? onTap,
  }) {
    final bananas = count ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      behavior: onTap != null ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: Container(
        decoration: isToday
            ? BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : null,
                color: isToday ? theme.colorScheme.onPrimary : null,
              ),
            ),
            if (bananas > 0)
              Text(
                '🍌 ${_formatAmount(bananas)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isToday
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(1);
  }

  String _amountLabel(double amount) {
    if (amount == 1.0) return 'Full';
    if (amount == 0.5) return 'Half';
    if (amount == 0.25) return '¼';
    return _formatAmount(amount);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $amPm';
  }

  Future<void> _showTodayLogs() async {
    final now = DateTime.now();
    final timestamps = await widget.db.getTodayTimestamps();
    if (!mounted) return;

    final theme = Theme.of(context);
    final title =
        "Today's Logs – ${_monthName(now.month)} ${now.day}";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (timestamps.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text('No bananas yet today!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withAlpha(150))),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: timestamps.length,
                    itemBuilder: (_, i) {
                      final entry = timestamps[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '🍌 ${_amountLabel(entry.amount)}  · ${_formatTime(entry.eatenAt)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCard(
      ThemeData theme, String title, String message, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(icon,
                size: 48, color: theme.colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: 12),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150))),
          ],
        ),
      ),
    );
  }
}
