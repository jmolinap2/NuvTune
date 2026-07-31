package com.nuvtune.engine

import kotlin.math.ln

/**
 * Presets del ecualizador (requerimiento seccion 5.3).
 *
 * Las curvas se definen sobre las diez bandas de octava del MVP. Ninguna banda
 * pasa de +6 dB y la ganancia previa automatica descuenta la banda mas alta, de
 * modo que los presets incluidos no producen clipping (criterio de aceptacion
 * 7).
 *
 * Para el modo avanzado la curva se remuestrea sobre las frecuencias de 15 o 20
 * bandas interpolando en escala logaritmica de frecuencia, que es como se
 * percibe el espectro; asi un preset suena igual con cualquier resolucion.
 */
internal object EqualizerPresets {

    const val FLAT = "Plano"
    const val CUSTOM = "Personalizado"

    private val curves10 = linkedMapOf(
        FLAT to doubleArrayOf(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
        "Pop" to doubleArrayOf(-1.0, -0.5, 0.0, 2.0, 3.5, 3.0, 1.5, 0.0, -0.5, -1.0),
        "Rock" to doubleArrayOf(4.0, 3.0, 1.5, -0.5, -1.5, -0.5, 1.5, 3.0, 3.5, 4.0),
        "Electronica" to doubleArrayOf(4.5, 3.5, 1.0, 0.0, -1.5, 1.5, 0.5, 1.0, 3.5, 4.5),
        "Hip hop" to doubleArrayOf(5.0, 4.0, 1.5, 2.5, -0.5, -0.5, 1.0, -0.5, 1.5, 2.5),
        "Jazz" to doubleArrayOf(3.0, 2.0, 1.0, 1.5, -1.0, -1.0, 0.0, 1.0, 2.0, 3.0),
        "Clasica" to doubleArrayOf(3.5, 2.5, 1.5, 0.5, -1.0, -1.0, 0.0, 1.5, 2.5, 3.5),
        "Vocal" to doubleArrayOf(-2.0, -1.5, -0.5, 1.5, 3.5, 3.5, 2.5, 1.5, 0.0, -1.0),
        "Acustica" to doubleArrayOf(3.0, 2.5, 1.5, 0.5, 1.0, 1.0, 1.5, 2.0, 2.0, 1.5),
        "Graves" to doubleArrayOf(6.0, 5.0, 3.5, 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
        "Agudos" to doubleArrayOf(0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 3.0, 4.5, 5.5, 6.0),
    )

    /** Nombres en el orden en que los muestra la interfaz, con Personalizado al final. */
    val names: List<String> = curves10.keys.toList() + CUSTOM

    fun gainsFor(presetName: String, bandCount: Int): List<Double> {
        val curve = curves10[presetName] ?: return List(bandCount) { 0.0 }
        if (bandCount == EqualizerAudioProcessor.BANDS_10) {
            return curve.toList()
        }
        return resample(
            sourceFrequencies = EqualizerAudioProcessor.centerFrequencies(
                EqualizerAudioProcessor.BANDS_10,
            ),
            sourceGains = curve,
            targetFrequencies = EqualizerAudioProcessor.centerFrequencies(bandCount),
        )
    }

    /**
     * Identifica a que preset corresponde un conjunto de ganancias, para que la
     * interfaz muestre el nombre correcto al restaurar los ajustes guardados.
     */
    fun matchPreset(gains: List<Double>): String {
        for (name in curves10.keys) {
            val candidate = gainsFor(name, gains.size)
            if (candidate.size == gains.size &&
                candidate.indices.all { kotlin.math.abs(candidate[it] - gains[it]) < 0.05 }
            ) {
                return name
            }
        }
        return CUSTOM
    }

    private fun resample(
        sourceFrequencies: DoubleArray,
        sourceGains: DoubleArray,
        targetFrequencies: DoubleArray,
    ): List<Double> = targetFrequencies.map { frequency ->
        val logTarget = ln(frequency)
        val logSource = sourceFrequencies.map { ln(it) }

        when {
            logTarget <= logSource.first() -> sourceGains.first()
            logTarget >= logSource.last() -> sourceGains.last()
            else -> {
                var upper = 1
                while (upper < logSource.size && logSource[upper] < logTarget) {
                    upper++
                }
                val lower = upper - 1
                val span = logSource[upper] - logSource[lower]
                val ratio = (logTarget - logSource[lower]) / span
                sourceGains[lower] + ratio * (sourceGains[upper] - sourceGains[lower])
            }
        }
    }
}
