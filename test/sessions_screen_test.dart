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

  @override
  Future<List<Videojuego>> getVideojuegos() async => [
    Videojuego(
      id: 7,
      titulo: 'Hades II',
      genero: 'Acción',
      estado: 'En progreso',
      plataforma: 'PC',
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
  await tester.tap(find.text('Registrar sesión'));
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
    'valida los campos y permite elegir minutos rápidos y plataforma',
    (tester) async {
      final repository = _SessionRepository();
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
      final platform = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(platform);
      await tester.tap(platform);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch').last);
      await tester.pumpAndSettle();
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
                plataformas: await _SessionRepository().getPlataformas(),
                plataformaInicialId: 3,
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
