import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/dashbord/DashboardScreen.dart';
import 'package:lego_app/ui/features/dashbord/lego_dashboard.dart';
import 'package:lego_app/ui/features/lista/sets_list_screen_new.dart';
import 'package:lego_app/ui/features/login/login_screen.dart';
import 'package:lego_app/ui/features/onboarding/welcome_screen.dart';
import 'package:lego_app/ui/features/settings/settings_screen.dart';
import 'package:lego_app/ui/features/splash/splash_screen.dart';
import 'package:lego_app/ui/features/utils/lego_block_style.dart';
import 'package:lego_app/ui/features/utils/lego_brick_clipper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/locale_providers.dart';
import 'data/sync_providers.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final bool isFT = prefs.getBool('is_first_time') ?? true;

  runApp(ProviderScope(child: LegoApp(isFirstTime: isFT)));
}

class LegoApp extends ConsumerWidget {
  final bool isFirstTime;

  const LegoApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const legoRed = Color(0xFFE3000B);
    const legoYellow = Color(0xFFFFD500);
    const legoDark = Color(0xFF1F1F1F);
    const legoBackground = Color(0xFFF4F4F4);

    final locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.titleWelcomeScreen,
      debugShowCheckedModeBanner: false,
      // Português e inglês. `locale` vem do localeControllerProvider:
      // null (nenhuma escolha explícita, ver Perfil > Idioma) = segue o
      // idioma do telemóvel automaticamente; se não for nenhum dos dois
      // suportados, cai no primeiro de supportedLocales (pt). Quando a
      // pessoa escolhe um idioma explicitamente, esse valor passa a ser
      // usado sempre, independentemente do idioma do aparelho.
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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
        // Configuração global da AppBar arredondada nas pontas inferiores
        appBarTheme: const AppBarTheme(
          backgroundColor: legoRed,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: legoYellow,
          foregroundColor: legoDark,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: isFirstTime
          ? Builder(
        builder: (navContext) {
          return WelcomeScreen(
            onLoginPressed: () {
              Navigator.of(navContext).pushReplacement(
                MaterialPageRoute(builder: (context) => const LegoLoginScreen()),
              );
            },
            onGuestPressed: () {
              Navigator.of(navContext).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeShell()),
              );
            },
          );
        },
      )
          : const SplashScreen(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _indice = 0;

  static final _ecrans = [
    LegoDashboardScreen(),
    SetsListScreenNew(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    ref.watch(syncControllerProvider);

    return Scaffold(
      body: IndexedStack(index: _indice, children: _ecrans),
      bottomNavigationBar: _BarraFlutuante(
        indice: _indice,
        onSelecionar: (i) => setState(() => _indice = i),
      ),
    );
  }
}

/// Barra de navegação flutuante personalizada com botões estilo LEGO
class _BarraFlutuante extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onSelecionar;



  const _BarraFlutuante({required this.indice, required this.onSelecionar});



  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    // Não é "static const" como antes: os labels agora vêm traduzidos
    // (precisam do BuildContext), por isso a lista é construída a cada
    // build — o custo é insignificante (3 items).
    final _itens = [
      _ItemNav(
        corAtiva: LegoColors.red,
        icone: Icons.dashboard_outlined,
        iconeAtivo: Icons.dashboard,
        label: t.navDashboard,
      ),
      _ItemNav(
        corAtiva: LegoColors.blue,
        icone: Icons.widgets_outlined,
        iconeAtivo: Icons.widgets,
        label: t.navMySets,
      ),
      _ItemNav(
        corAtiva: LegoColors.yellow,
        icone: Icons.settings_applications_outlined,
        iconeAtivo: Icons.settings_applications,
        label: t.navSettings,
      ),
    ];

    return SafeArea(
      minimum: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 68,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [

              for (var i = 0; i < _itens.length; i++)
                Expanded(
                  child: _BotaoNavLego(
                    item: _itens[i],
                    selecionado: i == indice,
                    corAtiva: _itens[i].corAtiva,
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

class _BotaoNavLego extends StatelessWidget {
  final _ItemNav item;
  final bool selecionado;
  final Color corAtiva;
  final VoidCallback onTap;

  const _BotaoNavLego({
    required this.item,
    required this.selecionado,
    required this.corAtiva,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: selecionado
            ? ClipPath(
          clipper: LegoBrickClipper(),
          child: Container(
            width: double.infinity,
            height: 64,
            color: corAtiva,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  item.iconeAtivo,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icone,
              color: Theme.of(context).colorScheme.outline,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _ItemNav {
  final IconData icone;
  final IconData iconeAtivo;
  final String label;
  final Color corAtiva;

  const _ItemNav({
    required this.corAtiva,
    required this.icone,
    required this.iconeAtivo,
    required this.label,
  });
}