import 'package:flutter/widgets.dart';

class AppSizing {
  final double w;
  final double h;

  const AppSizing._({required this.w, required this.h});

  factory AppSizing.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppSizing._(w: size.width, h: size.height);
  }

  // Typography
  double get fontXs => w * 0.030;
  double get fontSm => w * 0.035;
  double get fontMd => w * 0.040;
  double get fontLg => w * 0.045;
  double get fontXl => w * 0.055;
  double get font2xl => w * 0.065;
  double get font3xl => w * 0.080;
  double get fontHero => w * 0.200;

  // Spacing
  double get spaceXs => w * 0.011;
  double get spaceSm => w * 0.022;
  double get spaceMd => w * 0.044;
  double get spaceLg => w * 0.067;
  double get spaceXl => w * 0.089;

  // Icon / image sizes
  double get iconSm => w * 0.056;
  double get iconMd => w * 0.067;
  double get iconLg => w * 0.111;
  double get iconXl => w * 0.133;

  // Component sizes
  double get buttonHeight => h * 0.068;
  double get progressBarH => h * 0.012;
  double get dialogValueWidth => w * 0.278;
  double get nutritionCardH => h * 0.120;
}
