import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/data/repositories/game_repository_impl.dart';
import 'package:gamebacklog_cloud/data/services/supabase_remote_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// El transporte usa el SDK real contra un servidor HTTP local de prueba.
// No inicia sesión ni accede al proyecto Supabase del usuario.
class _AuthenticatedRemote extends SupabaseRemoteService {
  _AuthenticatedRemote(SupabaseClient client) : super(client: client);
  bool authenticated = true;

  @override
  User? get currentUser => authenticated
      ? const User(
          id: 'test-user',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-11-09T00:00:00Z',
        )
      : null;
}

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late _AuthenticatedRemote remote;
  late GameRepositoryImpl repository;
  late Object responseBody;
  late int responseStatus;
  late List<({String method, Uri uri, String body})> requests;

  setUp(() async {
    requests = [];
    responseStatus = 200;
    responseBody = <Object>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add((method: request.method, uri: request.uri, body: body));
      request.response.statusCode = responseStatus;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(responseBody));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'local-test-key',
    );
    remote = _AuthenticatedRemote(client);
    repository = GameRepositoryImpl(remote);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  Future<void> edit() async {
    await repository.actualizarSesion(
      id: 17,
      plataformaId: 4,
      minutosJugados: 45,
      notas: '  Avance editado  ',
    );
  }

  test(
    'editar juego persiste la plataforma en videojuegos sin modificar sesiones',
    () async {
      responseBody = [
        {'id': 7},
      ];
      await repository.actualizarVideojuego(
        id: 7,
        titulo: 'Hades II',
        estado: 'En progreso',
        plataforma: 'Switch',
        imagenUrl: '',
      );
      final request = requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/rest/v1/videojuegos');
      expect(request.uri.queryParameters['id'], 'eq.7');
      expect(jsonDecode(request.body), {
        'titulo': 'Hades II',
        'estado': 'En progreso',
        'plataforma': 'Switch',
        'imagen_url': null,
      });
    },
  );

  test('editar juego sin una fila confirmada no anuncia éxito', () async {
    await expectLater(
      repository.actualizarVideojuego(
        id: 7,
        titulo: 'Hades II',
        estado: 'En progreso',
        plataforma: 'Switch',
        imagenUrl: '',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('no tienes permiso'),
        ),
      ),
    );
  });

  test(
    'PATCH filtra por id, devuelve datos guardados y conserva juego y fecha',
    () async {
      responseBody = [
        {
          'id': 17,
          'videojuego_id': 7,
          'plataforma_id': 4,
          'minutos_jugados': 45,
          'notas': 'Avance editado',
          'fecha': '2026-11-09T19:27:00Z',
          'videojuegos': {'titulo': 'Hades II'},
          'plataformas': {'nombre': 'Switch'},
        },
      ];
      final updated = await repository.actualizarSesion(
        id: 17,
        plataformaId: 4,
        minutosJugados: 45,
        notas: '  Avance editado  ',
      );
      final request = requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.path, '/rest/v1/sesiones_juego');
      expect(request.uri.queryParameters['id'], 'eq.17');
      expect(jsonDecode(request.body), {
        'plataforma_id': 4,
        'minutos_jugados': 45,
        'notas': 'Avance editado',
      });
      expect(updated.id, 17);
      expect(updated.videojuegoId, 7);
      expect(updated.fecha.toUtc(), DateTime.utc(2026, 11, 9, 19, 27));
      expect(updated.plataformaNombre, 'Switch');
    },
  );

  test(
    'DELETE solo elimina el id elegido y solicita confirmación del servidor',
    () async {
      responseBody = [
        {'id': 17},
      ];
      await repository.eliminarSesion(17);
      expect(requests.single.method, 'DELETE');
      expect(requests.single.uri.queryParameters['id'], 'eq.17');
      expect(requests.single.uri.queryParameters['select'], 'id');
    },
  );

  for (final action in ['editar', 'eliminar']) {
    test(
      '$action no anuncia éxito si RLS oculta la fila o ya no existe',
      () async {
        await expectLater(
          action == 'editar' ? edit() : repository.eliminarSesion(17),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'mensaje',
              contains('no tienes permiso'),
            ),
          ),
        );
        expect(requests, hasLength(1));
      },
    );
  }

  test('un rechazo de permisos es un error recuperable', () async {
    responseStatus = 403;
    responseBody = {
      'code': '42501',
      'message': 'permission denied',
      'details': null,
      'hint': null,
    };
    await expectLater(
      edit(),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Revisa los permisos'),
        ),
      ),
    );
  });

  test('sin usuario autenticado no envía operaciones', () async {
    remote.authenticated = false;
    await expectLater(edit(), throwsA(isA<Exception>()));
    await expectLater(repository.eliminarSesion(17), throwsA(isA<Exception>()));
    expect(requests, isEmpty);
  });
}
