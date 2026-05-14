import 'package:flutter/material.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService db;

  const HomeScreen({super.key, required this.db});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _todayCount = 0.0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await widget.db.cleanupOldEntries();
      await _loadCount();
    } catch (e) {
      print('[HomeScreen] Init error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadCount() async {
    try {
      final count = await widget.db.getTodayCount();
      if (mounted) {
        setState(() {
          _todayCount = count;
          _loading = false;
        });
      }
    } catch (e) {
      print('[HomeScreen] Load count error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _logBanana(double amount) async {
    try {
      await widget.db.logBanana(amount);
      final count = await widget.db.getTodayCount();
      if (mounted) {
        setState(() {
          _todayCount = count;
        });
      }
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