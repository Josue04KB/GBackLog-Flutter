/// Reglas comunes al registrar y editar una sesión.
void validarSesion({
  required int? plataformaId,
  required int minutosJugados,
  required String notas,
}) {
  if (plataformaId == null) {
    throw Exception('Debes seleccionar una plataforma.');
  }
  if (minutosJugados <= 0 || minutosJugados > 1440) {
    throw Exception('El tiempo jugado debe estar entre 1 y 1440 minutos.');
  }
  if (notas.trim().length < 5) {
    throw Exception('Las notas deben tener al menos 5 caracteres.');
  }
}
