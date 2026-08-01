import 'package:flutter/material.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';

/// Selector de identidad cromatica reutilizable: lo usa Apariencia para el
/// acento global y el editor de regalo para el acento de una playlist.
class AccentSwatchGrid extends StatelessWidget {
  const AccentSwatchGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<AccentIdentity> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.space3,
      runSpacing: Tokens.space3,
      children: [
        for (final identity in AccentIdentity.all)
          AccentSwatch(
            identity: identity,
            selected: identity.id == selected,
            onTap: () => onSelected(identity),
          ),
      ],
    );
  }
}

class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    required this.identity,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AccentIdentity identity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Tokens.durationFast,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.radiusMedium),
                gradient: identity.gradient,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: identity.middle.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: Tokens.space2),
            Text(
              identity.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
