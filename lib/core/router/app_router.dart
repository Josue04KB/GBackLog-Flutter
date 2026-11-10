import 'package:go_router/go_router.dart';

import '../../presentation/auth/auth_screen.dart';
import '../../presentation/auth/auth_view_model.dart';
import '../../presentation/catalog/add_game_catalog_screen.dart';
import '../../presentation/catalog/catalog_screen.dart';
import '../../presentation/sessions/sessions_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/settings/user_profile_screen.dart';
import '../../presentation/navigation/main_navigation_shell.dart';

class AppRouter {
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/catalogo',
      // Escucha únicamente los cambios de sesión (login / logout)
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isLoggedIn = authViewModel.isAuthenticated;
        final location = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/registro';

        // Si no está autenticado e intenta ir a rutas protegidas -> login
        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }
        // Si ya está autenticado e intenta ir a login/registro -> catálogo
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
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainNavigationShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/catalogo',
                  builder: (context, state) => const CatalogScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/agregar_catalogo',
                  builder: (context, state) => const AddGameCatalogScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/config',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const UserProfileScreen(),
        ),
        GoRoute(
          path: '/sesiones',
          builder: (context, state) {
            final juegoIdStr = state.uri.queryParameters['juegoId'];
            final titulo = state.uri.queryParameters['titulo'];
            final juegoId = juegoIdStr != null
                ? int.tryParse(juegoIdStr)
                : null;

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
