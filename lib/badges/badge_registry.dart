class BadgeDefinition {
  final String tag;
  final String name;
  final String description;
  final String assetPath;

  const BadgeDefinition({
    required this.tag,
    required this.name,
    required this.description,
    required this.assetPath,
  });
}

class BadgeRegistry {
  BadgeRegistry._();

  static const Map<String, BadgeDefinition> _definitions = {
    'first_banana': BadgeDefinition(
      tag: 'first_banana',
      name: 'First Banana',
      description: 'Logged your very first banana',
      assetPath: 'assets/badges/first_banana.png',
    ),
    'streak_7': BadgeDefinition(
      tag: 'streak_7',
      name: 'Week Warrior',
      description: 'Maintained a 7-day logging streak',
      assetPath: 'assets/badges/streak_7.png',
    ),
    'streak_30': BadgeDefinition(
      tag: 'streak_30',
      name: 'Monthly Master',
      description: 'Maintained a 30-day logging streak',
      assetPath: 'assets/badges/streak_30.png',
    ),
    'total_10': BadgeDefinition(
      tag: 'total_10',
      name: 'Getting Started',
      description: 'Logged 10 bananas in total',
      assetPath: 'assets/badges/total_10.png',
    ),
    'total_100': BadgeDefinition(
      tag: 'total_100',
      name: 'Century Club',
      description: 'Logged 100 bananas in total',
      assetPath: 'assets/badges/total_100.png',
    ),
    'total_365': BadgeDefinition(
      tag: 'total_365',
      name: 'Banana Legend',
      description: 'Logged 365 bananas in total',
      assetPath: 'assets/badges/total_365.png',
    ),
    'goal_reached': BadgeDefinition(
      tag: 'goal_reached',
      name: 'Goal Getter',
      description: 'Hit your daily goal for the first time',
      assetPath: 'assets/badges/goal_reached.png',
    ),
    'goal_week': BadgeDefinition(
      tag: 'goal_week',
      name: 'On a Roll',
      description: 'Hit your daily goal 7 days in a row',
      assetPath: 'assets/badges/goal_week.png',
    ),
  };

  static BadgeDefinition? get(String tag) => _definitions[tag];

  static List<BadgeDefinition> get all => _definitions.values.toList();
}
