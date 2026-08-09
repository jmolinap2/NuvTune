import 'dart:convert';

/// Diseños rápidos de los controles del reproductor.
enum PlayerControlPreset {
  essential('essential', 'Esencial'),
  complete('complete', 'Completo'),
  oneHanded('oneHanded', 'Una mano'),
  custom('custom', 'Personalizado');

  const PlayerControlPreset(this.id, this.label);

  final String id;
  final String label;

  static PlayerControlPreset byId(String id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => PlayerControlPreset.complete,
  );
}

enum ControlHandedness {
  left('left', 'Izquierda'),
  right('right', 'Derecha');

  const ControlHandedness(this.id, this.label);

  final String id;
  final String label;

  static ControlHandedness byId(String id) => values.firstWhere(
    (value) => value.id == id,
    orElse: () => ControlHandedness.right,
  );
}

/// Acciones que pueden formar parte del bloque personalizable.
enum PlayerControlId {
  favorite('favorite', 'Favorito'),
  shuffle('shuffle', 'Aleatorio'),
  previous('previous', 'Anterior'),
  playPause('playPause', 'Reproducir o pausar'),
  next('next', 'Siguiente'),
  repeat('repeat', 'Repetición'),
  seekBackward('seekBackward', 'Retroceder 10 s'),
  seekForward('seekForward', 'Avanzar 30 s'),
  queue('queue', 'Cola'),
  sleepTimer('sleepTimer', 'Temporizador');

  const PlayerControlId(this.id, this.label);

  final String id;
  final String label;

  static PlayerControlId? tryById(Object? id) {
    if (id is! String) return null;
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// Orden visible de controles primarios y secundarios.
///
/// La normalización elimina valores desconocidos o repetidos y garantiza que
/// reproducir/pausar nunca desaparezca. Así una preferencia antigua o dañada
/// no puede dejar el reproductor sin su acción esencial.
class PlayerControlLayout {
  const PlayerControlLayout._({required this.primary, required this.secondary});

  factory PlayerControlLayout({
    required Iterable<PlayerControlId> primary,
    required Iterable<PlayerControlId> secondary,
  }) {
    final seen = <PlayerControlId>{};
    final normalizedPrimary = <PlayerControlId>[];
    final normalizedSecondary = <PlayerControlId>[];

    for (final control in primary) {
      if (seen.add(control)) normalizedPrimary.add(control);
    }
    for (final control in secondary) {
      if (seen.add(control)) normalizedSecondary.add(control);
    }

    if (!seen.contains(PlayerControlId.playPause)) {
      normalizedPrimary.insert(
        normalizedPrimary.length ~/ 2,
        PlayerControlId.playPause,
      );
    } else if (normalizedSecondary.remove(PlayerControlId.playPause)) {
      normalizedPrimary.insert(
        normalizedPrimary.length ~/ 2,
        PlayerControlId.playPause,
      );
    }

    return PlayerControlLayout._(
      primary: List.unmodifiable(normalizedPrimary),
      secondary: List.unmodifiable(normalizedSecondary),
    );
  }

  final List<PlayerControlId> primary;
  final List<PlayerControlId> secondary;

  static PlayerControlLayout forPreset(PlayerControlPreset preset) =>
      switch (preset) {
        PlayerControlPreset.essential => PlayerControlLayout(
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [PlayerControlId.favorite],
        ),
        PlayerControlPreset.oneHanded => PlayerControlLayout(
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [
            PlayerControlId.favorite,
            PlayerControlId.shuffle,
            PlayerControlId.repeat,
            PlayerControlId.queue,
          ],
        ),
        PlayerControlPreset.complete ||
        PlayerControlPreset.custom => PlayerControlLayout(
          primary: const [
            PlayerControlId.shuffle,
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
            PlayerControlId.repeat,
          ],
          secondary: const [
            PlayerControlId.favorite,
            PlayerControlId.seekBackward,
            PlayerControlId.seekForward,
            PlayerControlId.queue,
            PlayerControlId.sleepTimer,
          ],
        ),
      };

  static PlayerControlLayout fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return complete;
      return PlayerControlLayout(
        primary: _decodeList(decoded['primary']),
        secondary: _decodeList(decoded['secondary']),
      );
    } on FormatException {
      return complete;
    }
  }

  static Iterable<PlayerControlId> _decodeList(Object? value) sync* {
    if (value is! List) return;
    for (final item in value) {
      final control = PlayerControlId.tryById(item);
      if (control != null) yield control;
    }
  }

  static final complete = forPreset(PlayerControlPreset.complete);

  String toJsonString() => jsonEncode({
    'primary': primary.map((control) => control.id).toList(),
    'secondary': secondary.map((control) => control.id).toList(),
  });

  PlayerControlLayout copyWith({
    Iterable<PlayerControlId>? primary,
    Iterable<PlayerControlId>? secondary,
  }) => PlayerControlLayout(
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
  );

  @override
  bool operator ==(Object other) =>
      other is PlayerControlLayout &&
      _same(primary, other.primary) &&
      _same(secondary, other.secondary);

  @override
  int get hashCode => Object.hashAll([...primary, null, ...secondary]);

  static bool _same(List<PlayerControlId> a, List<PlayerControlId> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
