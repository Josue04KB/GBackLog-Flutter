import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/core/router/app_router.dart';
import 'package:gamebacklog_cloud/domain/models/game_models.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/domain/use_cases/registrar_sesion_use_case.dart';
import 'package:gamebacklog_cloud/presentation/auth/auth_view_model.dart';
import 'package:gamebacklog_cloud/presentation/catalog/catalog_view_model.dart';
import 'package:gamebacklog_cloud/presentation/sessions/session_view_model.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Repository implements GameRepository {
  bool loggedIn = true;
  int collectionLoads = 0;
  int inserts = 0;
  final games = [
    Videojuego(
      id: 1,
      titulo: 'Hades II',
      genero: 'Acción',
      estado: 'En progreso',
      plataforma: 'PC',
      imagenUrl: 'https://example.invalid/hades.png',
    ),
    Videojuego(
      id: 2,
      titulo: 'Pokémon Émeraude',
      genero: 'RPG',
      estado: 'Pendiente',
      plataforma: 'PC',
      imagenUrl: 'https://example.invalid/pokemon.png',
    ),
    Videojuego(
      id: 3,
      titulo: 'Cyberpunk 2077',
      genero: 'RPG',
      estado: 'Completado',
      plataforma: 'PC',
      imagenUrl: 'https://example.invalid/cyberpunk.png',
    ),
  ];

  @override
  bool get hasValidSession => loggedIn;
  @override
  String? get currentUserEmail => 'jugador@example.com';
  @override
  String? get currentUserAvatarUrl => null;
  @override
  Future<void> signOut() async => loggedIn = false;
  @override
  Future<List<Videojuego>> getVideojuegos() async {
    collectionLoads++;
    return List.of(games);
  }

  @override
  Future<List<Plataforma>> getPlataformas() async => [
    Plataforma(
      id: 1,
      nombre: 'PC',
      fabricante: 'PC',
      formatoDefault: 'Digital',
    ),
  ];
  @override
  Future<List<SesionJuego>> getSesiones({int? videojuegoId}) async => [];
  @override
  Future<List<JuegoCatalogo>> getCatalogoGlobal() async => [
    const JuegoCatalogo(
      titulo: 'Ori',
      genero: 'Aventura',
      desarrollador: 'Moon Studios',
      lanzamiento: '2020',
      imagenUrl: 'https://example.invalid/ori.png',
      descripcion: 'Una aventura de plataformas.',
    ),
  ];
  @override
  Future<void> crearVideojuego({
    required String titulo,
    required String genero,
    required String estado,
    required String plataforma,
    String? imagenUrl,
  }) async {
    inserts++;
    games.add(
      Videojuego(
        id: 4,
        titulo: titulo,
        genero: genero,
        estado: estado,
        plataforma: plataforma,
        imagenUrl: imagenUrl,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _previewKey = GlobalKey();

Future<void> _preview(WidgetTester tester, String name) async {
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

Future<({GoRouter router, AuthViewModel auth})> _start(
  WidgetTester tester,
  _Repository repo, {
  Brightness brightness = Brightness.dark,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthViewModel(repo);
  final catalog = CatalogViewModel(repo);
  final settings = SettingsViewModel(repo);
  final sessions = SessionViewModel(repo, RegistrarSesionUseCase(repo));
  settings.toggleTheme(brightness == Brightness.dark);
  final router = AppRouter.createRouter(auth);
  addTearDown(() {
    router.dispose();
    auth.dispose();
    catalog.dispose();
    settings.dispose();
    sessions.dispose();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: sessions),
      ],
      child: RepaintBoundary(
        key: _previewKey,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: brightness,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, auth: auth);
}

Finder _tab(int index) => find.byKey(ValueKey('nav-$index'));
Finder get _search => find.byKey(const ValueKey('collection-search'));

void main() {
  setUpAll(() async {
    final fonts = Platform.environment['SESSION_PREVIEW_FONT_DIR'];
    if (fonts == null) return;
    await (FontLoader('Roboto')..addFont(
          File('$fonts/roboto-regular.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('MaterialIcons')..addFont(
          File('$fonts/materialicons-regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });

  testWidgets(
    'busca por nombre sin distinguir mayúsculas ni acentos y combina el filtro',
    (tester) async {
      await _start(tester, _Repository());
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Configuración'), findsNothing);
      await tester.tap(find.byTooltip('Buscar en mi colección'));
      await tester.pumpAndSettle();
      await tester.enterText(_search, '  POKEMON emeraude  ');
      await tester.pumpAndSettle();
      expect(find.text('Pokémon Émeraude'), findsOneWidget);
      expect(find.text('Hades II'), findsNothing);
      await tester.tap(find.text('En progreso'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hay juegos que coincidan con tu búsqueda y filtro.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Hades II'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar búsqueda'));
      await tester.pumpAndSettle();
      expect(_search, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'las pestañas conservan búsqueda y filtro; atrás vuelve al Backlog',
    (tester) async {
      final repo = _Repository();
      final app = await _start(tester, repo);
      await tester.tap(find.byTooltip('Buscar en mi colección'));
      await tester.pumpAndSettle();
      await tester.enterText(_search, 'Hades');
      await tester.tap(find.text('En progreso').first);
      await tester.tap(_tab(1));
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/agregar_catalogo',
      );
      expect(find.text('Explorar Catálogo'), findsOneWidget);
      expect(find.text('Ori'), findsOneWidget);
      await tester.tap(_tab(2));
      await tester.pumpAndSettle();
      expect(find.text('Perfil de Usuario'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(app.router.routeInformationProvider.value.uri.path, '/catalogo');
      expect(tester.widget<TextField>(_search).controller!.text, 'Hades');
      expect(find.text('Hades II'), findsOneWidget);
      expect(find.text('Pokémon Émeraude'), findsNothing);
      expect(repo.collectionLoads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Explorar permite agregar un juego y regresa a la biblioteca', (
    tester,
  ) async {
    final repo = _Repository();
    final app = await _start(tester, repo);
    await tester.tap(_tab(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ori'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agregar al Backlog'));
    await tester.tap(find.text('Agregar al Backlog'));
    await tester.pumpAndSettle();
    expect(repo.inserts, 1);
    expect(app.router.routeInformationProvider.value.uri.path, '/catalogo');
    expect(find.text('Ori'), findsOneWidget);
    expect(find.text('4 juegos en tu colección'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'abrir un juego desde la búsqueda y volver conserva el resultado',
    (tester) async {
      final app = await _start(tester, _Repository());
      await tester.tap(find.byTooltip('Buscar en mi colección'));
      await tester.pumpAndSettle();
      await tester.enterText(_search, 'Hades');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hades II'));
      await tester.pumpAndSettle();
      expect(app.router.canPop(), isTrue);
      expect(find.text('Registrar sesión'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_search).controller!.text, 'Hades');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cerrar sesión quita la navegación y protege las tres rutas', (
    tester,
  ) async {
    final app = await _start(tester, _Repository());
    await tester.tap(_tab(2));
    await tester.pumpAndSettle();
    await app.auth.signOut();
    await tester.pumpAndSettle();
    expect(app.router.routeInformationProvider.value.uri.path, '/login');
    expect(_tab(0), findsNothing);
    for (final route in ['/catalogo', '/config', '/agregar_catalogo']) {
      app.router.go(route);
      await tester.pumpAndSettle();
      expect(app.router.routeInformationProvider.value.uri.path, '/login');
    }
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'barra inferior y búsqueda se adaptan a pantalla pequeña ${brightness.name}',
      (tester) async {
        await _start(
          tester,
          _Repository(),
          brightness: brightness,
          size: const Size(360, 800),
        );
        await _preview(tester, 'backlog-${brightness.name}');
        expect(_tab(0).hitTestable(), findsOneWidget);
        expect(_tab(1).hitTestable(), findsOneWidget);
        expect(_tab(2).hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Buscar en mi colección'));
        await tester.pumpAndSettle();
        await tester.enterText(_search, 'Hades');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(_search.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
