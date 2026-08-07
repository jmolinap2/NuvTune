import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/download_engine.g.dart';
import 'package:nuvtune/core/platform/download_engine_bridge.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/downloads/downloads_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Buscador de canciones para descargar (motor heredado de
/// C:\Repos\NuvClip: yt-dlp + ffmpeg nativos). Las descargas terminadas
/// aparecen solas en la biblioteca normal (Biblioteca > Canciones), no hay
/// una lista aparte que revisar.
///
/// La descarga esta en zona gris de los TOS de estas plataformas: por eso el
/// aviso fijo debajo del buscador.
class SongSearchScreen extends ConsumerStatefulWidget {
  const SongSearchScreen({super.key});

  @override
  ConsumerState<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends ConsumerState<SongSearchScreen> {
  final _controller = TextEditingController();
  List<SearchResultItem> _results = const [];
  bool _loading = false;
  bool _searched = false;

  StreamSubscription<DownloadCompletedEvent>? _completedSub;
  StreamSubscription<DownloadFailedEvent>? _failedSub;

  @override
  void initState() {
    super.initState();
    final bridge = ref.read(downloadEngineProvider);
    _completedSub = bridge.completed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Descargada: ${event.fileName}')),
      );
    });
    _failedSub = bridge.failed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.errorCode.userMessage)),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _completedSub?.cancel();
    _failedSub?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    try {
      final engine = ref.read(downloadEngineProvider);
      // La primera vez, el motor todavia puede estar extrayendo sus
      // binarios (arranque no bloqueante desde bootstrap.dart); esperar
      // aqui evita buscar antes de que este listo.
      await engine.initialize();
      final results = await engine.api.search(query, 12);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo buscar. Revisa tu conexión e inténtalo de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(SearchResultItem result) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(downloadsControllerProvider.notifier).download(result);
    if (!mounted || error == null) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(downloadsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar canciones')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space4,
              Tokens.gutter,
              Tokens.space2,
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Artista o canción',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Tokens.radiusPill),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Text(
              'Úsalo solo para contenido de dominio público o de uso '
              'personal permitido en tu jurisdicción.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: Tokens.space2),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: !_searched
                ? const EmptyState(
                    icon: Icons.music_note_outlined,
                    title: 'Busca una canción',
                    message: 'Escribe un artista o título y pulsa buscar.',
                  )
                : _results.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        message: 'Prueba con otro término de búsqueda.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: Tokens.space5),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          final percent = progress[result.sourceUrl];
                          return ListTile(
                            leading: const Icon(Icons.music_note_rounded),
                            title: Text(
                              result.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              result.author ?? 'Autor desconocido',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: percent != null
                                ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      value: percent / 100,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.download_rounded),
                                    onPressed: () => _download(result),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
