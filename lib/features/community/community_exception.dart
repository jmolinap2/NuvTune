/// Error legible para la persona; la pantalla lo muestra tal cual.
class CommunityException implements Exception {
  const CommunityException(this.message);
  final String message;

  @override
  String toString() => message;
}
