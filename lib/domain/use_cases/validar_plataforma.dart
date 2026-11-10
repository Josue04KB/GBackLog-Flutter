import '../../core/errors/app_exception.dart';

void validarPlataforma(String nombre, String fabricante, String formato) {
  for (final field in [
    (nombre, 'nombre'),
    (fabricante, 'fabricante'),
    (formato, 'formato'),
  ]) {
    final length = field.$1.trim().length;
    if (length < 2 || length > 80) {
      throw AppException('El ${field.$2} debe tener entre 2 y 80 caracteres.');
    }
  }
}
