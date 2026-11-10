import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/presentation/auth/auth_view_model.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_view_model.dart';
import 'package:gamebacklog_cloud/presentation/settings/user_profile_screen.dart';
import 'package:gamebacklog_cloud/presentation/settings/profile_action_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'support/test_fonts.dart';

class _ProfileRepository implements GameRepository {
  String name = 'Doran12';
  String email = 'doran@gmail.com';
  String? avatar;
  bool loggedIn = true;
  bool fail = false;
  int passwordCalls = 0;
  int deleteCalls = 0;
  int logoutCalls = 0;
  String? savedPassword;
  Completer<void>? pending;

  @override
  bool get hasValidSession => loggedIn;
  @override
  String? get currentUsername => name;
  @override
  String? get currentUserEmail => email;
  @override
  String? get currentUserAvatarUrl => avatar;

  @override
  Future<void> actualizarContrasena(String value) async {
    passwordCalls++;
    if (pending != null) await pending!.future;
    if (fail) throw const SocketException('offline');
    savedPassword = value;
  }

  @override
  Future<void> signOut() async {
    logoutCalls++;
    if (fail) throw const SocketException('offline');
    loggedIn = false;
  }

  @override
  Future<void> eliminarCuentaUsuario() async {
    deleteCalls++;
    if (pending != null) await pending!.future;
    if (fail) throw const SocketException('offline');
    loggedIn = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _preview = GlobalKey();

Future<GoRouter> _start(
  WidgetTester tester,
  _ProfileRepository repo, {
  bool dark = true,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = SettingsViewModel(repo)..toggleTheme(dark);
  final auth = AuthViewModel(repo);
  final router = GoRouter(
    initialLocation: '/perfil',
    refreshListenable: auth,
    redirect: (_, state) =>
        !auth.isAuthenticated && state.matchedLocation != '/login'
        ? '/login'
        : null,
    routes: [
      GoRoute(path: '/perfil', builder: (_, _) => const UserProfileScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Iniciar sesión')),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(settings.dispose);
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: RepaintBoundary(
        key: _preview,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _capture(WidgetTester tester, String name) async {
  final output = Platform.environment['PROFILE_PREVIEW_DIR'];
  if (output == null) return;
  await tester.runAsync(() async {
    final boundary =
        _preview.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);

  for (final dark in [true, false]) {
    testWidgets(
      'perfil ${dark ? "oscuro" : "claro"} se adapta a pantalla pequeña y texto grande',
      (tester) async {
        final repo = _ProfileRepository();
        await _start(tester, repo, dark: dark);
        await _capture(tester, dark ? 'profile-dark' : 'profile-light');
        expect(find.text('Doran12'), findsOneWidget);
        expect(find.text('doran@gmail.com'), findsOneWidget);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.physicalSize = const Size(320, 700);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Eliminar cuenta'), 200);
        expect(find.text('Eliminar cuenta').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'contraseña valida confirmación, conserva datos ante error y permite reintentar',
    (tester) async {
      final repo = _ProfileRepository()..fail = true;
      await _start(tester, repo);
      await _tap(tester, 'Cambiar contraseña');
      await _capture(tester, 'password-dialog');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'NuevaClave123!');
      await tester.enterText(fields.at(1), 'OtraClave123!');
      await _tap(tester, 'Guardar contraseña');
      expect(repo.passwordCalls, 0);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      await tester.enterText(fields.at(1), 'NuevaClave123!');
      await _tap(tester, 'Guardar contraseña');
      expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'NuevaClave123!',
      );
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: fields.at(0),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isFalse,
      );
      repo.fail = false;
      await _tap(tester, 'Guardar contraseña');
      expect(repo.savedPassword, 'NuevaClave123!');
      expect(find.byType(ProfileActionDialog), findsNothing);
      expect(find.text('Contraseña actualizada con éxito'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'formulario con teclado bloquea doble envío y cierre durante guardado',
    (tester) async {
      final repo = _ProfileRepository()..pending = Completer<void>();
      await _start(tester, repo, size: const Size(360, 800));
      await _tap(tester, 'Cambiar contraseña');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'NuevaClave123!');
      await tester.enterText(fields.at(1), 'NuevaClave123!');
      final save = find.text('Guardar contraseña');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.passwordCalls, 1);
      expect(find.byType(ProfileActionDialog), findsOneWidget);
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileActionDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cerrar sesión requiere confirmar y permite reintentar si falla',
    (tester) async {
      final repo = _ProfileRepository()..fail = true;
      final router = await _start(tester, repo);
      await _tap(tester, 'Cerrar sesión');
      await _tap(tester, 'Cancelar');
      expect(repo.logoutCalls, 0);
      await _tap(tester, 'Cerrar sesión');
      await _tap(tester, 'Sí, salir');
      expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/perfil');
      repo.fail = false;
      await _tap(tester, 'Sí, salir');
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('eliminar cuenta muestra advertencia y no navega si falla', (
    tester,
  ) async {
    final repo = _ProfileRepository()..fail = true;
    final router = await _start(tester, repo);
    await _tap(tester, 'Eliminar cuenta');
    expect(
      find.textContaining('Esta acción no se puede deshacer.'),
      findsOneWidget,
    );
    await _tap(tester, 'Cancelar');
    expect(repo.deleteCalls, 0);
    await _tap(tester, 'Eliminar cuenta');
    await _tap(tester, 'Sí, eliminar cuenta');
    expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/perfil');
    repo.fail = false;
    await _tap(tester, 'Sí, eliminar cuenta');
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(tester.takeException(), isNull);
  });
}
