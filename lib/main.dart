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
        ChangeNotifierProvider<SessionViewModel>(
          create: (ctx) => SessionViewModel(
            ctx.read<GameRepository>(),
            ctx.read<RegistrarSesionUseCase>(),
          ),
        ),
      ],
      child: const _AppRouterHost(),
    );
  }
}

class _AppRouterHost extends StatefulWidget {
  const _AppRouterHost();

  @override
  State<_AppRouterHost> createState() => _AppRouterHostState();
}

class _AppRouterHostState extends State<_AppRouterHost> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authVm);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GameBacklog Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}