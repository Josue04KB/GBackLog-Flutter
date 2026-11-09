import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/domain/use_cases/registrar_sesion_use_case.dart';

class _RecordingGameRepository implements GameRepository {
  int? videojuegoId;
  int? plataformaId;
  int? minutosJugados;
  String? notas;

  @override
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    this.videojuegoId = videojuegoId;
    this.plataformaId = plataformaId;
    this.minutosJugados = minutosJugados;
    this.notas = notas;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RegistrarSesionUseCase', () {
    late _RecordingGameRepository repository;
    late RegistrarSesionUseCase useCase;

    setUp(() {
      repository = _RecordingGameRepository();
      useCase = RegistrarSesionUseCase(repository);
    });

    test('registra una sesión válida y limpia las notas', () async {
      await useCase.execute(
        videojuegoId: 7,
        plataformaId: 3,
        minutosJugados: 90,
        notas: '  Derroté al jefe final  ',
      );

      expect(repository.videojuegoId, 7);
      expect(repository.plataformaId, 3);
      expect(repository.minutosJugados, 90);
      expect(repository.notas, 'Derroté al jefe final');
    });

    test('rechaza una sesión sin las dos entidades maestras', () async {
      await expectLater(
        useCase.execute(
          videojuegoId: null,
          plataformaId: 3,
          minutosJugados: 30,
          notas: 'Avancé mucho',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'mensaje',
            contains('videojuego y una plataforma'),
          ),
        ),
      );
    });

    test('rechaza duraciones fuera del rango permitido', () async {
      await expectLater(
        useCase.execute(
          videojuegoId: 7,
          plataformaId: 3,
          minutosJugados: 0,
          notas: 'Avancé mucho',
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        useCase.execute(
          videojuegoId: 7,
          plataformaId: 3,
          minutosJugados: 1441,
          notas: 'Avancé mucho',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rechaza notas demasiado cortas', () async {
      await expectLater(
        useCase.execute(
          videojuegoId: 7,
          plataformaId: 3,
          minutosJugados: 30,
          notas: 'abc',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'mensaje',
            contains('al menos 5 caracteres'),
          ),
        ),
      );
    });
  });
}
