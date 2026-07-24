import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/lego_block_style.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final VoidCallback onGuestPressed;

  const WelcomeScreen({
    super.key,
    required this.onLoginPressed,
    required this.onGuestPressed,
  });

  // Guardar preferência para não voltar a mostrar este ecrã no arranque
  Future<void> _setFirstTimeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LegoColors.lightGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),

              // LOGO E ILUSTRAÇÃO CENTRAL
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: LegoColors.blueDark,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    )
                  ],
                ),
                child: Image.asset(
                  'assets/lego_minifig.png', // Ou 'assets/piece.png' que já usaste no Splash
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback caso a imagem não seja encontrada
                    return const Icon(
                      Icons.extension_rounded,
                      size: 80,
                      color: Colors.white,
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // TÍTULO DA APP
              Text(
                'LEGO Collector',
                style: GoogleFonts.varelaRound(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: LegoColors.darkGrey,
                ),
              ),

              const SizedBox(height: 12),

              // SUBTÍTULO DESCRITIVO
              Text(
                'Gere os teus sets, acompanha a tua wishlist e explora a tua coleção num só lugar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.varelaRound(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // BOTÃO PRINCIPAL: INICIAR SESSÃO / LOGIN
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _setFirstTimeCompleted();
                    onLoginPressed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LegoColors.blue,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, color: Colors.white),
                  label: Text(
                    'Iniciar Sessão',
                    style: GoogleFonts.varelaRound(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // BOTÃO SECUNDÁRIO: MODO CONVIDADO
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _setFirstTimeCompleted();
                    onGuestPressed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LegoColors.yellow,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon:  Icon(Icons.arrow_forward_rounded, color: LegoColors.darkGrey),
                  label: Text(
                    'Continuar sem Conta',
                    style: GoogleFonts.varelaRound(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LegoColors.darkGrey,
                    ),
                  ),
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