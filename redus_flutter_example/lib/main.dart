import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/reactivity_screen.dart';
import 'screens/lifecycle_screen.dart';
import 'screens/di_screen.dart';
import 'screens/dashboard_screen.dart';
import 'stores/dashboard_store.dart';

void main() {
  // Register global dependencies
  register<DashboardStore>(DashboardStore());

  runApp(const RedusShowcaseApp());
}

class RedusShowcaseApp extends StatelessWidget {
  const RedusShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Redus Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
        cardTheme: CardThemeData(
          color: const Color(0xFF1D1E33),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  final _screens = [
    const HomeScreen(),
    const ReactivityScreen(),
    const LifecycleScreen(),
    const DIScreen(),
    DashboardScreen(),
  ];

  final _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bolt_outlined),
      selectedIcon: Icon(Icons.bolt),
      label: Text('Reactivity'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.loop_outlined),
      selectedIcon: Icon(Icons.loop),
      label: Text('Lifecycle'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.integration_instructions_outlined),
      selectedIcon: Icon(Icons.integration_instructions),
      label: Text('DI'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF111328),
            destinations: _destinations,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code, color: Colors.white),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
