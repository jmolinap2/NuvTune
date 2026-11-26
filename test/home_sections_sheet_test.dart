import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/data/repositories/settings_repository.dart';
import 'package:nuvtune/features/home/home_screen.dart';
import 'package:nuvtune/features/library/library_controller.dart';

class _EmptyLibrary extends LibraryController {
  @override
  LibraryState build() => LibraryState.empty;
}

void main() {
  late NuvTuneDatabase database;
  late SettingsRepository repository;

  setUp(() {
    database = NuvTuneDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepository(database);
  });
  tearDown(() => database.close());

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          libraryProvider.overrideWith(_EmptyLibrary.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
  }

  Future<List<String>> saved() async => List<String>.from(
    jsonDecode((await repository.settings()).homeSectionsJson) as List,
  );

  testWidgets('el interruptor refleja y guarda el cambio al instante', (
    tester,
  ) async {
    await openSheet(tester);
    final favorites = find.widgetWithText(SwitchListTile, 'Favoritos');
    expect(tester.widget<SwitchListTile>(favorites).value, isTrue);

    await tester.tap(favorites);
    await tester.pumpAndSettle();

    expect(await tester.runAsync(saved), isNot(contains('favorites')));
    // Ahora esta oculta: sigue en la hoja, con el interruptor apagado.
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Favoritos'),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.widgetWithText(SwitchListTile, 'Favoritos'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(saved), contains('favorites'));
  });

  testWidgets('arrastrar el asa cambia el orden guardado', (tester) async {
    await openSheet(tester);
    final before = (await tester.runAsync(saved))!;

    final handles = find.byIcon(Icons.drag_handle_rounded);
    await tester.timedDrag(
      handles.first,
      const Offset(0, 130),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    final after = (await tester.runAsync(saved))!;
    expect(after.toSet(), before.toSet());
    expect(after.first, isNot(before.first));
  });
}
