import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/app/theme/app_theme.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

void main() {
  test('los temas claro y oscuro conservan el mismo énfasis', () {
    final light = AppTheme.light(
      accent: AccentIdentity.aurora,
      depth: BackgroundDepth.warm,
    );
    final dark = AppTheme.dark(
      accent: AccentIdentity.aurora,
      depth: BackgroundDepth.warm,
    );

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, AccentIdentity.aurora.middle);
    expect(dark.colorScheme.primary, AccentIdentity.aurora.middle);
    expect(light.scaffoldBackgroundColor, isNot(dark.scaffoldBackgroundColor));
  });

  test('AMOLED conserva negro absoluto en el tema oscuro', () {
    final theme = AppTheme.dark(depth: BackgroundDepth.pureBlack);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
  });
}
