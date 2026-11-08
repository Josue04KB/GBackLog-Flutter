import 'package:gamebacklog_cloud/presentation/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/auth_screen.dart';
import '../../presentation/auth/auth_view_model.dart';
import '../../presentation/catalog/catalog_screen.dart';
import '../../presentation/sessions/sessions_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/catalogo',
      // IMPORTANTE: Solo escucha la autenticación para proteger las rutas privadas
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isLoggedIn = authViewModel.isAuthenticated;
        final location = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/registro';

        // Si NO ha iniciado sesión y quiere entrar a pantallas privadas -> redirige a /login
        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }
        // Si YA inició sesión y está en login/registro -> redirige al catálogo
        if (isLoggedIn && isAuthRoute) {
          return '/catalogo';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(isRegister: false),
        ),
        GoRoute(
          path: '/registro',
          builder: (context, state) => const AuthScreen(isRegister: true),
        ),
        GoRoute(
          path: '/catalogo',
          builder: (context, state) => const CatalogScreen(),
        ),
        GoRoute(
          path: '/config', 
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/sesiones',
          builder: (context, state) {
            // Paso de parámetros por URL con go_router
            final juegoIdStr = state.uri.queryParameters['juegoId'];
            final titulo = state.uri.queryParameters['titulo'];
            final juegoId = juegoIdStr != null ? int.tryParse(juegoIdStr) : null;

            return SessionsScreen(
              filtroVideojuegoId: juegoId,
              videojuegoTitulo: titulo,
            );
          },
        ),
      ],
    );
  }
}