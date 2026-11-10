import '../models/game_models.dart';
import '../repositories/game_repository.dart';
import 'validar_sesion.dart';

class ActualizarSesionUseCase {
  final GameRepository _repository;

  ActualizarSesionUseCase(this._repository);

  Future<SesionJuego> execute({
    required int id,
    required int? plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    validarSesion(
      plataformaId: plataformaId,
      minutosJugados: minutosJugados,
      notas: notas,
    );
    return _repository.actualizarSesion(
      id: id,
      plataformaId: plataformaId!,
      minutosJugados: minutosJugados,
      notas: notas.trim(),
    );
  }
}
