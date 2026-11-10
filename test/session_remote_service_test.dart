import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/data/repositories/game_repository_impl.dart';
import 'package:gamebacklog_cloud/data/services/supabase_remote_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MemoryPkceStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

// El transporte usa el SDK real contra un servidor HTTP local de prueba.
// No inicia sesión ni accede al proyecto Supabase del usuario.
class _AuthenticatedRemote extends SupabaseRemoteService {
  _AuthenticatedRemote(SupabaseClient client) : super(client: client);
  bool authenticated = true;
  Map<String, dynamic> metadata = {};

  @override
  User? get currentUser => authenticated
      ? User(
          id: 'test-user',
          appMetadata: {},
          userMetadata: metadata,
          email: 'legacy@example.com',
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
      authOptions: AuthClientOptions(pkceAsyncStorage: _MemoryPkceStorage()),
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

  test('nombre de usuario lee metadata y mantiene compatibilidad con cuentas antiguas', () {
    expect(repository.currentUsername, 'legacy');
    remote.metadata = {'username': '  Josue_gamer  '};
    expect(repository.currentUsername, 'Josue_gamer');
    remote.authenticated = false;
    expect(repository.currentUsername, isNull);
  });

  test('registro envía username en metadata para el trigger y no escribe profiles desde el cliente', () async {
    responseBody = {
      'id': '11111111-1111-4111-8111-111111111111',
      'aud': 'authenticated',
      'email': 'josue@example.com',
      'app_metadata': {},
      'user_metadata': {'username': 'Josue_gamer'},
      'created_at': '2026-11-10T00:00:00Z',
    };
    await repository.signUp(
      email: ' josue@example.com ',
      password: ' password123 ',
      username: ' Josue_gamer ',
    );
    expect(requests.single.method, 'POST');
    expect(requests.single.uri.path, '/auth/v1/signup');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['email'], 'josue@example.com');
    expect(body['password'], ' password123 ');
    expect(body['data'], {'username': 'Josue_gamer'});
    expect(repository.hasValidSession, isFalse);
  });

  test('registro inválido no envía solicitudes', () async {
    await expectLater(
      repository.signUp(
        email: 'josue@example.com',
        password: 'password123',
        username: ' ',
      ),
      throwsA(isA<Exception>()),
    );
    expect(requests, isEmpty);
  });

  test(
    'login traduce el rechazo real del SDK sin exponer el servidor',
    () async {
      responseStatus = 400;
      responseBody = {
        'code': 'invalid_credentials',
        'msg': 'Invalid login credentials',
      };
      await expectLater(
        repository.signIn(email: 'test@example.com', password: 'secret'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            'El correo o la contraseña son incorrectos. Revisa tus datos.',
          ),
        ),
      );
    },
  );

  test(
    'fallo desconocido de base de datos no revela SQL ni detalles',
    () async {
      responseStatus = 400;
      responseBody = {
        'code': '42703',
        'message': 'column secret_schema.internal does not exist',
        'details': 'private record',
        'hint': 'SQL SELECT',
      };
      await expectLater(
        repository.getVideojuegos(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            'No pudimos cargar tu colección. Inténtalo de nuevo.',
          ),
        ),
      );
    },
  );

  for (final entity in ['juego', 'plataforma']) {
    test('eliminar $entity sin fila confirmada no anuncia éxito', () async {
      await expectLater(
        entity == 'juego'
            ? repository.eliminarVideojuego(7)
            : repository.eliminarPlataforma(4),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('no tienes permiso'),
          ),
        ),
      );
      expect(requests.single.uri.queryParameters['select'], 'id');
    });
  }

  test('rechazo del trigger no se presenta como registro exitoso', () async {
    responseStatus = 500;
    responseBody = {
      'code': 'unexpected_failure',
      'msg': 'Database error saving new user',
    };
    await expectLater(
      repository.signUp(
        email: 'josue@example.com',
        password: 'password123',
        username: 'Josue_gamer',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Prueba con otro nombre de usuario'),
        ),
      ),
    );
  });

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
          contains('No tienes permiso'),
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
