import 'dart:async';
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

/// Ajustes en memoria que emiten cada cambio, como lo hace la base real.
class _MemorySettings extends SettingsRepository {
  _MemorySettings(super.database, AppSetting initial) : _current = initial {
    _changes.add(initial);
  }

  AppSetting _current;
  final _changes = StreamController<AppSetting>.broadcast(sync: true);

  @override
  Stream<AppSetting> watchSettings() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<AppSetting> settings() async => _current;

  @override
  Future<void> saveHomeSections(List<String> sections) async {
    _current = _current.copyWith(homeSectionsJson: jsonEncode(sections));
    _changes.add(_current);
  }
}

void main() {
  late _MemorySettings repository;

  setUp(() async {
    final database = NuvTuneDatabase.forTesting(NativeDatabase.memory());
    final initial = await SettingsRepository(database).settings();
    repository = _MemorySettings(database, initial);
  });

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
    await tester.pump();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
  }

  List<String> saved() => List<String>.from(
    jsonDecode(repository._current.homeSectionsJson) as List,
  );

  bool isOn(WidgetTester tester, String label) => tester
      .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label))
      .value;

  testWidgets('el interruptor refleja y guarda el cambio al instante', (
    tester,
  ) async {
    await openSheet(tester);
    expect(isOn(tester, 'Favoritos'), isTrue);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Favoritos'));
    await tester.pumpAndSettle();
    expect(saved(), isNot(contains('favorites')));
    expect(isOn(tester, 'Favoritos'), isFalse);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Favoritos'));
    await tester.pumpAndSettle();
    expect(saved(), contains('favorites'));
    expect(isOn(tester, 'Favoritos'), isTrue);
  });

  testWidgets('arrastrar el asa cambia el orden guardado', (tester) async {
    await openSheet(tester);
    final before = saved();

    await tester.timedDrag(
      find.byIcon(Icons.drag_handle_rounded).first,
      const Offset(0, 130),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    final after = saved();
    expect(after.toSet(), before.toSet());
    expect(after.first, isNot(before.first));
  });
}
