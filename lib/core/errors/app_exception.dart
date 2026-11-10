/// Mensaje redactado por la app y seguro para mostrar al usuario.
/// Nunca debe construirse concatenando la respuesta cruda de una API.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}
