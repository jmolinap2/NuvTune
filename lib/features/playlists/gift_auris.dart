import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

/// Auris acompaña el intercambio sin convertirse en un asistente invasivo.
/// La flotacion se apaga con Reducir animaciones y cuando la ruta deja de
/// tener TickerMode activo.
class GiftAuris extends StatefulWidget {
  const GiftAuris({
    this.message,
    this.size = 150,
    this.celebrate = false,
    super.key,
  });

  final String? message;
  final double size;
  final bool celebrate;

  @override
  State<GiftAuris> createState() => _GiftAurisState();
}

class _GiftAurisState extends State<GiftAuris>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool _motionEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled == _motionEnabled) return;
    _motionEnabled = enabled;
    if (enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = RepaintBoundary(
      child: Image.asset(
        'assets/images/auris.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Auris, mascota de NuvTune',
      ),
    );

    return Semantics(
      container: true,
      label: widget.message == null ? 'Auris' : 'Auris. ${widget.message}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            child: image,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -5 * _controller.value),
              child: Transform.scale(
                scale:
                    1 + (widget.celebrate ? 0.035 : 0.018) * _controller.value,
                child: child,
              ),
            ),
          ),
          if (widget.message case final message?) ...[
            const SizedBox(height: Tokens.space2),
            Container(
              constraints: const BoxConstraints(maxWidth: 330),
              padding: const EdgeInsets.symmetric(
                horizontal: Tokens.space3,
                vertical: Tokens.space2,
              ),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.36),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(Tokens.radiusLarge),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
