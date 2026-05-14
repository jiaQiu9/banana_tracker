class NutritionTotals {
  final double calories;
  final double potassium;
  final double carbs;
  final double sugar;

  const NutritionTotals({
    required this.calories,
    required this.potassium,
    required this.carbs,
    required this.sugar,
  });
}

class NutritionService {
  static const double _caloriesPerBanana = 89;
  static const double _potassiumPerBanana = 422;
  static const double _carbsPerBanana = 23;
  static const double _sugarPerBanana = 12;

  static const double dailyPotassium = 4700;

  NutritionTotals calculate(double totalBananas) {
    final factor = totalBananas;
    return NutritionTotals(
      calories: _caloriesPerBanana * factor,
      potassium: _potassiumPerBanana * factor,
      carbs: _carbsPerBanana * factor,
      sugar: _sugarPerBanana * factor,
    );
  }

  double potassiumPercent(double potassium) {
    return double.parse(
      ((potassium / NutritionService.dailyPotassium) * 100)
          .toStringAsFixed(1),
    );
  }
}
