package com.nuvtune.engine

/**
 * Perfiles de mejora de audio (requerimiento seccion 5.2).
 *
 * Un perfil fija los parametros de la cadena de mejora, no la curva del
 * ecualizador: el ecualizador es del usuario y cambiarlo por detras al elegir
 * un perfil seria destruir su trabajo sin avisar. La pantalla muestra los
 * valores exactos que aplica cada perfil, de modo que "Personalizado" parte
 * siempre de algo visible.
 */
internal object EnhancementPresets {

    fun apply(
        profile: EnhancementProfile,
        current: EnhancementSettings,
    ): EnhancementSettings = when (profile) {
        // Correccion discreta: dinamica suave y nada de coloracion.
        EnhancementProfile.BALANCED -> current.copy(
            profile = profile,
            detail = DetailLevel.LOW,
            multibandStrength = 0.35,
            stereoExpansionEnabled = false,
            stereoWidth = 0.0,
        )

        // Acentua transitorios y voces; el realce medio es el limite razonable
        // antes de que los archivos comprimidos empiecen a sonar duros.
        EnhancementProfile.CLARITY -> current.copy(
            profile = profile,
            detail = DetailLevel.MEDIUM,
            multibandStrength = 0.45,
            stereoExpansionEnabled = false,
            stereoWidth = 0.0,
        )

        // Compresion mas firme para que el grave no se desborde ni tape la voz.
        EnhancementProfile.TIGHT_BASS -> current.copy(
            profile = profile,
            detail = DetailLevel.LOW,
            multibandStrength = 0.75,
            stereoExpansionEnabled = false,
            stereoWidth = 0.0,
        )

        // Para escuchar de fondo: sin realce y con la dinamica contenida.
        EnhancementProfile.SMOOTH -> current.copy(
            profile = profile,
            detail = DetailLevel.OFF,
            multibandStrength = 0.55,
            stereoExpansionEnabled = false,
            stereoWidth = 0.0,
        )

        // La expansion estereo solo tiene sentido con audifonos, y aun asi
        // moderada (requerimiento 5.2).
        EnhancementProfile.HEADPHONES -> current.copy(
            profile = profile,
            detail = DetailLevel.LOW,
            multibandStrength = 0.40,
            stereoExpansionEnabled = true,
            stereoWidth = 0.45,
        )

        // El altavoz del telefono es practicamente mono y no reproduce graves:
        // se comprime fuerte para ganar volumen util y se anula la expansion,
        // que ahi solo restaria energia al canal central.
        EnhancementProfile.PHONE_SPEAKER -> current.copy(
            profile = profile,
            detail = DetailLevel.MEDIUM,
            multibandStrength = 0.85,
            stereoExpansionEnabled = false,
            stereoWidth = 0.0,
        )

        // No toca nada: el usuario edita todos los parametros a mano.
        EnhancementProfile.CUSTOM -> current.copy(profile = profile)
    }

    /**
     * Perfil sugerido para una salida concreta. Solo se usa la primera vez que
     * aparece un tipo de salida; despues manda lo que el usuario haya guardado
     * para esa salida (requerimiento 5.4).
     */
    fun suggestedFor(output: AudioOutput): EnhancementProfile = when (output) {
        AudioOutput.SPEAKER -> EnhancementProfile.PHONE_SPEAKER
        AudioOutput.WIRED_HEADPHONES -> EnhancementProfile.HEADPHONES
        AudioOutput.BLUETOOTH -> EnhancementProfile.HEADPHONES
        AudioOutput.ANDROID_AUTO -> EnhancementProfile.BALANCED
        AudioOutput.USB_DAC -> EnhancementProfile.BALANCED
    }
}
