import 'package:flutter/material.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/data/repositories/library_repository.dart';

/// Barra de busqueda, orden y filtro que comparten las secciones de la
/// biblioteca (requerimiento seccion 4.1).
class SortFilterBar extends StatelessWidget {
  const SortFilterBar({
    required this.search,
    required this.onSearchChanged,
    this.sort,
    this.direction,
    this.onSortChanged,
    this.filter,
    this.onFilterChanged,
    this.availableSorts = SongSort.values,
    this.trailing,
    super.key,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;
  final SongSort? sort;
  final SortDirection? direction;
  final void Function(SongSort sort, SortDirection direction)? onSortChanged;
  final SongFilter? filter;
  final ValueChanged<SongFilter>? onFilterChanged;
  final List<SongSort> availableSorts;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _SearchField(value: search, onChanged: onSearchChanged),
          ),
          if (onSortChanged != null && sort != null && direction != null)
            _SortButton(
              sort: sort!,
              direction: direction!,
              available: availableSorts,
              onChanged: onSortChanged!,
            ),
          if (onFilterChanged != null && filter != null)
            _FilterButton(filter: filter!, onChanged: onFilterChanged!),
          ?trailing,
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppStrings.search,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.direction,
    required this.available,
    required this.onChanged,
  });

  final SongSort sort;
  final SortDirection direction;
  final List<SongSort> available;
  final void Function(SongSort sort, SortDirection direction) onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      tooltip: AppStrings.sort,
      icon: const Icon(Icons.sort_rounded),
      onSelected: (value) {
        if (value is SongSort) {
          onChanged(value, direction);
        } else if (value is SortDirection) {
          onChanged(sort, value);
        }
      },
      itemBuilder: (context) => [
        for (final option in available)
          CheckedPopupMenuItem(
            value: option,
            checked: option == sort,
            child: Text(option.label),
          ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: SortDirection.ascending,
          checked: direction == SortDirection.ascending,
          child: const Text('Ascendente'),
        ),
        CheckedPopupMenuItem(
          value: SortDirection.descending,
          checked: direction == SortDirection.descending,
          child: const Text('Descendente'),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.filter, required this.onChanged});

  final SongFilter filter;
  final ValueChanged<SongFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<SongFilter>(
      tooltip: AppStrings.filter,
      icon: Icon(
        filter == SongFilter.all
            ? Icons.filter_list_rounded
            : Icons.filter_list_alt,
        color: filter == SongFilter.all ? null : scheme.primary,
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in SongFilter.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == filter,
            child: Text(option.label),
          ),
      ],
    );
  }
}

/// Cabecera con "reproducir todo" y "aleatorio" (requerimiento seccion 4.1).
class PlayAllHeader extends StatelessWidget {
  const PlayAllHeader({
    required this.count,
    required this.onPlayAll,
    required this.onShuffleAll,
    this.subtitle,
    super.key,
  });

  final int count;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subtitle ?? (count == 1 ? '1 canción' : '$count canciones'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          IconButton.filledTonal(
            onPressed: count == 0 ? null : onShuffleAll,
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: AppStrings.shuffleAll,
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: count == 0 ? null : onPlayAll,
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: AppStrings.playAll,
          ),
        ],
      ),
    );
  }
}
