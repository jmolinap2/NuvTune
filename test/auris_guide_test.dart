import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/app/theme/app_theme.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/features/settings/auris_guide.dart';

void main() {
  testWidgets('Auris respeta reducir animaciones a 320 px y texto ampliado', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: ThemeScope(
          appearance: Appearance.fallback,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                disableAnimations: true,
                textScaler: TextScaler.linear(1.6),
              ),
              child: const Scaffold(
                body: TickerMode(
                  enabled: false,
                  child: SingleChildScrollView(child: AurisGuide()),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Auris'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image == const AssetImage('assets/images/auris.png'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
