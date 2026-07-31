import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/features/lyrics/lrc_parser.dart';

void main() {
  group('LrcParser', () {
    test('lee marcas de tiempo con centesimas y la etiqueta offset', () {
      final parsed = LrcParser.parse('''
[ar:Artista]
[offset:250]
[00:12.50]Primera linea
[01:05.00]Segunda linea
''');

      expect(parsed.synchronized, isTrue);
      expect(parsed.offsetMs, 250);
      expect(parsed.lines.length, 2);
      expect(parsed.lines.first.timeMs, 12500);
      expect(parsed.lines.first.text, 'Primera linea');
      expect(parsed.lines.last.timeMs, 65000);
    });

    test('una misma linea con varias marcas se repite en cada una', () {
      final parsed = LrcParser.parse('[00:05.00][00:35.00]Estribillo');

      expect(parsed.lines.length, 2);
      expect(parsed.lines.first.timeMs, 5000);
      expect(parsed.lines.last.timeMs, 35000);
      expect(parsed.lines.every((line) => line.text == 'Estribillo'), isTrue);
    });

    test('agrupa la traduccion cuando comparte la marca de tiempo', () {
      final parsed = LrcParser.parse('''
[00:10.00]Hello world
[00:10.00]Hola mundo
''');

      expect(parsed.lines.length, 1);
      expect(parsed.lines.first.text, 'Hello world');
      expect(parsed.lines.first.translation, 'Hola mundo');
    });

    test('una letra sin marcas queda como texto plano', () {
      final parsed = LrcParser.parse('Solo texto\nsin tiempos');

      expect(parsed.synchronized, isFalse);
      expect(parsed.lines.length, 2);
      expect(parsed.lines.first.timeMs, isNull);
    });

    test('activeLineIndex respeta el desfase del archivo y el del usuario', () {
      final parsed = LrcParser.parse('[00:10.00]A\n[00:20.00]B');

      expect(LrcParser.activeLineIndex(parsed, 5000), -1);
      expect(LrcParser.activeLineIndex(parsed, 15000), 0);
      expect(LrcParser.activeLineIndex(parsed, 25000), 1);
      // Con un desfase de mas seis segundos la segunda linea aun no llega.
      expect(LrcParser.activeLineIndex(parsed, 25000, extraOffsetMs: 6000), 0);
    });

    test('write y parse son reversibles', () {
      final original = LrcParser.parse('[01:02.30]Linea unica');
      final rewritten = LrcParser.parse(LrcParser.write(original));

      expect(rewritten.lines.first.timeMs, original.lines.first.timeMs);
      expect(rewritten.lines.first.text, 'Linea unica');
    });

    test('una letra vacia no produce lineas', () {
      expect(LrcParser.parse('   ').isEmpty, isTrue);
    });
  });
}
