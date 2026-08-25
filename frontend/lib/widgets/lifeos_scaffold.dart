import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LifeOsScaffold extends StatelessWidget {
  const LifeOsScaffold({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  int get _index {
    if (location.startsWith('/ai')) return 1;
    if (location.startsWith('/modules')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/ai');
            case 2:
              context.go('/modules/habits');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Modules'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

