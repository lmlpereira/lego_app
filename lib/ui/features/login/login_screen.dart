import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lego_app/ui/features/login/register_screen.dart';

import '../utils/lego_block_style.dart';

class LegoLoginScreen extends ConsumerStatefulWidget {
  const LegoLoginScreen({super.key});

  @override
  ConsumerState<LegoLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LegoLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeterLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: Adicionar aqui a lógica de autenticação (ex: ref.read(authProvider)...)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LegoColors.blue,
      body: Stack(
        children: [
          // 1. Fundo de pinos LEGO (Preenche sempre o ecrã todo)
          const Positioned.fill(
            child: LegoFloorBackground(),
          ),

          // 2. Conteúdo com CustomScrollView para preencher os 100% da altura
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, // Garante que o conteúdo estica para ocupar a tela inteira
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribui o conteúdo de topo a fundo
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bloco Superior (Título + Formulário)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            const LegoTitleBlock(text: 'LOGIN'),
                            const SizedBox(height: 30),
                            const _LegoLoginFormPanel(), // O teu formulário
                          ],
                        ),

                        // Bloco Inferior (Links + Espaço para o Boneco)
                        /*Column(
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Esqueceu-se da Palavra-Passe?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.varelaRound(
                                  color: LegoColors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Ainda não é um LEGO Insider? Registar-se!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.varelaRound(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Espaço reserva no fundo para o boneco não tapar os botões
                            const SizedBox(height: 130),
                          ],
                        ),*/
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Boneco LEGO afixado no fundo do ecrã
          Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            child: IgnorePointer(
              child: Image.asset(
                'assets/lego_minifig.png',
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 150),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.varelaRound(
        color: LegoColors.blueDark,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}

class _LegoLoginFormPanel extends StatelessWidget {
  const _LegoLoginFormPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LegoColors.blueDark, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(4, 4), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo Utilizador
          const _LegoInputFieldMobile(
            label: 'NOME DE UTILIZADOR / EMAIL',
            placeholder: 'Insira o seu nome ou email',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          // Campo Senha
          const _LegoInputFieldMobile(
            label: 'PALAVRA PASSE',
            placeholder: '••••••••',
            icon: Icons.key_outlined,
            isPassword: true,
          ),
          const SizedBox(height: 24),

          // Botão Entrar
          const _LegoSignInButtonMobile(),
          const SizedBox(height: 24),

          // Botão Google
          const _LegoGoogleButtonMobile(),
          const SizedBox(height: 24),

          // Botão Registar
          const _LegoRegisterButtonMobile(),
        ],
      ),
    );
  }
}

class _LegoInputFieldMobile extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final bool isPassword;

  const _LegoInputFieldMobile({
    required this.label,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.varelaRound(
            color: LegoColors.blueDark,
            fontWeight: FontWeight.bold,
            fontSize: 12, // Reduzido para telemóvel
          ),
        ),
        const SizedBox(height: 6),
        LegoBlockDecorator(
          color: LegoColors.lightGrey,
          borderRadius: 6,
          child: TextField(
            obscureText: isPassword,
            style: GoogleFonts.varelaRound(fontSize: 14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.varelaRound(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(icon, color: LegoColors.yellow, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegoSignInButtonMobile extends StatelessWidget {
  const _LegoSignInButtonMobile();

  @override
  Widget build(BuildContext context) {
    return LegoBlockDecorator(
      color: LegoColors.red,
      borderRadius: 8,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A entrar...")));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo LEGO (precisa estar nos assets)
              Image.asset(
                'assets/lego.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'ENTRAR!',
                style: GoogleFonts.varelaRound(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegoRegisterButtonMobile extends StatelessWidget {
  const _LegoRegisterButtonMobile();

  @override
  Widget build(BuildContext context) {
    return LegoBlockDecorator(
      color: LegoColors.red,
      borderRadius: 8,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RegisterScreen(), // <-- Substitui pelo teu ecrã inicial
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo LEGO (precisa estar nos assets)
              Image.asset(
                'assets/lego.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Registar!',
                style: GoogleFonts.varelaRound(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegoGoogleButtonMobile extends StatelessWidget {
  const _LegoGoogleButtonMobile();

  @override
  Widget build(BuildContext context) {
    return LegoBlockDecorator(
      color: LegoColors.mediumGrey,
      borderRadius: 8,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A entrar...")));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo LEGO (precisa estar nos assets)
              Image.asset(
                'assets/google.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24),
              ),
              const SizedBox(width: 12),
              /*Text(
                'Entrar com Google!',
                style: GoogleFonts.varelaRound(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.send, color: Colors.white, size: 20),*/
            ],
          ),
        ),
      ),
    );
  }
}

class LegoFloorBackground extends StatelessWidget {
  const LegoFloorBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / 25.0).floor();
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) => Container(
            decoration: const BoxDecoration(
              color: LegoColors.mediumGrey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Título dinâmico onde cada letra fica dentro de um bloco
class LegoTitleBlock extends StatelessWidget {
  final String text;
  const LegoTitleBlock({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: text.toUpperCase().split('').map((letter) {
          Color blockColor = LegoColors.red;
          if (letter == 'O' || letter == 'N' || letter == 'E') {
            blockColor = LegoColors.yellow;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LegoBlockDecorator(
              color: blockColor,
              borderRadius: 4,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: GoogleFonts.coiny(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}