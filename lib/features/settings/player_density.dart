/// Cuanto aire deja el reproductor alrededor de la portada y los controles.
///
/// Es un unico dato con un unico escritor (la preferencia guardada) que escala
/// de forma proporcional la portada, las separaciones y el tamaño de los
/// iconos. Se prefirio esto a deslizadores independientes por la regla 1: tres
/// medidas sueltas se pueden combinar en estados contradictorios -portada
/// enorme mas separaciones enormes deja los controles fuera de la pantalla- y
/// no habria una sola fuente que decidiera el resultado.
///
/// La densidad NO decide cuanto mide la portada en pixeles: eso lo reparte el
/// propio reproductor con la altura real disponible (ver `_NowPlayingTab`).
/// La densidad solo expresa el gusto por encima de ese reparto, de modo que
/// ningun valor pueda dejar los controles fuera de pantalla.
enum PlayerDensity {
  compact('compact', 'Compacta', coverFraction: 0.66, iconScale: 0.86, gapScale: 0.62),
  normal('normal', 'Normal', coverFraction: 0.80, iconScale: 1.0, gapScale: 1.0),
  spacious('spacious', 'Amplia', coverFraction: 0.90, iconScale: 1.12, gapScale: 1.35);

  const PlayerDensity(
    this.id,
    this.label, {
    required this.coverFraction,
    required this.iconScale,
    required this.gapScale,
  });

  final String id;
  final String label;

  /// Fraccion del ancho disponible que ocupa la portada.
  final double coverFraction;

  /// Multiplicador del tamaño de los iconos de control.
  final double iconScale;

  /// Multiplicador de las separaciones verticales del bloque inferior.
  final double gapScale;

  static PlayerDensity byId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => normal);

  /// Separacion vertical ya escalada, redondeada para no producir medias
  /// unidades logicas que dejarian bordes borrosos.
  double gap(double base) => (base * gapScale).roundToDouble();
}
