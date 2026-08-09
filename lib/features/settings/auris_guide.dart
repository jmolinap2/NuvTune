import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/app/theme/theme_scope.dart';
import 'package:nuvtune/features/settings/settings_mutation_controller.dart';

/// Encabezado ligero de Ajustes con la mascota Auris.
class AurisGuide extends ConsumerStatefulWidget {
  const AurisGuide({super.key});

  @override
  ConsumerState<AurisGuide> createState() => _AurisGuideState();
}

class _AurisGuideState extends ConsumerState<AurisGuide>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
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
      _idle.repeat(reverse: true);
    } else {
      _idle.stop();
      _idle.value = 0;
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeScope.of(context).accent;
    final save = ref.watch(settingsMutationProvider);
    ref.listen(settingsMutationProvider, (previous, next) {
      if (_motionEnabled &&
          previous?.revision != next.revision &&
          next.status == SettingsSaveStatus.saved) {
        _pulse.forward(from: 0);
      }
    });

    final isError = save.status == SettingsSaveStatus.error;
    final message = switch (save.status) {
      SettingsSaveStatus.saving => 'Guardando tu configuración…',
      SettingsSaveStatus.saved => 'Listo, guardé el cambio.',
      SettingsSaveStatus.error =>
        save.message ?? 'No pude guardar el último cambio.',
      SettingsSaveStatus.idle =>
        'Personaliza cómo se ve y cómo responde NuvTune.',
    };

    return Semantics(
      container: true,
      label: 'Auris. $message',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusLarge),
          border: Border.all(
            color: isError
                ? const Color(0xFFFF5470).withValues(alpha: 0.55)
                : accent.middle.withValues(alpha: 0.30),
          ),
          gradient: LinearGradient(
            colors: [
              (isError ? const Color(0xFFFF5470) : accent.middle).withValues(
                alpha: 0.15,
              ),
              accent.start.withValues(alpha: 0.07),
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_idle, _pulse]),
              child: const RepaintBoundary(
                child: Image(
                  image: AssetImage('assets/images/auris.png'),
                  width: 78,
                  height: 78,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              builder: (context, child) {
                final pulse = Curves.easeOutBack.transform(_pulse.value);
                return Transform.translate(
                  offset: Offset(0, -2.5 * _idle.value),
                  child: Transform.scale(
                    scale: 1 + 0.025 * _idle.value + 0.055 * pulse,
                    child: child,
                  ),
                );
              },
            ),
            const SizedBox(width: Tokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Auris',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (save.status == SettingsSaveStatus.saving) ...[
                        const SizedBox(width: Tokens.space2),
                        const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Tokens.space1),
                  AnimatedSwitcher(
                    duration: Tokens.durationFast,
                    child: Text(
                      message,
                      key: ValueKey(save.status),
                      style: TextStyle(
                        height: 1.25,
                        fontSize: 12.5,
                        color: isError
                            ? const Color(0xFFFF8FA1)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
