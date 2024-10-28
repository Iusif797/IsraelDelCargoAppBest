// lib/theme_extensions.dart
import 'package:flutter/material.dart';

@immutable
class GradientThemeExtension extends ThemeExtension<GradientThemeExtension> {
  final LinearGradient backgroundGradient;
  final LinearGradient buttonGradient;

  const GradientThemeExtension({
    required this.backgroundGradient,
    required this.buttonGradient,
  });

  @override
  GradientThemeExtension copyWith({
    LinearGradient? backgroundGradient,
    LinearGradient? buttonGradient,
  }) {
    return GradientThemeExtension(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      buttonGradient: buttonGradient ?? this.buttonGradient,
    );
  }

  @override
  GradientThemeExtension lerp(ThemeExtension<GradientThemeExtension>? other, double t) {
    if (other is! GradientThemeExtension) {
      return this;
    }
    return GradientThemeExtension(
      backgroundGradient: LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      buttonGradient: LinearGradient.lerp(buttonGradient, other.buttonGradient, t)!,
    );
  }
}
