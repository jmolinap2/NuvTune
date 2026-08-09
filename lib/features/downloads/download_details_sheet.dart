import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/core/platform/download_engine.g.dart';
import 'package:nuvtune/core/platform/download_engine_bridge.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/core/utils/formatters.dart';

class DownloadChoice {
  const DownloadChoice({required this.analysis, required this.format});

  final VideoAnalysis analysis;
  final VideoFormatOption format;
}

Future<DownloadChoice?> showDownloadDetails(
  BuildContext context,
  SearchResultItem result,
) => showModalBottomSheet<DownloadChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => DownloadDetailsSheet(result: result),
);

/// Analiza el resultado una sola vez y convierte el botón de descarga en una
/// decisión informada: portada, fuente, duración, formato, calidad y tamaño.
class DownloadDetailsSheet extends ConsumerStatefulWidget {
  const DownloadDetailsSheet({required this.result, super.key});

  final SearchResultItem result;

  @override
  ConsumerState<DownloadDetailsSheet> createState() =>
      _DownloadDetailsSheetState();
}

class _DownloadDetailsSheetState extends ConsumerState<DownloadDetailsSheet> {
  late final DownloadEngineBridge _engine;
  AnalysisResult? _result;
  String? _error;
  String? _selectedFormatId;
  bool _loading = true;
  bool _preparingPreview = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _engine = ref.read(downloadEngineProvider);
    _load();
  }

  @override
  void dispose() {
    _engine.api.stopPreview();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _engine.initialize();
      final result = await _engine.api.analyzeUrl(widget.result.sourceUrl);
      if (!mounted) return;
      final video = result.video;
      setState(() {
        _result = result;
        _selectedFormatId = video?.audioFormats.firstOrNull?.formatId;
        _error = video == null
            ? result.errorCode?.userMessage ??
                  'No se pudieron obtener los detalles.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron obtener los detalles.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _engine.api.stopPreview();
      if (mounted) setState(() => _previewing = false);
      return;
    }
    if (_preparingPreview) return;
    setState(() => _preparingPreview = true);
    try {
      await _engine.api.startPreview(widget.result.sourceUrl);
      if (mounted) setState(() => _previewing = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el audio. Prueba actualizar el extractor en Ajustes.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _preparingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: Tokens.space2),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(Tokens.radiusPill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space3,
              Tokens.space2,
              Tokens.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Detalles de descarga',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorDetails(message: _error!, onRetry: _load)
                : _buildDetails(_result!.video!),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(VideoAnalysis video) {
    final theme = Theme.of(context);
    final selected = video.audioFormats
        .where((format) => format.formatId == _selectedFormatId)
        .firstOrNull;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Tokens.gutter),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.radiusLarge),
                  child: _NetworkCover(url: video.thumbnailUrl),
                ),
              ),
              const SizedBox(height: Tokens.space3),
              Text(video.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: Tokens.space1),
              Text(
                [
                  if ((video.author ?? '').isNotEmpty) video.author!,
                  if (video.durationSeconds > 0)
                    Formatters.duration(video.durationSeconds * 1000),
                  _platformLabel(video.platform),
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Tokens.space4),
              Row(
                children: [
                  Expanded(
                    child: _FactCard(
                      icon: Icons.image_rounded,
                      label: 'Portada',
                      value: video.thumbnailUrl == null
                          ? 'No disponible'
                          : 'Se incrustará',
                    ),
                  ),
                  const SizedBox(width: Tokens.space2),
                  Expanded(
                    child: _FactCard(
                      icon: Icons.audio_file_rounded,
                      label: 'Salida',
                      value: 'MP3 con metadatos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.space4),
              Text('Calidad de audio', style: theme.textTheme.titleMedium),
              const SizedBox(height: Tokens.space2),
              if (video.audioFormats.isEmpty)
                const Text('No hay formatos de audio disponibles.')
              else
                Wrap(
                  spacing: Tokens.space2,
                  runSpacing: Tokens.space2,
                  children: [
                    for (final format in video.audioFormats)
                      ChoiceChip(
                        selected: format.formatId == _selectedFormatId,
                        onSelected: (_) =>
                            setState(() => _selectedFormatId = format.formatId),
                        label: Text(
                          [
                            format.qualityLabel,
                            if (format.approxSizeBytes case final bytes?)
                              '≈ ${Formatters.fileSize(bytes)}',
                          ].join(' · '),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: Tokens.space4),
              Container(
                padding: const EdgeInsets.all(Tokens.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Tokens.radiusLarge),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded),
                    SizedBox(width: Tokens.space3),
                    Expanded(
                      child: Text(
                        'La fuente puede usar otro códec; NuvTune la convertirá '
                        'a MP3 y guardará título, artista y portada. El tamaño '
                        'mostrado es aproximado.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(Tokens.gutter),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _preparingPreview ? null : _togglePreview,
                icon: _preparingPreview
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _previewing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                      ),
                label: Text(_previewing ? 'Detener' : 'Escuchar'),
              ),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: FilledButton.icon(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(context).pop(
                          DownloadChoice(analysis: video, format: selected),
                        ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Descargar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _platformLabel(SourcePlatform platform) => switch (platform) {
    SourcePlatform.youtube => 'YouTube',
    SourcePlatform.tiktok => 'TikTok',
    SourcePlatform.instagram => 'Instagram',
    SourcePlatform.facebook => 'Facebook',
    SourcePlatform.unknown => 'Fuente desconocida',
  };
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: Tokens.space2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NetworkCover extends StatelessWidget {
  const _NetworkCover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: const Center(child: Icon(Icons.album_rounded, size: 64)),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

class _ErrorDetails extends StatelessWidget {
  const _ErrorDetails({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52),
            const SizedBox(height: Tokens.space3),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: Tokens.space4),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
