/// Textos de la interfaz.
///
/// La aplicación se entrega en un solo idioma, así que las cadenas viven en una
/// clase de constantes en lugar de en un sistema de traducción completo. Al
/// estar centralizadas aquí, agregar otro idioma consiste en convertir esta
/// clase en una interfaz con una implementación por locale, sin tocar ninguna
/// pantalla.
abstract final class AppStrings {
  // Navegación
  static const appName = 'NuvTune';
  static const tagline = 'Tu música, mejor sonido';
  static const navHome = 'Inicio';
  static const navLibrary = 'Biblioteca';
  static const navPlaylists = 'Listas';
  static const navSettings = 'Ajustes';

  // Inicio
  static const homeContinue = 'Continuar escuchando';
  static const homeFavorites = 'Favoritos';
  static const homeRecentlyPlayed = 'Reproducidas recientemente';
  static const homeRecentAlbums = 'Álbumes recientes';
  static const homeMostPlayed = 'Más reproducidas';
  static const homeFeaturedPlaylists = 'Listas destacadas';
  static const homeArtists = 'Artistas de tu biblioteca';

  // Biblioteca
  static const tabSongs = 'Canciones';
  static const tabAlbums = 'Álbumes';
  static const tabArtists = 'Artistas';
  static const tabFolders = 'Carpetas';
  static const tabPlaylists = 'Listas';
  static const genres = 'Géneros';
  static const composers = 'Compositores';
  static const recentlyAdded = 'Añadidas recientemente';

  // Acciones
  static const search = 'Buscar';
  static const sort = 'Ordenar';
  static const filter = 'Filtrar';
  static const playAll = 'Reproducir todo';
  static const shuffleAll = 'Reproducir aleatoriamente';
  static const addToQueue = 'Agregar a la cola';
  static const playNext = 'Reproducir a continuación';
  static const addToPlaylist = 'Agregar a una lista';
  static const editInfo = 'Editar información';
  static const share = 'Compartir';
  static const showFileLocation = 'Ver ubicación del archivo';
  static const excludeFolder = 'Excluir esta carpeta del escaneo';
  static const removeFromLibrary = 'Quitar de la biblioteca';
  static const deleteFromDevice = 'Eliminar del dispositivo';
  static const save = 'Guardar';
  static const cancel = 'Cancelar';
  static const discardChanges = 'Restaurar cambios';
  static const rename = 'Renombrar';
  static const duplicate = 'Duplicar';
  static const delete = 'Eliminar';
  static const create = 'Crear';
  static const retry = 'Reintentar';
  static const close = 'Cerrar';
  static const undo = 'Deshacer';

  // Reproductor
  static const nowPlaying = 'Reproduciendo';
  static const queue = 'Cola';
  static const lyrics = 'Letras';
  static const effects = 'Efectos';
  static const technicalInfo = 'Información técnica';
  static const sleepTimer = 'Temporizador de apagado';
  static const repeatOff = 'Sin repetir';
  static const repeatOne = 'Repetir canción';
  static const repeatAll = 'Repetir lista';
  static const shuffle = 'Aleatorio';
  static const favorite = 'Favorito';
  static const videoBackgroundUnavailable =
      'No se pudo cargar el video musical de esta canción';

  // Cola
  static const saveQueueAsPlaylist = 'Guardar la cola como lista';
  static const clearQueue = 'Limpiar la cola';
  static const emptyQueue = 'La cola está vacía';

  // Listas
  static const newPlaylist = 'Nueva lista';
  static const playlistName = 'Nombre de la lista';
  static const changeCover = 'Cambiar portada';
  static const exportM3u = 'Exportar como M3U';
  static const importM3u = 'Importar M3U';
  static const shareListing = 'Compartir listado';
  static const smartPlaylists = 'Listas inteligentes';
  static const smartFromFolder = 'Música de una carpeta específica';
  static const deletePlaylistNote =
      'Se elimina la lista. Las canciones siguen en el dispositivo.';

  // Ecualizador
  static const equalizer = 'Ecualizador';
  static const equalizerEnabled = 'Ecualizador activado';
  static const preset = 'Perfil';
  static const preamp = 'Ganancia previa';
  static const balance = 'Balance';
  static const monoOutput = 'Convertir a mono';
  static const autoPreventClipping = 'Evitar saturación automáticamente';
  static const bandsMode = 'Número de bandas';
  static const resetEqualizer = 'Dejar todas las bandas en cero';

  /// Aviso que exige el requerimiento sección 5.1 y el criterio 9.
  static const enhancementHonesty =
      'El ecualizador y la mejora cambian cómo suena el archivo, no recuperan '
      'la información que se perdió al comprimirlo.';

  // Mejora de audio (requerimiento 5.1 y 5.2)
  static const enhancementTitle = 'Mejorar audio';
  static const enhancementSubtitle =
      'Cadena completa: realce, dinámica, normalización y limitador.';
  static const enhancementCompare = 'Comparar con la mejora apagada';
  static const enhancementProfile = 'Perfil';
  static const enhancementDetail = 'Realce de detalle';
  static const enhancementDetailWarning =
      'En nivel alto puede sonar artificial, sobre todo en archivos de baja '
      'calidad. Lo que se añade son armónicos calculados, no información '
      'recuperada del original.';
  static const enhancementMultiband = 'Procesamiento dinámico multibanda';
  static const enhancementNormalization = 'Normalización de volumen';
  static const enhancementStereo = 'Imagen estéreo';
  static const enhancementLimiter = 'Limitador';
  static const enhancementLimiterNote =
      'Siempre activo al final de la cadena mientras la mejora esté encendida. '
      'Es lo que impide que la suma de refuerzos sature la salida, y por eso no '
      'se puede desactivar.';

  // Fuentes remotas (requerimiento 10)
  static const remoteSources = 'Fuentes remotas';
  static const remoteSourcesNote =
      'Las fuentes remotas se muestran siempre aparte de la biblioteca local y '
      'nunca se mezclan con ella.';
  static const addRemoteSource = 'Agregar fuente';
  static const remoteBrowse = 'Explorar';
  static const fetchLyricsOnline = 'Buscar letra en internet';

  // Editor
  static const editSong = 'Editar canción';
  static const editSeveralSongs = 'Editar varias canciones';
  static const fieldTitle = 'Título';
  static const fieldArtist = 'Artista';
  static const fieldAlbumArtist = 'Artista del álbum';
  static const fieldAlbum = 'Álbum';
  static const fieldGenre = 'Género';
  static const fieldYear = 'Año';
  static const fieldTrackNumber = 'Número de pista';
  static const fieldDiscNumber = 'Número de disco';
  static const fieldComposer = 'Compositor';
  static const fieldComment = 'Comentario';
  static const fieldLyrics = 'Letra';
  static const cover = 'Portada';
  static const coverFromGallery = 'Elegir de la galería';
  static const coverFromCamera = 'Tomar fotografía';
  static const coverFromFiles = 'Buscar en archivos';
  static const coverFromClipboard = 'Usar una imagen copiada';
  static const coverRemove = 'Eliminar portada';
  static const coverApplyToAlbum = 'Aplicar a todo el álbum';
  static const coverEmbedInFile = 'Incrustar la portada en el archivo';
  static const coverAppOnly = 'Usar la portada solo dentro de la aplicación';
  static const batchApply = 'Aplicar en lote';

  // Completar metadata con internet
  static const metadataLookupTitle = 'Completar con internet';
  static const metadataLookupSubtitle =
      'Busca en MusicBrainz género, artista, compositor y portada de las '
      'canciones a las que les falte alguno.';
  static const metadataLookupStart = 'Buscar coincidencias';
  static const metadataLookupStop = 'Detener búsqueda';
  static const metadataLookupApplySelected = 'Aplicar seleccionadas';
  static const metadataLookupNoPending =
      'Género, artista y compositor ya están completos';
  static const metadataLookupNoMatch = 'Sin coincidencia';

  // Letras
  static const noLyrics = 'Esta canción no tiene letra guardada';
  static const lyricsOffset = 'Ajustar desfase';
  static const lyricsAutoScroll = 'Desplazamiento automático';
  static const lyricsAssociateFile = 'Asociar un archivo LRC';
  static const lyricsEdit = 'Editar texto';
  static const lyricsSaveLrc = 'Guardar como archivo LRC';

  // Ajustes
  static const settingsLibrary = 'Biblioteca';
  static const settingsExcludedFolders = 'Carpetas excluidas';
  static const settingsSourceFolders = 'Carpetas de música';
  static const settingsAppearance = 'Apariencia';
  static const settingsPlayback = 'Reproducción';
  static const settingsQuality = 'Calidad';
  static const settingsBluetooth = 'Bluetooth';
  static const settingsAndroidAuto = 'Android Auto';
  static const settingsMetadata = 'Metadatos';
  static const settingsWidgets = 'Widgets';
  static const settingsBackup = 'Copias de seguridad';
  static const settingsPrivacy = 'Privacidad';
  static const settingsAbout = 'Acerca de';
  static const rescanLibrary = 'Volver a escanear la biblioteca';
  static const dynamicColor = 'Colores tomados de la portada';
  static const pureBlack = 'Fondo negro puro';
  static const restoreQueue = 'Restaurar la última cola al abrir';
  static const gapless = 'Reproducción sin espacios';
  static const crossfade = 'Crossfade';
  static const fadeOnPause = 'Fundido al pausar y reanudar';
  static const directMode = 'Modo directo';
  static const directModeNote =
      'Reproduce con el menor procesamiento posible. Desactiva la mejora, el '
      'ecualizador, el balance y la conversión a mono, y permite audio offload.';
  static const allowOffload = 'Permitir audio offload';
  static const playbackSpeed = 'Velocidad';
  static const playbackPitch = 'Tono';
  static const outputDevice = 'Salida de audio';

  // Apariencia
  static const appearanceAccent = 'Color de la aplicación';
  static const appearanceAccentNote =
      'Define el degradado de la marca: botones, barras del ecualizador y '
      'elementos activos de toda la aplicación.';
  static const appearanceDepth = 'Profundidad del fondo';
  static const appearanceGlass = 'Efecto de vidrio';
  static const appearanceGlassNote =
      'Cuánto dejan ver las tarjetas lo que hay detrás. En «Sutil» se dibujan '
      'sin desenfoque, que es la opción más ligera.';
  static const appearancePreview = 'Vista previa';

  // Widgets de inicio (requerimiento 9.2)
  static const widgetsEnable = 'Activar widgets';
  static const widgetsPreview = 'Vista previa';
  static const widgetsStyle = 'Estilo del widget';
  static const widgetsSize = 'Tamaño';
  static const widgetsAppearance = 'Apariencia';
  static const widgetsContent = 'Información a mostrar';
  static const widgetsBehaviour = 'Comportamiento';
  static const widgetsHowTo = 'Cómo añadir el widget';

  static const privacyNote =
      'Toda la biblioteca permanece en el dispositivo. NuvTune no necesita '
      'cuenta ni servidor, no envía archivos a ninguna parte y no incluye '
      'publicidad.';
  static const androidAutoNote =
      'NuvTune aparece en Android Auto con las canciones, los álbumes, los '
      'artistas y las carpetas del dispositivo.';

  // Permisos y estados vacíos
  static const permissionTitle = 'Permiso de música';
  static const permissionBody =
      'NuvTune necesita permiso para leer los archivos de audio del '
      'dispositivo. No pide acceso al resto del almacenamiento.';
  static const grantPermission = 'Conceder permiso';
  static const openSystemSettings = 'Abrir ajustes del sistema';
  static const emptyLibrary = 'No se encontró música en el dispositivo';
  static const emptyLibraryHint =
      'Comprueba las carpetas excluidas o vuelve a escanear la biblioteca.';
  static const scanning = 'Escaneando la biblioteca…';
  static const noResults = 'Sin resultados';
  static const unsupportedFormat = 'Formato no compatible con este dispositivo';
}
