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
///
/// `favorite` ya no está aquí: pertenece al bloque de información de la
/// canción y se dibuja fijo a la derecha del título. Tenerlo además como
/// control movible creaba dos sitios distintos para la misma acción. Un
/// diseño guardado que aún lo mencione simplemente lo ignora al leerse.
enum PlayerControlId {
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
  const PlayerControlLayout._({
    required this.top,
    required this.metadata,
    required this.primary,
    required this.secondary,
    required this.footer,
  });

  factory PlayerControlLayout({
    Iterable<PlayerControlId> top = const [],
    Iterable<PlayerControlId> metadata = const [],
    required Iterable<PlayerControlId> primary,
    required Iterable<PlayerControlId> secondary,
    Iterable<PlayerControlId> footer = const [],
  }) {
    final seen = <PlayerControlId>{};
    final normalizedTop = <PlayerControlId>[];
    final topOverflow = <PlayerControlId>[];
    final normalizedMetadata = <PlayerControlId>[];
    final metadataOverflow = <PlayerControlId>[];
    final normalizedPrimary = <PlayerControlId>[];
    final normalizedSecondary = <PlayerControlId>[];
    final normalizedFooter = <PlayerControlId>[];

    for (final control in top) {
      if (control == PlayerControlId.playPause) continue;
      if (!seen.add(control)) continue;
      if (normalizedTop.length < 2) {
        normalizedTop.add(control);
      } else {
        topOverflow.add(control);
      }
    }

    // La fila del título comparte ancho con el nombre de la canción, así que
    // dos acciones son el máximo antes de empezar a recortar el texto.
    for (final control in metadata) {
      if (control == PlayerControlId.playPause) continue;
      if (!seen.add(control)) continue;
      if (normalizedMetadata.length < 2) {
        normalizedMetadata.add(control);
      } else {
        metadataOverflow.add(control);
      }
    }

    for (final control in primary) {
      if (seen.add(control)) normalizedPrimary.add(control);
    }
    for (final control in secondary) {
      if (seen.add(control)) normalizedSecondary.add(control);
    }
    normalizedSecondary.insertAll(0, [...topOverflow, ...metadataOverflow]);
    for (final control in footer) {
      if (seen.add(control)) normalizedFooter.add(control);
    }

    if (!seen.contains(PlayerControlId.playPause)) {
      normalizedPrimary.insert(
        normalizedPrimary.length ~/ 2,
        PlayerControlId.playPause,
      );
    } else if (normalizedSecondary.remove(PlayerControlId.playPause) ||
        normalizedFooter.remove(PlayerControlId.playPause)) {
      normalizedPrimary.insert(
        normalizedPrimary.length ~/ 2,
        PlayerControlId.playPause,
      );
    }

    return PlayerControlLayout._(
      top: List.unmodifiable(normalizedTop),
      metadata: List.unmodifiable(normalizedMetadata),
      primary: List.unmodifiable(normalizedPrimary),
      secondary: List.unmodifiable(normalizedSecondary),
      footer: List.unmodifiable(normalizedFooter),
    );
  }

  final List<PlayerControlId> top;

  /// Acciones a la derecha del título y el artista, en la misma fila.
  final List<PlayerControlId> metadata;
  final List<PlayerControlId> primary;
  final List<PlayerControlId> secondary;
  final List<PlayerControlId> footer;

  static PlayerControlLayout forPreset(PlayerControlPreset preset) =>
      switch (preset) {
        PlayerControlPreset.essential => PlayerControlLayout(
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [],
        ),
        PlayerControlPreset.oneHanded => PlayerControlLayout(
          primary: const [
            PlayerControlId.previous,
            PlayerControlId.playPause,
            PlayerControlId.next,
          ],
          secondary: const [
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
            PlayerControlId.seekBackward,
            PlayerControlId.seekForward,
            PlayerControlId.queue,
            PlayerControlId.sleepTimer,
          ],
        ),
      };

  /// Los identificadores desconocidos se descartan, así que un diseño guardado
  /// que todavía nombre `favorite` se lee sin él y sin dejar huecos.
  static PlayerControlLayout fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return complete;
      return PlayerControlLayout(
        top: _decodeList(decoded['top']),
        // Una preferencia guardada antes de existir esta zona simplemente no
        // trae la clave: se lee vacía y el resto del diseño no se altera.
        metadata: _decodeList(decoded['metadata']),
        primary: _decodeList(decoded['primary']),
        secondary: _decodeList(decoded['secondary']),
        footer: _decodeList(decoded['footer']),
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
    'top': top.map((control) => control.id).toList(),
    'metadata': metadata.map((control) => control.id).toList(),
    'primary': primary.map((control) => control.id).toList(),
    'secondary': secondary.map((control) => control.id).toList(),
    'footer': footer.map((control) => control.id).toList(),
  });

  PlayerControlLayout copyWith({
    Iterable<PlayerControlId>? top,
    Iterable<PlayerControlId>? metadata,
    Iterable<PlayerControlId>? primary,
    Iterable<PlayerControlId>? secondary,
    Iterable<PlayerControlId>? footer,
  }) => PlayerControlLayout(
    top: top ?? this.top,
    metadata: metadata ?? this.metadata,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    footer: footer ?? this.footer,
  );

  @override
  bool operator ==(Object other) =>
      other is PlayerControlLayout &&
      _same(top, other.top) &&
      _same(metadata, other.metadata) &&
      _same(primary, other.primary) &&
      _same(secondary, other.secondary) &&
      _same(footer, other.footer);

  @override
  int get hashCode => Object.hashAll([
    ...top,
    null,
    ...metadata,
    null,
    ...primary,
    null,
    ...secondary,
    null,
    ...footer,
  ]);

  static bool _same(List<PlayerControlId> a, List<PlayerControlId> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
