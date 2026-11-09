import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/domain/models/game_models.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/presentation/catalog/catalog_view_model.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_screen.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_view_model.dart';
import 'package:provider/provider.dart';

class _SettingsRepository implements GameRepository {
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
  Future<List<Videojuego>> getVideojuegos() async => [];

  @override
  Future<List<Plataforma>> getPlataformas() async => List.of(plataformas);

  @override
  Future<void> crearPlataforma({
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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
    await tester.tap(find.text('Guardar'));
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
}
