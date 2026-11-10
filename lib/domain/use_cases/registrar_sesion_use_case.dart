import '../../core/errors/app_exception.dart';
import '../repositories/game_repository.dart';
import 'validar_sesion.dart';

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
      throw AppException('Debes seleccionar un videojuego y una plataforma.');
    }

    validarSesion(
      plataformaId: plataformaId,
      minutosJugados: minutosJugados,
      notas: notas,
    );
    final notasLimpias = notas.trim();

    // Si pasa todas las reglas de dominio, se envía al repositorio
    await _repository.registrarSesion(
      videojuegoId: videojuegoId,
      plataformaId: plataformaId,
      minutosJugados: minutosJugados,
      notas: notasLimpias,
    );
  }
}
