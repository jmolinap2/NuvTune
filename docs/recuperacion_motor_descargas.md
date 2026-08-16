# Recuperación del motor de descargas

Estado: implementado en `1.5.0+21`.

NuvTune no intenta resolver todos los fallos actualizando `yt-dlp`. El motor
nativo clasifica primero el diagnóstico y elige una de tres acciones:

| Diagnóstico | Acción |
| --- | --- |
| Fallo de extracción o parseo, `signature extraction` o `nsig extraction` | Actualizar `yt-dlp`, reanalizar y repetir una vez |
| El formato solicitado desapareció | Reanalizar sin actualizar y repetir una vez |
| Red, 403/404/429, anti-bot, contenido privado/eliminado/regional, almacenamiento, QuickJS o challenge | No actualizar |

## Límites de seguridad

- Solo puede haber una recuperación automática por análisis, vista previa o
  descarga.
- La actualización es *single-flight*: dos trabajos no descargan el binario a
  la vez.
- Se reintenta si otro trabajo ya cambió la versión observada.
- Un intento sin versión nueva activa un enfriamiento de 15 minutos. La
  actualización manual de Ajustes no está sujeta a ese límite.
- La descarga nunca reutiliza a ciegas la solicitud fallida: después de una
  actualización vuelve a analizar el enlace con las cookies vigentes.
- La cancelación tiene prioridad incluso mientras se actualiza el extractor.
- Los registros no incluyen la URL privada del contenido.

Las reglas puras de clasificación se verifican en
`android/app/src/test/kotlin/com/nuvtune/engine/downloader/YtDlpEngineRecoveryTest.kt`.
