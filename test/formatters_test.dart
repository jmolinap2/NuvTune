import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('duration usa horas solo cuando hacen falta', () {
      expect(Formatters.duration(0), '0:00');
      expect(Formatters.duration(9000), '0:09');
      expect(Formatters.duration(125000), '2:05');
      expect(Formatters.duration(3725000), '1:02:05');
    });

    test('fileSize escala a la unidad legible', () {
      expect(Formatters.fileSize(512), '512 B');
      expect(Formatters.fileSize(2048), '2.0 KB');
      expect(Formatters.fileSize(5 * 1024 * 1024), '5.0 MB');
    });

    test('los datos tecnicos ausentes se declaran, no se inventan', () {
      expect(Formatters.sampleRate(44100), '44.1 kHz');
      expect(Formatters.sampleRate(48000), '48 kHz');
      expect(Formatters.sampleRate(null), 'No disponible');
      expect(Formatters.bitDepth(-1), 'No disponible');
      expect(Formatters.bitrate(null), 'No disponible');
      expect(Formatters.bitrate(320000), '320 kbps');
      expect(Formatters.channels(2), 'Estéreo');
      expect(Formatters.channels(null), 'No disponible');
    });

    test('gainDb muestra el signo del refuerzo', () {
      expect(Formatters.gainDb(3.5), '+3.5 dB');
      expect(Formatters.gainDb(-2), '-2.0 dB');
      expect(Formatters.gainDb(0), '0.0 dB');
    });

    test('frequency abrevia los kilohercios de las bandas', () {
      expect(Formatters.frequency(31.5), '31.5');
      expect(Formatters.frequency(1000), '1k');
      expect(Formatters.frequency(16000), '16k');
    });
  });
}
