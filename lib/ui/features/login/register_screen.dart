import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/lego_block_style.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para os 5 campos solicitados
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submeterRegisto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: Chamar o provider de autenticação (ex: Firebase Auth / Backend)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LegoColors.blue,
      body: Stack(
        children: [
          // 1. Fundo de pinos LEGO (Ocupa a tela inteira)
          const Positioned.fill(
            child: LegoFloorBackground(),
          ),

          // 2. Conteúdo em Scroll para telemóveis
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Seção Superior: Título + Formulário
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            const LegoTitleBlock(text: 'REGISTO'),
                            const SizedBox(height: 24),

                            // Painel Branco do Formulário
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: LegoColors.blueDark, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    offset: Offset(4, 4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Nome
                                    _buildLabel('NOME COMPLETO'),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _nameCtrl,
                                      hint: 'Ex: João Silva',
                                      icon: Icons.badge_outlined,
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Insira o seu nome'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // 2. Nome de Utilizador
                                    _buildLabel('NOME DE UTILIZADOR'),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _usernameCtrl,
                                      hint: 'Ex: joaosilva99',
                                      icon: Icons.person_outline,
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'Insira um nome de utilizador'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // 3. Email
                                    _buildLabel('EMAIL'),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _emailCtrl,
                                      hint: 'exemplo@email.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Insira o seu email';
                                        }
                                        if (!v.contains('@') || !v.contains('.')) {
                                          return 'Email inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 4. Password
                                    _buildLabel('PALAVRA-PASSE'),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _passwordCtrl,
                                      hint: '••••••••',
                                      icon: Icons.lock_outline,
                                      isPassword: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                              () => _obscurePassword = !_obscurePassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Insira a palavra-passe';
                                        }
                                        if (v.length < 6) {
                                          return 'Mínimo de 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 5. Confirmação de Password
                                    _buildLabel('CONFIRMAR PALAVRA-PASSE'),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _confirmPasswordCtrl,
                                      hint: '••••••••',
                                      icon: Icons.lock_reset_outlined,
                                      isPassword: _obscureConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                              () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v != _passwordCtrl.text) {
                                          return 'As palavras-passe não coincidem';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Botão Registar
                                    LegoBlockDecorator(
                                      color: LegoColors.green, // Cor verde para criar conta
                                      borderRadius: 8,
                                      child: InkWell(
                                        onTap: _loading ? null : _submeterRegisto,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: _loading
                                              ? const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                              : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'CRIAR CONTA!',
                                                style: GoogleFonts.varelaRound(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.check_circle_outline,
                                                  color: Colors.white, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Seção Inferior: Link de voltar ao Login + Espaço Minifigura
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Já tens conta? Fazer Login',
                                style: GoogleFonts.varelaRound(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Espaço reservado para o boneco no fundo não tapar o botão
                            const SizedBox(height: 100),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Boneco LEGO no Fundo
          Positioned(
            left: 0,
            right: 0,
            bottom: -15,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/lego_minifig.png',
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 140),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para os rótulos dos campos
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.varelaRound(
        color: LegoColors.blueDark,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  // Helper para os inputs em blocos 3D
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return LegoBlockDecorator(
      color: LegoColors.lightGrey,
      borderRadius: 6,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.varelaRound(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.varelaRound(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: LegoColors.yellow, size: 18),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          errorStyle: GoogleFonts.varelaRound(fontSize: 10, color: LegoColors.red),
        ),
        validator: validator,
      ),
    );
  }
}