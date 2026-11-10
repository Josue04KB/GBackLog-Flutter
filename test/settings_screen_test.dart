import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/models/game_models.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/presentation/catalog/catalog_view_model.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_screen.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_view_model.dart';
import 'package:provider/provider.dart';
import 'package:gamebacklog_cloud/presentation/settings/platform_form_sheet.dart';

import 'support/test_fonts.dart';

class _SettingsRepository implements GameRepository {
  bool failSave = false;
  int updateCalls = 0;
  Completer<void>? pending;
  final List<Plataforma> plataformas = [
    Plataforma(
      id: 1,
      nombre: 'PC',
      fabricante: 'Personal',
      formatoDefault: 'Digital',
    ),
  ];

  @override
  String? get currentUserAvatarUrl => null;

  @override
  String? get currentUserEmail => 'jugador@example.com';
  @override
  String? get currentUsername => 'jugador';

  @override
  Future<List<Videojuego>> getVideojuegos() async => [];

  @override
  Future<List<Plataforma>> getPlataformas() async => List.of(plataformas);

  @override
  Future<void> crearPlataforma({
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    if (failSave) throw const SocketException('offline');
    plataformas.add(
      Plataforma(
        id: 2,
        nombre: nombre,
        fabricante: fabricante,
        formatoDefault: formato,
      ),
    );
  }

  @override
  Future<void> eliminarPlataforma(int id) async {
    plataformas.removeWhere((platform) => platform.id == id);
  }

  @override
  Future<Plataforma> actualizarPlataforma({
    required int id,
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    updateCalls++;
    if (pending != null) await pending!.future;
    if (failSave) throw const SocketException('offline');
    final index = plataformas.indexWhere((p) => p.id == id);
    return plataformas[index] = Plataforma(
      id: id,
      nombre: nombre,
      fabricante: fabricante,
      formatoDefault: formato,
      userId: plataformas[index].userId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadTestFonts);
  testWidgets('crea y elimina una plataforma después de cerrar el diálogo', (
    tester,
  ) async {
    final repository = _SettingsRepository();
    final catalogViewModel = CatalogViewModel(repository);
    await catalogViewModel.cargarMaestros();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SettingsViewModel(repository)),
          ChangeNotifierProvider.value(value: catalogViewModel),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Switch');
    await tester.enterText(fields.at(1), 'Nintendo');
    await tester.enterText(fields.at(2), 'Cartucho');
    await tester.tap(find.text('Guardar plataforma'));
    await tester.pumpAndSettle();

    expect(find.text('Switch'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Switch'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  Future<void> start(WidgetTester tester, _SettingsRepository repo) async {
    final catalog = CatalogViewModel(repo);
    final settings = SettingsViewModel(repo);
    await catalog.cargarMaestros();
    addTearDown(catalog.dispose);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catalog),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'lápiz izquierdo abre datos; cancelar no modifica la plataforma',
    (tester) async {
      final repo = _SettingsRepository();
      await start(tester, repo);
      final pencil = find.byTooltip('Editar PC');
      expect(
        tester.getCenter(pencil).dx,
        lessThan(tester.getCenter(find.text('PC')).dx),
      );
      await tester.tap(pencil);
      await tester.pumpAndSettle();
      expect(find.text('Editar plataforma'), findsOneWidget);
      final fields = find.byType(TextFormField);
      expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, 'PC');
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        'Personal',
      );
      expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text,
        'Digital',
      );
      await tester.enterText(fields.first, 'Computadora');
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.updateCalls, 0);
      expect(repo.plataformas.single.nombre, 'PC');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editar valida, conserva datos sin internet y actualiza la misma fila al reintentar',
    (tester) async {
      final repo = _SettingsRepository()..failSave = true;
      await start(tester, repo);
      await tester.tap(find.byTooltip('Editar PC'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      final save = find.byKey(const ValueKey('save-platform'));
      await tester.enterText(fields.first, ' ');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.updateCalls, 0);
      expect(find.text('Escribe entre 2 y 80 caracteres.'), findsOneWidget);
      await tester.enterText(fields.at(0), '  Mi PC  ');
      await tester.enterText(fields.at(1), '  Personalizado  ');
      await tester.enterText(fields.at(2), '  Físico / Digital  ');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Revisa tu conexión a internet'),
        findsOneWidget,
      );
      expect(repo.plataformas.single.nombre, 'PC');
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        '  Mi PC  ',
      );
      repo.failSave = false;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(PlatformFormSheet), findsNothing);
      expect(repo.plataformas.single.id, 1);
      expect(repo.plataformas.single.nombre, 'Mi PC');
      expect(repo.plataformas.single.fabricante, 'Personalizado');
      expect(repo.plataformas.single.formatoDefault, 'Físico / Digital');
      expect(find.text('Mi PC'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('guardar impide doble envío y cierre mientras espera', (
    tester,
  ) async {
    final pending = Completer<void>();
    final repo = _SettingsRepository()..pending = pending;
    await start(tester, repo);
    await tester.tap(find.byTooltip('Editar PC'));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('save-platform'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PlatformFormSheet), findsOneWidget);
    expect(repo.updateCalls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(PlatformFormSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('formulario ${brightness.name} con teclado y texto grande', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preview = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          home: RepaintBoundary(
            key: preview,
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: PlatformFormSheet(
                  onSave: (_) async =>
                      'No pudimos guardar. Inténtalo de nuevo.',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final output = Platform.environment['PLATFORM_PREVIEW_DIR'];
      if (output != null) {
        await tester.runAsync(() async {
          final boundary =
              preview.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/platform-${brightness.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Switch');
      await tester.enterText(fields.at(1), 'Nintendo');
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Digital'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Digital'));
      final save = find.byKey(const ValueKey('save-platform'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.text('No pudimos guardar. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
