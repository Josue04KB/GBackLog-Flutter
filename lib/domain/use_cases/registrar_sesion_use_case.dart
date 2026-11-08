import '../repositories/game_repository.dart';

class RegistrarSesionUseCase {
  final GameRepository _repository;

  RegistrarSesionUseCase(this._repository);

  Future<void> execute({
    required int? videojuegoId,
    required int? plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    // Regla 1: Obligatoriedad de relación con ambas entidades maestras
    if (videojuegoId == null || plataformaId == null) {
      throw Exception('Debes seleccionar un videojuego y una plataforma.');
    }

    // Regla 2: Validación de rango lógico de tiempo (1 min a 24 horas)
    if (minutosJugados <= 0 || minutosJugados > 1440) {
      throw Exception('El tiempo jugado debe estar entre 1 y 1440 minutos.');
    }

    // Regla 3: Validación de contenido mínimo en notas de partida
    final notasLimpias = notas.trim();
    if (notasLimpias.length < 5) {
      throw Exception('Las notas deben tener al menos 5 caracteres.');
    }

    // Si pasa todas las reglas de dominio, se envía al repositorio
    await _repository.registrarSesion(
      videojuegoId: videojuegoId,
      plataformaId: plataformaId,
      minutosJugados: minutosJugados,
      notas: notasLimpias,
    );
  }
}