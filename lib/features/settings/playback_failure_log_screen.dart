import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Una entrada del registro de fallos de reproduccion.
///
/// El motor nativo escribe JSON Lines; el parseo vive aqui porque es el
/// unico lugar que lo necesita.
class _FailureEntry {
  _FailureEntry({
    required this.timestamp,
    required this.stage,
    required this.title,
    required this.filePath,
    required this.mimeType,
    required this.code,
    required this.message,
  });

  factory _FailureEntry.fromJson(Map<String, dynamic> json) => _FailureEntry(
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    stage: json['stage'] as String? ?? 'DESCONOCIDO',
    title: json['title'] as String?,
    filePath: json['filePath'] as String?,
    mimeType: json['mimeType'] as String?,
    code: json['code'] as String?,
    message: json['message'] as String? ?? '',
  );

  final DateTime timestamp;
  final String stage;
  final String? title;
  final String? filePath;
  final String? mimeType;
  final String? code;
  final String message;
}

const _stageLabels = {
  'SCAN': 'Detectado al escanear',
  'MANUAL_PLAY': 'Fallo al reproducir a propósito',
  'AUTO_SKIP': 'Falló solo en la cola',
  'SHORT_PLAYBACK': 'Terminó antes de tiempo',
};

const _stageIcons = {
  'SCAN': Icons.search_off_rounded,
  'MANUAL_PLAY': Icons.error_outline_rounded,
  'AUTO_SKIP': Icons.skip_next_rounded,
  'SHORT_PLAYBACK': Icons.timer_off_rounded,
};

/// Todo lo que falló al leer o reproducir música: detectado en el escaneo,
/// al tocar una canción a propósito, mientras la cola avanzaba sola, o una
/// pista que terminó mucho antes de lo que declaraba durar.
///
/// Existe porque adivinar qué códecs faltan a partir del tipo de archivo no
/// alcanza: hay canciones que declaran un formato soportado y aun así
/// fallan al decodificarse (archivo corrupto, descarga incompleta). Este es
/// el registro de lo que pasa de verdad en este teléfono.
class PlaybackFailureLogScreen extends ConsumerStatefulWidget {
  const PlaybackFailureLogScreen({super.key});

  @override
  ConsumerState<PlaybackFailureLogScreen> createState() =>
      _PlaybackFailureLogScreenState();
}

class _PlaybackFailureLogScreenState
    extends ConsumerState<PlaybackFailureLogScreen> {
  List<_FailureEntry>? _entries;
  String? _rawJson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(engineProvider).api.readPlaybackFailureLog();
    final parsed = <_FailureEntry>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        parsed.add(_FailureEntry.fromJson(item as Map<String, dynamic>));
      }
    } catch (_) {
      // Una linea suelta con formato invalido no debe tirar abajo el resto.
    }
    parsed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() {
      _entries = parsed;
      _rawJson = raw;
      _loading = false;
    });
  }

  Future<void> _share() async {
    final raw = _rawJson;
    if (raw == null || raw == '[]') return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/nuvtune_registro_reproduccion.json');
    await file.writeAsString(raw);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Registro de reproducción de NuvTune',
      ),
    );
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Vaciar el registro?'),
        content: const Text('Se borran todas las entradas guardadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(engineProvider).api.clearPlaybackFailureLog();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de reproducción'),
        actions: [
          if (entries != null && entries.isNotEmpty) ...[
            IconButton(
              tooltip: 'Compartir',
              icon: const Icon(Icons.share_rounded),
              onPressed: _share,
            ),
            IconButton(
              tooltip: 'Vaciar',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _clear,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : entries == null || entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(Tokens.gutter),
                child: Text(
                  'Sin fallos registrados. Se anota aquí cualquier canción '
                  'que no se pueda leer o reproducir, apenas ocurra.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: Icon(
                    _stageIcons[entry.stage] ?? Icons.error_outline_rounded,
                  ),
                  title: Text(entry.title ?? 'Sin título'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_stageLabels[entry.stage] ?? entry.stage),
                      Text(entry.message),
                      Text(
                        [
                          if (entry.mimeType != null) entry.mimeType!,
                          if (entry.code != null) entry.code!,
                          Formatters.dateTime(entry.timestamp),
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
