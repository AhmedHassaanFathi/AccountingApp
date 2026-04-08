import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/delegates/presentation/delegates_screen.dart';
import '../../features/transactions/presentation/delegate_transactions_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../presentation/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userProfile = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = userProfile.isLoading;
      final user = userProfile.value;
      
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (isLoading) return null; // Let it show splash/loading

      if (user == null && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      if (user != null && (isLoggingIn || isRegistering)) {
        if (user.role == 'employee') {
          return '/delegates';
        }
        return '/'; // Go to dashboard
      }

      // All users have full access to the application routes

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delegates',
                builder: (context, state) => const DelegatesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => DelegateTransactionsScreen(
                      delegateId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
