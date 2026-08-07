import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/shared/widgets/option_picker.dart';

enum _Sample { a, b, c }

const _options = [
  OptionPickerItem(
    value: _Sample.a,
    icon: Icons.circle,
    label: 'A',
    description: 'Opción A',
  ),
  OptionPickerItem(
    value: _Sample.b,
    icon: Icons.circle,
    label: 'B',
    description: 'Opción B',
  ),
  OptionPickerItem(
    value: _Sample.c,
    icon: Icons.circle,
    label: 'C',
    description: 'Opción C',
  ),
];

Widget _harness({
  required ValueChanged<Future<_Sample?>> onPressed,
  String? helperText,
}) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => onPressed(
            showOptionPicker<_Sample>(
              context,
              title: 'Elegí una opción',
              selected: _Sample.b,
              helperText: helperText,
              options: _options,
            ),
          ),
          child: const Text('Abrir'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('muestra el título y todas las opciones', (tester) async {
    await tester.pumpWidget(_harness(onPressed: (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Elegí una opción'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Opción A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('tocar una opción cierra el sheet con el valor elegido', (
    tester,
  ) async {
    Future<_Sample?>? pending;
    await tester.pumpWidget(_harness(onPressed: (future) => pending = future));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();

    expect(await pending, _Sample.c);
  });

  testWidgets('el texto de ayuda solo aparece cuando se provee', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(onPressed: (_) {}));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Este es un texto de ayuda'), findsNothing);
  });

  testWidgets('renderiza el texto de ayuda cuando se provee', (tester) async {
    await tester.pumpWidget(
      _harness(onPressed: (_) {}, helperText: 'Este es un texto de ayuda'),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Este es un texto de ayuda'), findsOneWidget);
  });
}
