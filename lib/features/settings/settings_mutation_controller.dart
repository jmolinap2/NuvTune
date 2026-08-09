import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/core/providers.dart';
import 'package:nuvtune/data/db/database.dart';
import 'package:nuvtune/features/player/player_controller.dart';
import 'package:nuvtune/features/settings/settings_engine_config.dart';

enum SettingsSyncTarget { audio, widget, deviceControls }

enum SettingsSaveStatus { idle, saving, saved, error }

class SettingsMutationState {
  const SettingsMutationState({
    this.status = SettingsSaveStatus.idle,
    this.message,
    this.revision = 0,
  });

  final SettingsSaveStatus status;
  final String? message;
  final int revision;
}

final settingsMutationProvider =
    NotifierProvider<SettingsMutationController, SettingsMutationState>(
      SettingsMutationController.new,
    );

/// Único punto de escritura para Ajustes.
///
/// Además de persistir, sincroniza únicamente los consumidores que necesitan
/// conocer el cambio. El estado breve de guardado alimenta la reacción de
/// Auris y evita que cada pantalla implemente su propio manejo de errores.
class SettingsMutationController extends Notifier<SettingsMutationState> {
  @override
  SettingsMutationState build() => const SettingsMutationState();

  Future<bool> save(
    AppSettingsCompanion companion, {
    Set<SettingsSyncTarget> sync = const {},
  }) async {
    final revision = state.revision + 1;
    state = SettingsMutationState(
      status: SettingsSaveStatus.saving,
      revision: revision,
    );

    try {
      final repository = ref.read(settingsRepositoryProvider);
      await repository.update(companion);

      if (sync.contains(SettingsSyncTarget.audio)) {
        await ref.read(playbackProvider.notifier).pushAudioSettings();
      }
      if (sync.contains(SettingsSyncTarget.widget) ||
          sync.contains(SettingsSyncTarget.deviceControls)) {
        final settings = await repository.settings();
        final api = ref.read(engineProvider).api;
        if (sync.contains(SettingsSyncTarget.widget)) {
          api.setWidgetConfig(widgetConfigOf(settings));
        }
        if (sync.contains(SettingsSyncTarget.deviceControls)) {
          api.setDeviceControlConfig(deviceControlConfigOf(settings));
        }
      }

      state = SettingsMutationState(
        status: SettingsSaveStatus.saved,
        message: 'Ajustes guardados',
        revision: revision,
      );
      unawaited(_returnToIdle(revision));
      return true;
    } catch (error) {
      state = SettingsMutationState(
        status: SettingsSaveStatus.error,
        message: 'No se pudo guardar el cambio',
        revision: revision,
      );
      return false;
    }
  }

  void clearError() {
    if (state.status == SettingsSaveStatus.error) {
      state = SettingsMutationState(revision: state.revision);
    }
  }

  Future<void> _returnToIdle(int revision) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (state.revision == revision &&
        state.status == SettingsSaveStatus.saved) {
      state = SettingsMutationState(revision: revision);
    }
  }
}
