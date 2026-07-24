import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/dashbord/DashboardScreen.dart';
import 'package:lego_app/ui/features/lista/sets_list_screen_new.dart';
import 'package:lego_app/ui/features/login/AuthGate.dart';
import 'package:lego_app/ui/features/settings/settings_screen.dart';
import 'package:lego_app/ui/features/splash/splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  // WidgetsFlutterBinding tem de ser inicializado antes de qualquer
  // chamada assíncrona antes do runApp (aqui, o Firebase.initializeApp).
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ProviderScope tem de envolver a app para os providers do Riverpod
  // (setsRepositoryProvider, totalComprasProvider, utilizadorAtualProvider,
  // etc.) funcionarem.
  runApp(const ProviderScope(child: LegoApp()));
}

class LegoApp extends StatelessWidget {
  const LegoApp({super.key});

  @override
  Widget build(BuildContext context) {

    // Cores inspiradas na marca LEGO
    const legoRed = Color(0xFFE3000B);
    const legoYellow = Color(0xFFFFD500);
    const legoDark = Color(0xFF1F1F1F);
    const legoBackground = Color(0xFFF4F4F4);

    return MaterialApp(
      title: 'Lego App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: legoBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: legoRed,
          primary: legoRed,
          secondary: legoYellow,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: legoDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: legoRed,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: legoYellow,
          foregroundColor: legoDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: legoRed, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const SplashScreen(),
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
    SetsListScreenNew(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _ecrans),
      bottomNavigationBar: _BarraFlutuante(
        indice: _indice,
        onSelecionar: (i) => setState(() => _indice = i),
      ),
    );
  }
}

/// Barra de navegação flutuante: um "pill" arredondado com sombra,
/// afastado das margens e do fundo do ecrã (em vez de colado a toda a
/// largura/altura como a NavigationBar padrão do Material).
class _BarraFlutuante extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onSelecionar;

  const _BarraFlutuante({required this.indice, required this.onSelecionar});

  static const _itens = [
    _ItemNav(
      icone: Icons.dashboard_outlined,
      iconeAtivo: Icons.dashboard,
      label: 'Dashboard',
    ),
    _ItemNav(
      icone: Icons.widgets_outlined,
      iconeAtivo: Icons.widgets,
      label: 'Meus Sets',
    ),
    _ItemNav(
      icone: Icons.settings_applications_outlined,
      iconeAtivo: Icons.settings_applications,
      label: 'Configurações',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final corAtiva = Theme.of(context).colorScheme.primary;
    final corInativa = Theme.of(context).colorScheme.outline;

    return SafeArea(
      // Só a margem lateral/inferior conta para o SafeArea; o resto do
      // espaçamento é feito no Padding abaixo.
      minimum: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _itens.length; i++)
                Expanded(
                  child: _BotaoNav(
                    item: _itens[i],
                    selecionado: i == indice,
                    corAtiva: corAtiva,
                    corInativa: corInativa,
                    onTap: () => onSelecionar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoNav extends StatelessWidget {
  final _ItemNav item;
  final bool selecionado;
  final Color corAtiva;
  final Color corInativa;
  final VoidCallback onTap;

  const _BotaoNav({
    required this.item,
    required this.selecionado,
    required this.corAtiva,
    required this.corInativa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? corAtiva : corInativa;

    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selecionado ? item.iconeAtivo : item.icone, color: cor, size: 24),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              color: cor,
              fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemNav {
  final IconData icone;
  final IconData iconeAtivo;
  final String label;

  const _ItemNav({required this.icone, required this.iconeAtivo, required this.label});
}