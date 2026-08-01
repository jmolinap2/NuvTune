import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/network/piped_client.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/features/downloads/downloads_controller.dart';
import 'package:nuvtune/shared/widgets/empty_state.dart';

/// Buscador de canciones para descargar (feature "buscar y descargar
/// canciones"), sobre la API publica de Piped.
///
/// La descarga desde YouTube esta en zona gris de sus TOS: por eso el aviso
/// fijo debajo del buscador.
class SongSearchScreen extends ConsumerStatefulWidget {
  const SongSearchScreen({super.key});

  @override
  ConsumerState<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends ConsumerState<SongSearchScreen> {
  final _controller = TextEditingController();
  List<PipedSearchResult> _results = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    final results = await ref.read(pipedClientProvider).searchMany(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
      _searched = true;
    });
  }

  Future<void> _download(PipedSearchResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(downloadsControllerProvider.notifier).startDownload(
            result.videoId,
            title: result.title,
            artist: result.uploaderName,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Descargada: ${result.title}')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo descargar "${result.title}"')),
      );
    }
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
                          final percent = progress[result.videoId];
                          return ListTile(
                            leading: const Icon(Icons.music_note_rounded),
                            title: Text(
                              result.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              result.uploaderName,
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
