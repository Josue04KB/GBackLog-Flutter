import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'data/repositories/game_repository_impl.dart';
import 'data/services/supabase_remote_service.dart';
import 'domain/repositories/game_repository.dart';
import 'domain/use_cases/registrar_sesion_use_case.dart';
import 'presentation/auth/auth_view_model.dart';
import 'presentation/catalog/catalog_view_model.dart';
import 'presentation/sessions/session_view_model.dart';
import 'presentation/settings/settings_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase (Maneja y restaura el token JWT de forma segura)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Capa de Datos: Servicio Remoto y Repositorio (Contrato -> Impl)
        Provider<SupabaseRemoteService>(
          create: (_) => SupabaseRemoteService(),
        ),
        ProxyProvider<SupabaseRemoteService, GameRepository>(
          update: (_, service, _) => GameRepositoryImpl(service),
        ),

        // 2. Capa de Dominio: Caso de Uso
        ProxyProvider<GameRepository, RegistrarSesionUseCase>(
          update: (_, repo, _) => RegistrarSesionUseCase(repo),
        ),

        // 3. Capa de Presentación: ViewModels con ChangeNotifier
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<GameRepository>()),
        ),
        ChangeNotifierProvider<CatalogViewModel>(
          create: (ctx) => CatalogViewModel(ctx.read<GameRepository>()),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (ctx) => SettingsViewModel(ctx.read<GameRepository>()),
        ),
        ChangeNotifierProvider<SessionViewModel>(
          create: (ctx) => SessionViewModel(
            ctx.read<GameRepository>(),
            ctx.read<RegistrarSesionUseCase>(),
          ),
        ),
      ],
      child: const _AppRootView(),
    );
  }
}

class _AppRootView extends StatefulWidget {
  const _AppRootView();

  @override
  State<_AppRootView> createState() => _AppRootViewState();
}

class _AppRootViewState extends State<_AppRootView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Instanciamos el router UNA SOLA VEZ para que no se pierda la pila de navegación al cambiar el tema
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    _router = AppRouter.createRouter(authVm);
  }

  @override
  Widget build(BuildContext context) {
    // Escucha al SettingsViewModel para actualizar el tema visual al instante
    final settingsVm = context.watch<SettingsViewModel>();

    return MaterialApp.router(
      title: 'GameBacklog Cloud',
      debugShowCheckedModeBanner: false,
      themeMode: settingsVm.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: _router,
    );
  }
}