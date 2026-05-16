import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../utils/sizing.dart';

class OnboardingScreen extends StatefulWidget {
  final DatabaseService db;
  final PreferencesService prefsService;

  const OnboardingScreen({
    super.key,
    required this.db,
    required this.prefsService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onGetStarted() async {
    await widget.prefsService.setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildWelcomeSlide(),
                _buildHowToLogSlide(),
                _buildDailyGoalSlide(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: s.buttonHeight + s.spaceLg + s.spaceMd),
                child: _buildDotIndicators(),
              ),
            ),
            if (_currentPage > 0)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: s.spaceLg,
                      bottom: s.spaceLg,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(s.spaceMd),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: s.spaceLg,
                          vertical: s.spaceXs,
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: s.iconMd),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: s.spaceLg,
                    bottom: s.spaceLg,
                  ),
                  child: ElevatedButton(
                    onPressed: _currentPage < 2 ? _onNext : _onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s.spaceMd),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: s.spaceLg,
                        vertical: s.spaceXs,
                      ),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Icon(
                      _currentPage < 2
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: s.iconMd,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide() {
    final s = AppSizing.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: s.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍌', style: TextStyle(fontSize: 80)),
          SizedBox(height: s.spaceXl),
          Text(
            'Welcome to\nBanana Tracker',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.font2xl,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: s.spaceMd),
          Text(
            'Track how many bananas you eat each day,\nsimply and beautifully.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.fontLg,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToLogSlide() {
    final s = AppSizing.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: s.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/full.png',
                      width: s.iconXl * 1.5,
                      height: s.iconXl * 1.5,
                    ),
                    SizedBox(width: s.spaceMd),
                    Image.asset(
                      'assets/images/half.png',
                      width: s.iconXl * 1.5,
                      height: s.iconXl * 1.5,
                    ),
                    SizedBox(width: s.spaceMd),
                    Image.asset(
                      'assets/images/quarter.png',
                      width: s.iconXl * 1.5,
                      height: s.iconXl * 1.5,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: s.spaceXl),
          Text(
            'Log Your Bananas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.font2xl,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: s.spaceMd),
          Text(
            'Tap the full banana for a whole banana,\nhalf banana for half, or quarter for a small piece.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.fontLg,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalSlide() {
    final s = AppSizing.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: s.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.celebration,
            size: 80,
            color: Color(0xFFFFC107),
          ),
          SizedBox(height: s.spaceXl),
          Text(
            'Set Your Daily Goal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.font2xl,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: s.spaceMd),
          Text(
            'Tap the 🎉 icon to set how many bananas\nyou want to eat each day. Track your\nprogress with the bar below your count —\nit turns green when you hit your goal!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.fontLg,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    final s = AppSizing.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.spaceMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: s.spaceXs),
            width: isActive ? s.spaceLg : s.spaceSm,
            height: s.spaceSm,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFFC107)
                  : const Color(0xFFFFC107).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

}
