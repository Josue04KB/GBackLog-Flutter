import '../../core/errors/app_exception.dart';

/// Reglas comunes al registrar y editar una sesión.
void validarSesion({
  required int? plataformaId,
  required int minutosJugados,
  required String notas,
}) {
  if (plataformaId == null) {
    throw AppException('Debes seleccionar una plataforma.');
  }
  if (minutosJugados <= 0 || minutosJugados > 1440) {
    throw AppException('El tiempo jugado debe estar entre 1 y 1440 minutos.');
  }
  if (notas.trim().length < 5) {
    throw AppException('Las notas deben tener al menos 5 caracteres.');
  }
}
