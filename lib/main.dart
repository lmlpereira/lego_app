import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/dashbord/DashboardScreen.dart';
import 'package:lego_app/ui/features/import/import_screen.dart';
import 'package:lego_app/ui/features/lista/sets_list_screen.dart';

void main() {
  // ProviderScope tem de envolver a app para os providers do Riverpod
  // (setsRepositoryProvider, totalComprasProvider, etc.) funcionarem.
  runApp(const ProviderScope(child: LegoApp()));
}

class LegoApp extends StatelessWidget {
  const LegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lego App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

/// Casca da app: alterna entre Dashboard, Lista de sets e Importar
/// através de uma barra de navegação em baixo. Usa IndexedStack (em vez
/// de trocar o widget diretamente) para que cada ecrã mantenha o seu
/// estado (ex: scroll da lista) ao saltar entre abas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  // "static final" em vez de "const": não obriga todos os ecrãs a terem
  // construtor const (não sabemos ao certo se SetsListScreen já tem).
  static final _ecrans = [
    DashboardScreen(),
    SetsListScreen(),
    ImportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _ecrans),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Sets',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Importar',
          ),
        ],
      ),
    );
  }
}