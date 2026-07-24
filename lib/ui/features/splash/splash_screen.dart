import 'dart:async';
import 'package:flutter/material.dart';

// Importa o teu widget de animação do LEGO
import '../../../main.dart';
import '../utils/lego_brick_loading.dart';

// Importa o teu ecrã principal / inicial da app
// import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Temporizador de 5 segundos
    _timer = Timer(const Duration(seconds: 5), _navegarParaHome);
  }

  void _navegarParaHome() {
    if (!mounted) return;

    // Substitui o SplashScreen pelo ecrã inicial (ex: HomeScreen)
    // Usamos pushReplacement para o utilizador não conseguir voltar atrás para o Splash
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeShell(), // <-- Substitui pelo teu ecrã inicial
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela o timer se o widget for destruído antes do tempo
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logótipo / Nome da Aplicação
              /*Icon(
                Icons.extension,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),*/
              // Carrega a imagem do ícone configurado no teu projeto
              ClipRRect(
                borderRadius: BorderRadius.circular(20), // BORDAS ARREDONDADAS ESTILO APP ICON
                child: Image.asset(
                  'assets/piece.png', // <-- Caminho da imagem do teu ícone
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback caso a imagem ainda não exista na pasta de assets
                    return Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.widgets,
                        size: 48,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'LEGO Collector',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Gestão de Coleção',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              // Animação do Lego a cair e empilhar
              const LegoBrickLoading(
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 16),
              const Text(
                'A carregar a coleção...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              // Crédito no rodapé do Splash
              const Text(
                'Dev4You - Luis Pereira',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}