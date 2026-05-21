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
  static const int _totalSlides = 4;

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
                _buildFeaturesSlide(),
                _buildGetStartedSlide(),
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
                    onPressed: _currentPage < _totalSlides - 1 ? _onNext : _onGetStarted,
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
                      _currentPage < _totalSlides - 1
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

  Widget _buildFeaturesSlide() {
    final s = AppSizing.of(context);
    final theme = Theme.of(context);
    final cardWidth = s.w * 0.38;

    const features = [
      (emoji: '🌙', name: 'Dark Mode', description: 'Easy on your eyes, day or night'),
      (emoji: '🔔', name: 'Daily Reminder', description: 'Never miss your banana for the day'),
      (emoji: '🎯', name: 'Daily Goal', description: 'Set a target and track your progress'),
      (emoji: '📅', name: 'History', description: 'Browse your logs by day, week, and month'),
      (emoji: '🏆', name: 'Badges', description: 'Earn achievements as you build your streak'),
    ];

    final navAreaHeight = s.buttonHeight + s.spaceLg + s.spaceSm + 3 * s.spaceMd;

    return Padding(
      padding: EdgeInsets.fromLTRB(s.spaceXl, 0, s.spaceXl, navAreaHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final rowCount = (features.length / 2).ceil();
          final rowGaps = (rowCount - 1) * s.spaceMd;
          final headerEstimate = s.font2xl * 1.4 + s.spaceSm + s.fontLg * 1.4 + s.spaceXl;
          final cardHeight =
              ((availableHeight - headerEstimate - rowGaps) / rowCount).clamp(0.0, availableHeight);

          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Everything You Need',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: s.font2xl,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: s.spaceSm),
                Text(
                  'Here\'s what\'s waiting for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: s.fontLg,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: s.spaceXl),
                for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: rowIndex < rowCount - 1 ? s.spaceMd : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFeatureCard(
                          emoji: features[rowIndex * 2].emoji,
                          name: features[rowIndex * 2].name,
                          description: features[rowIndex * 2].description,
                          width: cardWidth,
                          height: cardHeight,
                        ),
                        if (rowIndex * 2 + 1 < features.length) ...[
                          SizedBox(width: s.spaceMd),
                          _buildFeatureCard(
                            emoji: features[rowIndex * 2 + 1].emoji,
                            name: features[rowIndex * 2 + 1].name,
                            description: features[rowIndex * 2 + 1].description,
                            width: cardWidth,
                            height: cardHeight,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required String emoji,
    required String name,
    required String description,
    required double width,
    required double height,
  }) {
    final s = AppSizing.of(context);
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(s.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(s.spaceSm),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: s.fontXl)),
          SizedBox(height: s.spaceSm),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.fontMd,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: s.spaceXs),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: s.fontSm,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedSlide() {
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
            'Start Recording Your Bananas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s.font2xl,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: s.spaceMd),
          Text(
            'Start recording your bananas.',
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
        children: List.generate(_totalSlides, (index) {
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
