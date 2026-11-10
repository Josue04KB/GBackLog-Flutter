import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/presentation/auth/auth_screen.dart';
import 'package:gamebacklog_cloud/presentation/auth/auth_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _RegistrationRepository implements GameRepository {
  bool authenticated = false;
  bool confirmEmail = false;
  bool fail = false;
  int calls = 0;
  String? sentUsername;
  String? sentEmail;
  String? sentPassword;
  Completer<void>? pending;

  @override
  bool get hasValidSession => authenticated;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    calls++;
    sentUsername = username;
    sentEmail = email;
    sentPassword = password;
    if (pending != null) await pending!.future;
    if (fail) {
      throw Exception(
        'No se pudo crear la cuenta. Prueba con otro nombre de usuario.',
      );
    }
    authenticated = !confirmEmail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _start(
  WidgetTester tester,
  _RegistrationRepository repo, {
  Size size = const Size(390, 844),
  bool register = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthViewModel(repo);
  final router = GoRouter(
    initialLocation: register ? '/registro' : '/login',
    routes: [
      GoRoute(
        path: '/registro',
        builder: (_, _) => const AuthScreen(isRegister: true),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const AuthScreen(isRegister: false),
      ),
      GoRoute(
        path: '/catalogo',
        builder: (_, _) => const Scaffold(body: Text('Mi biblioteca')),
      ),
    ],
  );
  addTearDown(() {
    router.dispose();
    auth.dispose();
  });
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp.router(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Finder get _username => find.byKey(const ValueKey('register-username'));
Finder get _register => find.widgetWithText(ElevatedButton, 'Registrarse');

Future<void> _fill(
  WidgetTester tester, {
  String username = '  Josue_gamer  ',
}) async {
  await tester.enterText(_username, username);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Correo electrónico'),
    '  josue@example.com  ',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    ' Password123! ',
  );
}

void main() {
  testWidgets(
    'registro exige usuario y valida formato antes de llamar al servidor',
    (tester) async {
      final repo = _RegistrationRepository();
      await _start(tester, repo);
      await tester.ensureVisible(_register);
      await tester.tap(_register);
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu nombre de usuario'), findsOneWidget);
      for (final invalid in ['ab', 'usuario con espacios', 'x' * 31]) {
        await _fill(tester, username: invalid);
        await tester.ensureVisible(_register);
        await tester.tap(_register);
        await tester.pumpAndSettle();
        expect(repo.calls, 0);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'envía usuario y correo limpios, conserva contraseña y entra con sesión',
    (tester) async {
      final repo = _RegistrationRepository();
      final router = await _start(tester, repo);
      await _fill(tester);
      await tester.ensureVisible(_register);
      await tester.tap(_register);
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(repo.sentUsername, 'Josue_gamer');
      expect(repo.sentEmail, 'josue@example.com');
      expect(repo.sentPassword, ' Password123! ');
      expect(router.routeInformationProvider.value.uri.path, '/catalogo');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sin sesión avisa que confirme su correo y abre el inicio de sesión',
    (tester) async {
      final repo = _RegistrationRepository()..confirmEmail = true;
      final router = await _start(tester, repo);
      await _fill(tester);
      await tester.ensureVisible(_register);
      await tester.tap(_register);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(
        find.text(
          'Revisa tu correo para confirmar tu cuenta. Después podrás iniciar sesión.',
        ),
        findsOneWidget,
      );
      expect(_username, findsNothing);
      expect(repo.authenticated, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fallo conserva los campos y permite cambiar el usuario para reintentar',
    (tester) async {
      final repo = _RegistrationRepository()..fail = true;
      await _start(tester, repo);
      await _fill(tester);
      await tester.ensureVisible(_register);
      await tester.tap(_register);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No se pudo crear la cuenta. Prueba con otro nombre de usuario.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(_username).controller!.text,
        '  Josue_gamer  ',
      );
      repo.fail = false;
      await tester.enterText(_username, 'Josue_gamer2');
      await tester.ensureVisible(_register);
      await tester.tap(_register);
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(repo.sentUsername, 'Josue_gamer2');
      expect(find.text('Mi biblioteca'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bloquea doble envío mientras el servidor crea la cuenta', (
    tester,
  ) async {
    final pending = Completer<void>();
    final repo = _RegistrationRepository()..pending = pending;
    await _start(tester, repo);
    await _fill(tester);
    await tester.ensureVisible(_register);
    await tester.tap(_register);
    await tester.tap(_register);
    await tester.pump();
    expect(repo.calls, 1);
    expect(tester.widget<TextFormField>(_username).enabled, isFalse);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Inicia sesión aquí'),
          )
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('inicio de sesión mantiene solo correo y contraseña', (
    tester,
  ) async {
    await _start(tester, _RegistrationRepository(), register: false);
    expect(_username, findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('registro usable en teléfono pequeño con teclado y errores', (
    tester,
  ) async {
    await _start(tester, _RegistrationRepository(), size: const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_register);
    await tester.tap(_register);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_username);
    expect(_username.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
