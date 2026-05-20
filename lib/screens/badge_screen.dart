import 'package:flutter/material.dart';

import '../badges/badge_registry.dart';
import '../services/badge_service.dart';
import '../utils/sizing.dart';

class BadgeScreen extends StatefulWidget {
  final BadgeService badgeService;

  const BadgeScreen({super.key, required this.badgeService});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  Set<String> _unlockedTags = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUnlocked();
  }

  Future<void> _loadUnlocked() async {
    final unlocked = await widget.badgeService.getUnlockedTags();
    if (mounted) {
      setState(() {
        _unlockedTags = unlocked;
        _loading = false;
      });
    }
  }

  static const _greyscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppSizing.of(context);
    const crossAxisCount = 4;
    final cellWidth = (s.w - s.spaceMd * 2 - s.spaceSm * (crossAxisCount - 1)) /
        crossAxisCount;
    final imageSize = cellWidth * 0.55;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(s.spaceMd),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: s.spaceMd,
                crossAxisSpacing: s.spaceSm,
                childAspectRatio: 0.85,
              ),
              itemCount: BadgeRegistry.all.length,
              itemBuilder: (context, index) {
                final badge = BadgeRegistry.all[index];
                final unlocked = _unlockedTags.contains(badge.tag);
                return _buildBadgeCell(
                  badge: badge,
                  unlocked: unlocked,
                  imageSize: imageSize,
                  theme: theme,
                  s: s,
                );
              },
            ),
    );
  }

  Widget _buildBadgeCell({
    required BadgeDefinition badge,
    required bool unlocked,
    required double imageSize,
    required ThemeData theme,
    required AppSizing s,
  }) {
    final image = Image.asset(
      badge.assetPath,
      width: imageSize,
      height: imageSize,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => Icon(
        Icons.emoji_events,
        size: imageSize,
        color: unlocked ? const Color(0xFFFFC107) : theme.colorScheme.onSurface,
      ),
    );

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, unlocked, theme, s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unlocked)
            image
          else
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
              child: image,
            ),
          SizedBox(height: s.spaceXs),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: s.fontXs,
              color: unlocked
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(
    BadgeDefinition badge,
    bool unlocked,
    ThemeData theme,
    AppSizing s,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                badge.assetPath,
                width: s.iconXl,
                height: s.iconXl,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => Icon(
                  Icons.emoji_events,
                  size: s.iconXl,
                  color: unlocked
                      ? const Color(0xFFFFC107)
                      : theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: s.spaceMd),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: s.fontLg,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: s.spaceXs),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: s.fontSm,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: s.spaceSm),
              Text(
                unlocked ? 'Unlocked ✓' : 'Not yet unlocked',
                style: TextStyle(
                  fontSize: s.fontSm,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? Colors.green : null,
                ),
              ),
              SizedBox(height: s.spaceMd),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
