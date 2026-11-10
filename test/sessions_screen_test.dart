import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/models/game_models.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/domain/use_cases/registrar_sesion_use_case.dart';
import 'package:gamebacklog_cloud/presentation/catalog/catalog_view_model.dart';
import 'package:gamebacklog_cloud/presentation/sessions/session_view_model.dart';
import 'package:gamebacklog_cloud/presentation/sessions/new_session_sheet.dart';
import 'package:gamebacklog_cloud/presentation/sessions/sessions_screen.dart';
import 'package:provider/provider.dart';

final _previewKey = GlobalKey();

Future<void> _capturePreview(WidgetTester tester, String name) async {
  final output = Platform.environment['SESSION_PREVIEW_DIR'];
  if (output == null) return;
  await tester.runAsync(() async {
    final boundary =
        _previewKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

class _SessionRepository implements GameRepository {
  final sesiones = <SesionJuego>[];
  int insertCalls = 0;
  int? lastFilter;
  bool failInsert = false;
  Completer<void>? pendingInsert;
  int updateCalls = 0;
  int deleteCalls = 0;
  bool failUpdate = false;
  bool failDelete = false;
  Completer<void>? pendingUpdate;
  Completer<void>? pendingDelete;
  String gamePlatform = 'PC';
  int gameUpdateCalls = 0;
  bool failGameUpdate = false;

  @override
  Future<void> actualizarVideojuego({
    required int id,
    required String titulo,
    required String estado,
    required String plataforma,
    required String imagenUrl,
  }) async {
    gameUpdateCalls++;
    if (failGameUpdate) throw Exception('No se pudo actualizar el juego.');
    gamePlatform = plataforma;
  }

  @override
  Future<SesionJuego> actualizarSesion({
    required int id,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    updateCalls++;
    if (pendingUpdate != null) await pendingUpdate!.future;
    if (failUpdate) {
      throw Exception('No tienes permiso para editar esta sesión.');
    }
    final index = sesiones.indexWhere((s) => s.id == id);
    final original = sesiones[index];
    return sesiones[index] = SesionJuego(
      id: original.id,
      videojuegoId: original.videojuegoId,
      plataformaId: plataformaId,
      minutosJugados: minutosJugados,
      notas: notas,
      fecha: original.fecha,
    );
  }

  @override
  Future<void> eliminarSesion(int id) async {
    deleteCalls++;
    if (pendingDelete != null) await pendingDelete!.future;
    if (failDelete) throw Exception('Sin conexión. No se pudo eliminar.');
    sesiones.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<Videojuego>> getVideojuegos() async => [
    Videojuego(
      id: 7,
      titulo: 'Hades II',
      genero: 'Acción',
      estado: 'En progreso',
      plataforma: gamePlatform,
      imagenUrl: 'missing-test-cover.png',
    ),
  ];

  @override
  Future<List<Plataforma>> getPlataformas() async => [
    Plataforma(
      id: 3,
      nombre: 'PC',
      fabricante: 'PC',
      formatoDefault: 'Digital',
    ),
    Plataforma(
      id: 4,
      nombre: 'Switch',
      fabricante: 'Nintendo',
      formatoDefault: 'Digital',
    ),
  ];

  @override
  Future<List<SesionJuego>> getSesiones({int? videojuegoId}) async {
    lastFilter = videojuegoId;
    return List.of(sesiones);
  }

  @override
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    insertCalls++;
    if (pendingInsert != null) await pendingInsert!.future;
    if (failInsert) throw Exception('Sin conexión. Inténtalo de nuevo.');
    sesiones.add(
      SesionJuego(
        id: insertCalls,
        videojuegoId: videojuegoId,
        plataformaId: plataformaId,
        minutosJugados: minutosJugados,
        notas: notas,
        fecha: DateTime(2026, 11, 9),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openForm(
  WidgetTester tester,
  _SessionRepository repository, {
  Brightness brightness = Brightness.dark,
  Size size = const Size(430, 932),
  bool openForm = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final catalog = CatalogViewModel(repository);
  final sessions = SessionViewModel(
    repository,
    RegistrarSesionUseCase(repository),
  );
  await catalog.cargarMaestros();
  addTearDown(catalog.dispose);
  addTearDown(sessions.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: sessions),
      ],
      child: RepaintBoundary(
        key: _previewKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: brightness,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: const SessionsScreen(
            filtroVideojuegoId: 7,
            videojuegoTitulo: 'Hades II',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (openForm) {
    await tester.tap(find.text('Registrar sesión'));
    await tester.pumpAndSettle();
  }
}

_SessionRepository _withSession() => _SessionRepository()
  ..sesiones.add(
    SesionJuego(
      id: 17,
      videojuegoId: 7,
      plataformaId: 3,
      minutosJugados: 60,
      notas: 'Primera partida',
      fecha: DateTime(2026, 11, 9, 19, 27),
    ),
  );

Future<void> _chooseSessionAction(WidgetTester tester, String action) async {
  await tester.longPress(find.byKey(const ValueKey('sesion-17')));
  await tester.pumpAndSettle();
  expect(find.text('Editar'), findsOneWidget);
  expect(find.text('Eliminar'), findsOneWidget);
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Minutos jugados'),
    '62',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Notas o progreso logrado'),
    '  Superé el primer jefe  ',
  );
}

Future<void> _editGame(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editar juego'));
  await tester.pumpAndSettle();
}

Future<void> _selectGamePlatform(WidgetTester tester, String name) async {
  final platform = find.byKey(const ValueKey('plataforma-juego'));
  await tester.ensureVisible(platform);
  await tester.tap(platform);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Finder get _save => find.ancestor(
  of: find.textContaining(RegExp(r'^Guardar')),
  matching: find.byType(ElevatedButton),
);

void main() {
  setUpAll(() async {
    final fonts = Platform.environment['SESSION_PREVIEW_FONT_DIR'];
    if (fonts != null) {
      final loader = FontLoader('Roboto')
        ..addFont(
          File('$fonts/roboto-regular.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('$fonts/materialicons-regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await icons.load();
    }
  });

  testWidgets(
    'pulsación prolongada permite editar sin cambiar id, juego ni fecha',
    (tester) async {
      final repository = _withSession();
      final original = repository.sesiones.single;
      await _openForm(tester, repository, openForm: false);
      await _chooseSessionAction(tester, 'Editar');
      expect(find.text('Editar sesión'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('Primera partida'), findsWidgets);
      expect(find.text('Plataforma'), findsNothing);
      await _fillForm(tester);
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      final updated = repository.sesiones.single;
      expect(updated.id, original.id);
      expect(updated.videojuegoId, original.videojuegoId);
      expect(updated.fecha, original.fecha);
      expect(updated.plataformaId, original.plataformaId);
      expect(updated.minutosJugados, 62);
      expect(updated.notas, 'Superé el primer jefe');
      expect(repository.insertCalls, 0);
      expect(repository.updateCalls, 1);
      expect(find.text('1h 2m'), findsOneWidget);
      expect(find.text('62 minutos jugados'), findsOneWidget);
      expect(find.text('Sesión actualizada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editar plataforma del juego actualiza la ficha y las nuevas sesiones, no el historial',
    (tester) async {
      final repository = _withSession();
      await _openForm(tester, repository, openForm: false);
      await _editGame(tester);
      final platform = find.byKey(const ValueKey('plataforma-juego'));
      await tester.ensureVisible(platform);
      final status = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Estado en tu colección',
      );
      expect(
        tester.getTopLeft(platform).dy,
        greaterThan(tester.getTopLeft(status).dy),
      );
      await _capturePreview(tester, 'edit-game-platform');
      await _selectGamePlatform(tester, 'Switch');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repository.gamePlatform, 'Switch');
      expect(repository.gameUpdateCalls, 1);
      expect(find.text('Switch'), findsOneWidget);
      expect(repository.sesiones.single.plataformaId, 3);
      await tester.tap(find.text('Registrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Plataforma'), findsNothing);
      await _fillForm(tester);
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(repository.sesiones.last.plataformaId, 4);
      await _chooseSessionAction(tester, 'Editar');
      await _fillForm(tester);
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(repository.sesiones.first.plataformaId, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelar o fallar al cambiar plataforma conserva el juego y permite reintentar',
    (tester) async {
      final repository = _SessionRepository();
      await _openForm(tester, repository, openForm: false);
      await _editGame(tester);
      await _selectGamePlatform(tester, 'Switch');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.gameUpdateCalls, 0);
      expect(find.text('PC'), findsOneWidget);
      repository.failGameUpdate = true;
      await _editGame(tester);
      await _selectGamePlatform(tester, 'Switch');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(EditGameScreen), findsOneWidget);
      expect(repository.gamePlatform, 'PC');
      expect(find.text('No se pudo actualizar el juego.'), findsOneWidget);
      repository.failGameUpdate = false;
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repository.gamePlatform, 'Switch');
      expect(find.byType(EditGameScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'una plataforma no disponible obliga a elegirla en Editar juego',
    (tester) async {
      final repository = _SessionRepository()
        ..gamePlatform = 'Plataforma eliminada';
      await _openForm(tester, repository);
      expect(find.byType(NewSessionSheet), findsNothing);
      expect(
        find.text(
          'Selecciona una plataforma disponible en Editar juego antes de registrar una sesión.',
        ),
        findsOneWidget,
      );
      expect(repository.insertCalls, 0);
      await _editGame(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repository.gameUpdateCalls, 0);
      await _selectGamePlatform(tester, 'Switch');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(NewSessionSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelar edición y borrado no modifica la sesión', (
    tester,
  ) async {
    final repository = _withSession();
    await _openForm(tester, repository, openForm: false);
    await _chooseSessionAction(tester, 'Editar');
    await _fillForm(tester);
    await tester.ensureVisible(find.text('Cancelar'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await _chooseSessionAction(tester, 'Eliminar');
    expect(find.text('¿Eliminar sesión?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.updateCalls, 0);
    expect(repository.deleteCalls, 0);
    expect(repository.sesiones.single.minutosJugados, 60);
    expect(find.text('60 minutos jugados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar conserva los cambios al fallar y bloquea doble envío', (
    tester,
  ) async {
    final repository = _withSession()..failUpdate = true;
    await _openForm(tester, repository, openForm: false);
    await _chooseSessionAction(tester, 'Editar');
    await _fillForm(tester);
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(
      find.text('No tienes permiso para editar esta sesión.'),
      findsOneWidget,
    );
    expect(find.text('  Superé el primer jefe  '), findsOneWidget);
    expect(repository.sesiones.single.minutosJugados, 60);
    final pending = Completer<void>();
    repository.failUpdate = false;
    repository.pendingUpdate = pending;
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.tap(_save);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(NewSessionSheet), findsOneWidget);
    expect(repository.updateCalls, 2);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('62 minutos jugados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'eliminar confirma, permite reintentar y actualiza el estado vacío',
    (tester) async {
      final repository = _withSession()..failDelete = true;
      await _openForm(tester, repository, openForm: false);
      await _chooseSessionAction(tester, 'Eliminar');
      expect(repository.deleteCalls, 0);
      await tester.tap(find.text('Eliminar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión. No se pudo eliminar.'), findsOneWidget);
      expect(repository.sesiones, hasLength(1));
      final pending = Completer<void>();
      repository.failDelete = false;
      repository.pendingDelete = pending;
      await tester.tap(find.text('Eliminar sesión'));
      await tester.tap(find.text('Eliminar sesión'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Eliminando…'), findsOneWidget);
      expect(repository.deleteCalls, 2);
      pending.complete();
      await tester.pumpAndSettle();
      expect(repository.sesiones, isEmpty);
      expect(
        find.text('Aún no has registrado sesiones para este juego.'),
        findsOneWidget,
      );
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Sesión eliminada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'eliminar una sesión mantiene las demás y descuenta solo sus minutos',
    (tester) async {
      final repository = _withSession()
        ..sesiones.add(
          SesionJuego(
            id: 18,
            videojuegoId: 7,
            plataformaId: 4,
            minutosJugados: 30,
            notas: 'Segunda partida',
            fecha: DateTime(2026, 11, 9),
          ),
        );
      await _openForm(tester, repository, openForm: false);
      expect(find.text('1h 30m'), findsOneWidget);
      await _chooseSessionAction(tester, 'Eliminar');
      await tester.tap(find.text('Eliminar sesión'));
      await tester.pumpAndSettle();
      expect(repository.sesiones.single.id, 18);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('30 minutos jugados'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guardar una sesión con notas enfocadas no rompe el cierre del formulario',
    (tester) async {
      final repository = _SessionRepository();
      await _openForm(tester, repository);
      await _fillForm(tester);
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repository.insertCalls, 1);
      expect(repository.sesiones.single.videojuegoId, 7);
      expect(repository.sesiones.single.plataformaId, 3);
      expect(repository.sesiones.single.minutosJugados, 62);
      expect(repository.sesiones.single.notas, 'Superé el primer jefe');
      expect(repository.lastFilter, 7);
      expect(find.text('62 minutos jugados'), findsOneWidget);
    },
  );

  testWidgets(
    'cancelar, cerrar y volver no liberan los campos durante la transición',
    (tester) async {
      final repository = _SessionRepository();
      await _openForm(tester, repository);
      for (final action in ['cancel', 'close', 'back']) {
        await _fillForm(tester);
        if (action == 'cancel') {
          await tester.ensureVisible(find.text('Cancelar'));
          await tester.tap(find.text('Cancelar'));
        } else if (action == 'close') {
          await tester.ensureVisible(find.byTooltip('Cerrar formulario'));
          await tester.tap(find.byTooltip('Cerrar formulario'));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(find.byType(NewSessionSheet), findsNothing);
        expect(repository.insertCalls, 0);
        if (action != 'back') {
          await tester.tap(find.text('Registrar sesión'));
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets('un fallo de red conserva el formulario y permite reintentar', (
    tester,
  ) async {
    final repository = _SessionRepository()..failInsert = true;
    await _openForm(tester, repository);
    await _fillForm(tester);
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.byType(NewSessionSheet), findsOneWidget);
    expect(find.text('Sin conexión. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.text('  Superé el primer jefe  '), findsOneWidget);
    expect(repository.sesiones, isEmpty);
    repository.failInsert = false;
    await tester.ensureVisible(_save);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repository.sesiones, hasLength(1));
    expect(find.byType(NewSessionSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'guardar bloquea doble envío y el botón atrás mientras espera la red',
    (tester) async {
      final pending = Completer<void>();
      final repository = _SessionRepository()..pendingInsert = pending;
      await _openForm(tester, repository);
      await _fillForm(tester);
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.tap(_save);
      await tester.pump();
      expect(find.text('Guardando sesión…'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NewSessionSheet), findsOneWidget);
      expect(repository.insertCalls, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(repository.sesiones, hasLength(1));
      expect(find.byType(NewSessionSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'valida los campos y usa la plataforma del juego con minutos rápidos',
    (tester) async {
      final repository = _SessionRepository()..gamePlatform = 'Switch';
      await _openForm(tester, repository);
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(repository.insertCalls, 0);
      expect(
        find.text('Ingresa un tiempo entre 1 y 1440 minutos.'),
        findsOneWidget,
      );
      expect(
        find.text('Describe tu avance con al menos 5 caracteres.'),
        findsOneWidget,
      );
      expect(find.text('Plataforma'), findsNothing);
      await tester.ensureVisible(find.text('30 min'));
      await tester.tap(find.text('30 min'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notas o progreso logrado'),
        'Segunda partida',
      );
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(repository.sesiones.single.minutosJugados, 30);
      expect(repository.sesiones.single.plataformaId, 4);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'formulario ${brightness.name} usable en un teléfono pequeño con teclado',
      (tester) async {
        final repository = _SessionRepository();
        await _openForm(
          tester,
          repository,
          brightness: brightness,
          size: const Size(360, 800),
        );
        await _capturePreview(tester, 'new-session-${brightness.name}');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await _fillForm(tester);
        await tester.ensureVisible(_save);
        await tester.pumpAndSettle();
        expect(_save.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(_save);
        await tester.pumpAndSettle();
        expect(repository.sesiones, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'el panel se puede desplazar en horizontal y con texto ampliado',
    (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(740, 360),
                textScaler: TextScaler.linear(1.5),
              ),
              child: NewSessionSheet(
                videojuegoTitulo:
                    'Un videojuego con un nombre especialmente largo',
                onSave: (_) async => 'Error de prueba',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(_save);
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Ingresa un tiempo entre 1 y 1440 minutos.'),
        findsOneWidget,
      );
    },
  );
}
