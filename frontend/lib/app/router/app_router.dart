import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/life_module.dart';
import '../../features/ai/lifeos_ai_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/modules/module_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../widgets/lifeos_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => const MaterialPage(child: AuthScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => LifeOsScaffold(
        location: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const MaterialPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/ai',
          pageBuilder: (context, state) => const MaterialPage(child: LifeOsAiScreen()),
        ),
        GoRoute(
          path: '/modules/:module',
          pageBuilder: (context, state) {
            final moduleKey = state.pathParameters['module'] ?? 'habits';
            final module = lifeModules.firstWhere(
              (item) => item.route.endsWith('/$moduleKey'),
              orElse: () => lifeModules.first,
            );
            return MaterialPage(child: ModuleScreen(module: module));
          },
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const MaterialPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);

