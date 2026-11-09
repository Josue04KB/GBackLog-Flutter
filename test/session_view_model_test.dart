import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/models/game_models.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/domain/use_cases/registrar_sesion_use_case.dart';
import 'package:gamebacklog_cloud/presentation/sessions/session_view_model.dart';
import 'package:gamebacklog_cloud/presentation/widgets/ui_state.dart';

class _SessionRepository implements GameRepository {
  _SessionRepository({this.sesiones = const []});

  List<SesionJuego> sesiones;
  int getSesionesCalls = 0;
  int? videojuegoIdRegistrado;
  int? plataformaIdRegistrada;

  @override
  Future<List<SesionJuego>> getSesiones({int? videojuegoId}) async {
    getSesionesCalls++;
    return sesiones;
  }

  @override
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    videojuegoIdRegistrado = videojuegoId;
    plataformaIdRegistrada = plataformaId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SesionJuego _sesionDePrueba() {
  return SesionJuego(
    id: 1,
    videojuegoId: 7,
    plataformaId: 3,
    minutosJugados: 90,
    notas: 'Prueba de sesión',
    fecha: DateTime(2026, 1, 1),
  );
}

void main() {
  group('SessionViewModel', () {
    test(
      'muestra el estado vacío cuando el repositorio no devuelve sesiones',
      () async {
        final repository = _SessionRepository();
        final viewModel = SessionViewModel(
          repository,
          RegistrarSesionUseCase(repository),
        );

        await viewModel.cargarSesiones(videojuegoId: 7);

        expect(viewModel.state, ViewState.empty);
        expect(viewModel.sesiones, isEmpty);
      },
    );

    test(
      'registra y vuelve a cargar las sesiones desde el repositorio',
      () async {
        final repository = _SessionRepository(sesiones: [_sesionDePrueba()]);
        final viewModel = SessionViewModel(
          repository,
          RegistrarSesionUseCase(repository),
        );

        final result = await viewModel.registrarNuevaSesion(
          videojuegoId: 7,
          plataformaId: 3,
          minutosJugados: 90,
          notas: 'Terminé la misión principal',
          filtroVideojuegoIdActual: 7,
        );

        expect(result, isTrue);
        expect(repository.videojuegoIdRegistrado, 7);
        expect(repository.plataformaIdRegistrada, 3);
        expect(repository.getSesionesCalls, 1);
        expect(viewModel.state, ViewState.success);
        expect(viewModel.sesiones, hasLength(1));
      },
    );
  });
}
