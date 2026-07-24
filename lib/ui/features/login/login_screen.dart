import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lego_app/ui/features/login/register_screen.dart';
import 'package:lego_app/ui/features/perfil/complete_profile_form.dart';

import '../../../data/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../main.dart';
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
  bool _aEntrarGoogle = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeterLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      await ref.read(authRepositoryProvider).entrarComEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );

      if (mounted) {
        _navegarParaHome();
      }

    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() {
      _aEntrarGoogle = true;
      _erro = null;
    });

    try {
      // 1. Obtém o utilizador autenticado
      final user = await ref.read(authRepositoryProvider).entrarComGoogle();

      if (!mounted) return;

      // 2. Verifica se o utilizador precisa de completar o perfil
      // Assumimos que se o username for nulo ou vazio, o perfil está incompleto
      final perfilIncompleto = user.username == null || user.username!.trim().isEmpty;

      if (perfilIncompleto) {
        // Redireciona para o ecrã de completar perfil
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
              (route) => false,
        );
      } else {
        // Perfil completo -> Vai para a Home
        if (mounted) {
          _navegarParaHome();
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao entrar com o Google: $e');
    } finally {
      if (mounted) setState(() => _aEntrarGoogle = false);
    }
  }



  void _navegarParaHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeShell()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tecladoAberto = MediaQuery.of(context).viewInsets.bottom > 0;


    return Scaffold(
      backgroundColor: LegoColors.blue,
      //resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            const LegoTitleBlock(text: 'LOGIN'),
                            const SizedBox(height: 30),

                            // Mensagem de Erro
                            if (_erro != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: LegoColors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _erro!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.varelaRound(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],

                            // Formulário com referências aos handlers e controladores
                            _LegoLoginFormPanel(
                              formKey: _formKey,
                              emailCtrl: _emailCtrl,
                              passwordCtrl: _passwordCtrl,
                              isLoading: _loading,
                              isGoogleLoading: _aEntrarGoogle,
                              onLogin: _submeterLogin,
                              onGoogleLogin: _entrarComGoogle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Boneco LEGO no fundo
          if (!tecladoAberto)
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
}

class _LegoLoginFormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final bool isGoogleLoading;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;

  const _LegoLoginFormPanel({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.isGoogleLoading,
    required this.onLogin,
    required this.onGoogleLogin,
  });

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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo Utilizador/Email
            _LegoInputFieldMobile(
              controller: emailCtrl,
              label: 'EMAIL',
              placeholder: 'Insira o seu email',
              icon: Icons.person_outline,
              validator: (v) => v == null || v.trim().isEmpty ? 'Insira o email' : null,
            ),
            const SizedBox(height: 16),

            // Campo Senha
            _LegoInputFieldMobile(
              controller: passwordCtrl,
              label: 'PALAVRA PASSE',
              placeholder: '••••••••',
              icon: Icons.key_outlined,
              isPassword: true,
              validator: (v) => v == null || v.isEmpty ? 'Insira a palavra-passe' : null,
            ),
            const SizedBox(height: 24),

            // Botão Entrar
            _LegoSignInButtonMobile(
              isLoading: isLoading,
              onPressed: onLogin,
            ),
            const SizedBox(height: 16),

            // Botão Google
            _LegoGoogleButtonMobile(
              isLoading: isGoogleLoading,
              onPressed: onGoogleLogin,
            ),

            const SizedBox(height: 16),

            _LegoRegistarButtonMobile(isLoading: false, onPressed: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterLegoScreen()));
            },)
          ],
        ),
      ),
    );
  }
}

class _LegoInputFieldMobile extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final bool isPassword;
  final String? Function(String?)? validator;

  const _LegoInputFieldMobile({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
    this.validator,
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
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        LegoBlockDecorator(
          color: LegoColors.lightGrey,
          borderRadius: 6,
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            validator: validator,
            style: GoogleFonts.varelaRound(fontSize: 14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.varelaRound(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(icon, color: LegoColors.yellow, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegoSignInButtonMobile extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LegoSignInButtonMobile({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LegoBlockDecorator(
      color: LegoColors.green,
      borderRadius: 8,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LegoRegistarButtonMobile extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LegoRegistarButtonMobile({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LegoBlockDecorator(
      color: LegoColors.red,
      borderRadius: 8,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else ...[
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
            ],
          ),
        ),
      ),
    );
  }
}


class _LegoGoogleButtonMobile extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LegoGoogleButtonMobile({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LegoBlockDecorator(
      color: LegoColors.mediumGrey,
      borderRadius: 8,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else ...[
                Image.asset(
                  'assets/google.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Entrar com Google',
                  style: GoogleFonts.varelaRound(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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