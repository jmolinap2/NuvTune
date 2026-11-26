import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:bip340/bip340.dart' as bip340;
import 'package:nuvtune/features/community/community_exception.dart';

/// Par de claves de Nostr (BIP-340). La clave secreta es la identidad: quien
/// la tiene es esa persona, y no hay forma de recuperarla si se pierde.
class NostrKeys {
  const NostrKeys._(this.secretHex, this.publicHex);

  /// Clave nueva con aleatoriedad criptografica del sistema.
  factory NostrKeys.generate() =>
      NostrKeys.fromSecretHex(_hex(_randomBytes(32)));

  factory NostrKeys.fromSecretHex(String secretHex) =>
      NostrKeys._(secretHex, bip340.getPublicKey(secretHex));

  /// Acepta `nsec1...` o 64 caracteres hexadecimales.
  factory NostrKeys.parseSecret(String input) {
    final text = input.trim();
    if (text.startsWith('nsec1')) {
      return NostrKeys.fromSecretHex(decodeBech32('nsec', text));
    }
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(text)) {
      return NostrKeys.fromSecretHex(text.toLowerCase());
    }
    throw const CommunityException('La clave secreta no es válida.');
  }

  final String secretHex;
  final String publicHex;

  String get nsec => encodeBech32('nsec', secretHex);

  /// Codigo de amigo: lo que le das a otra persona para que te agregue.
  String get npub => encodeBech32('npub', publicHex);

  String sign(String messageHex) =>
      bip340.sign(secretHex, messageHex, _hex(_randomBytes(32)));

  static bool verify(String publicHex, String messageHex, String signature) =>
      bip340.verify(publicHex, messageHex, signature);
}

/// `npub1...` o hexadecimal de 64 caracteres -> hexadecimal de la clave publica.
String parsePublicKey(String input) {
  final text = input.trim();
  if (text.startsWith('npub1')) return decodeBech32('npub', text);
  if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(text)) return text.toLowerCase();
  throw const CommunityException('El código de amigo no es válido.');
}

String encodeBech32(String hrp, String hex) {
  final data = _convertBits(_unhex(hex), 8, 5, pad: true);
  return const Bech32Codec().encode(Bech32(hrp, data));
}

String decodeBech32(String hrp, String text) {
  final Bech32 decoded;
  try {
    decoded = const Bech32Codec().decode(text, text.length);
  } on Exception {
    throw const CommunityException('El código no es válido (checksum).');
  }
  if (decoded.hrp != hrp) {
    throw CommunityException('Se esperaba un código $hrp.');
  }
  return _hex(_convertBits(decoded.data, 5, 8, pad: false));
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> _unhex(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];

List<int> _convertBits(List<int> data, int from, int to, {required bool pad}) {
  var accumulator = 0;
  var bits = 0;
  final result = <int>[];
  final maxValue = (1 << to) - 1;
  for (final value in data) {
    accumulator = (accumulator << from) | value;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((accumulator >> bits) & maxValue);
    }
    accumulator &= (1 << bits) - 1;
  }
  if (pad) {
    if (bits > 0) result.add((accumulator << (to - bits)) & maxValue);
  } else if (bits >= from || accumulator != 0) {
    throw const CommunityException('El código no es válido (relleno).');
  }
  return result;
}
