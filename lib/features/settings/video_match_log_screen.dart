import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Como se eligio el video de fondo de cada cancion.
///
/// Existe para afinar el algoritmo de seleccion con datos de este telefono:
/// cuando el fondo muestra un video que no es el oficial, aqui se ve que
/// candidatos habia, con que señales llegaron y por que gano el que gano.
class VideoMatchLogScreen extends ConsumerWidget {
  const VideoMatchLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(videoMatchLogProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selección de video'),
        actions: [
          if (entries != null && entries.isNotEmpty) ...[
            IconButton(
              tooltip: 'Compartir',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _share(entries),
            ),
            IconButton(
              tooltip: 'Vaciar',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _clear(context, ref),
            ),
          ],
        ],
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(Tokens.gutter),
                child: Text(
                  'Sin resoluciones registradas. Se anota aquí cada vez que '
                  'el reproductor busca el video de una canción.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _EntryTile(entry: entries[index]),
            ),
    );
  }

  Future<void> _share(List<VideoMatchLogData> entries) async {
    final payload = [
      for (final entry in entries)
        {
          'resolvedAt': entry.resolvedAt.toIso8601String(),
          'song': {
            'title': entry.songTitle,
            'artist': entry.songArtist,
            'durationSeconds': entry.songDurationSeconds,
          },
          'query': entry.query,
          'chosen': {
            'videoId': entry.chosenVideoId,
            'score': entry.chosenScore,
            'sourceType': entry.chosenSourceType,
            'confidence': entry.chosenConfidence,
          },
          'candidates': jsonDecode(entry.candidatesJson),
        },
    ];
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/nuvtune_seleccion_video.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Selección de video de NuvTune',
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
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
    await ref.read(videoMatchLogRepositoryProvider).clear();
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final VideoMatchLogData entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matched = entry.chosenVideoId.isNotEmpty;
    final candidates = _decodeCandidates(entry.candidatesJson);

    return ExpansionTile(
      leading: Icon(
        matched ? Icons.check_circle_outline_rounded : Icons.help_outline,
        color: matched ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text('${entry.songArtist} · ${entry.songTitle}'),
      subtitle: Text(
        matched
            ? '${entry.chosenSourceType} · ${entry.chosenConfidence} · '
                  '${entry.chosenScore} puntos'
            : 'Ningún candidato superó el umbral',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        Tokens.gutter,
        0,
        Tokens.gutter,
        Tokens.space3,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(label: 'Búsqueda', value: entry.query),
        if (matched) _Field(label: 'Elegido', value: entry.chosenVideoId),
        _Field(
          label: 'Duración local',
          value: '${entry.songDurationSeconds} s',
        ),
        const SizedBox(height: Tokens.space2),
        Text(
          'Candidatos (${candidates.length})',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: Tokens.space1),
        for (final candidate in candidates)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.space2),
            child: _CandidateRow(
              candidate: candidate,
              isChosen: candidate['videoId'] == entry.chosenVideoId,
            ),
          ),
      ],
    );
  }

  static List<Map<String, Object?>> _decodeCandidates(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, Object?>>().toList();
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate, required this.isChosen});

  final Map<String, Object?> candidate;
  final bool isChosen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signals = <String>[
      if (candidate['verified'] == true) 'verificado',
      if (candidate['musicCategory'] == true) 'música',
      '${candidate['durationSeconds']} s',
      '${candidate['views']} vistas',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isChosen ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Tokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${candidate['title']}',
              style: TextStyle(
                fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            Text(
              '${candidate['uploader']}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            Text(
              signals.join(' · '),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}
