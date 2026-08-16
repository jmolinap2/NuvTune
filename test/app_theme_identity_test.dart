import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/app/theme/app_theme_identity.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

void main() {
  group('AppThemeIdentity', () {
    test('un identificador desconocido cae en Nebula Glass', () {
      expect(AppThemeIdentity.byId(null), AppThemeIdentity.nebulaGlass);
      expect(AppThemeIdentity.byId('otro'), AppThemeIdentity.nebulaGlass);
    });

    test('los identificadores guardados se conservan', () {
      for (final identity in AppThemeIdentity.values) {
        expect(AppThemeIdentity.byId(identity.id), identity);
      }
    });

    test('cada identidad apunta a un acento que existe', () {
      for (final identity in AppThemeIdentity.values) {
        expect(
          identity.accent.id,
          identity.accentId,
          reason: '${identity.name} referencia un acento inexistente',
        );
      }
    });

    test('las tres identidades son realmente distintas entre sí', () {
      // El motivo de existir de este modelo: antes «claro» y «oscuro» solo
      // cambiaban el fondo. Cada identidad debe diferir en más de un eje.
      final combinations = AppThemeIdentity.values
          .map(
            (identity) => (
              identity.surface,
              identity.typography,
              identity.density,
            ),
          )
          .toSet();
      expect(combinations.length, AppThemeIdentity.values.length);
    });

    test('Paper Loft es la identidad clara y las otras oscuras', () {
      expect(AppThemeIdentity.paperLoft.brightness, Brightness.light);
      expect(AppThemeIdentity.nebulaGlass.brightness, Brightness.dark);
      expect(AppThemeIdentity.amoledMono.brightness, Brightness.dark);
    });

    test('AMOLED Mono usa negro absoluto', () {
      expect(AppThemeIdentity.amoledMono.depth, BackgroundDepth.pureBlack);
    });

    test('cada identidad anuncia exactamente tres rasgos', () {
      for (final identity in AppThemeIdentity.values) {
        expect(identity.tags.length, 3, reason: identity.name);
      }
    });
  });

  group('ejes', () {
    test('un identificador desconocido cae en el valor por defecto', () {
      expect(SurfaceStyle.byId(null), SurfaceStyle.glass);
      expect(TypographyStyle.byId(''), TypographyStyle.expressive);
      expect(LayoutDensity.byId('nada'), LayoutDensity.balanced);
    });

    test('los identificadores guardados se conservan', () {
      for (final value in SurfaceStyle.values) {
        expect(SurfaceStyle.byId(value.id), value);
      }
      for (final value in TypographyStyle.values) {
        expect(TypographyStyle.byId(value.id), value);
      }
      for (final value in LayoutDensity.values) {
        expect(LayoutDensity.byId(value.id), value);
      }
    });

    test('solo la superficie de vidrio desenfoca', () {
      expect(SurfaceStyle.glass.glassIntensity.blur, greaterThan(0));
      expect(SurfaceStyle.flat.glassIntensity.blur, 0);
      expect(SurfaceStyle.paper.glassIntensity.blur, 0);
    });

    test('solo el papel levanta la tarjeta con sombra', () {
      expect(SurfaceStyle.paper.cardElevation, greaterThan(0));
      expect(SurfaceStyle.glass.cardElevation, 0);
      expect(SurfaceStyle.flat.cardElevation, 0);
    });

    test('la densidad ordena el espaciado de menor a mayor', () {
      expect(
        LayoutDensity.compact.spacingScale,
        lessThan(LayoutDensity.balanced.spacingScale),
      );
      expect(
        LayoutDensity.balanced.spacingScale,
        lessThan(LayoutDensity.airy.spacingScale),
      );
    });

    test('la tipografía ordena el tamaño de menor a mayor', () {
      expect(
        TypographyStyle.minimal.scale,
        lessThan(TypographyStyle.expressive.scale),
      );
      expect(
        TypographyStyle.expressive.scale,
        lessThan(TypographyStyle.editorial.scale),
      );
    });
  });
}
