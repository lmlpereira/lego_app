import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import '../utils/lego_block_style.dart';
import 'login_screen.dart';

class RegisterLegoScreen extends ConsumerStatefulWidget {
  const RegisterLegoScreen({super.key});

  @override
  ConsumerState<RegisterLegoScreen> createState() => _RegisterLegoScreenState();
}

class _RegisterLegoScreenState extends ConsumerState<RegisterLegoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _usernameCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _idLegoInsidersCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  DateTime? _dataNascimento;
  String? _sexo;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _erro;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nomeCtrl.dispose();
    _idLegoInsidersCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataNascimento() async {
    final dataHoje = DateTime.now();
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: dataHoje,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: LegoColors.red,
              onPrimary: Colors.white,
              onSurface: LegoColors.blueDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      setState(() => _dataNascimento = dataSelecionada);
    }
  }

  Future<void> _submeterRegisto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      await ref.read(authRepositoryProvider).registarComEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        username: _usernameCtrl.text,
        nome: _nomeCtrl.text,
        dataNascimento: _dataNascimento,
        idLegoInsiders: _idLegoInsidersCtrl.text,
        sexo: _sexo,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeShell()),
              (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Ocorreu um erro ao criar a conta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LegoColors.blue,
      body: Stack(
        children: [
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
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            LegoTitleBlock(text: t.registotitle),
                            const SizedBox(height: 24),

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

                            // Painel do Formulário
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
                                    // 1. Nome Completo (OBRIGATÓRIO)
                                    _buildLabel(t.nomeLabel, isRequired: true),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _nomeCtrl,
                                      hint: t.nomeHint,
                                      icon: Icons.badge_outlined,
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? t.nomeError
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // 2. Nome de Utilizador (OBRIGATÓRIO)
                                    _buildLabel(t.usernameLabel, isRequired: true),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _usernameCtrl,
                                      hint: t.usernameHint,
                                      icon: Icons.person_outline,
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? t.usernameError
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // 3. Email (OBRIGATÓRIO)
                                    _buildLabel(t.emailLabel, isRequired: true),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _emailCtrl,
                                      hint: t.emailHint,
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return t.emailError;
                                        }
                                        if (!v.contains('@') || !v.contains('.')) {
                                          return t.emailError2;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 4. Password (OBRIGATÓRIO)
                                    _buildLabel(t.passwordLabel, isRequired: true),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _passwordCtrl,
                                      hint: t.passwordHint,
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
                                          return t.passwordError;
                                        }
                                        if (v.length < 6) {
                                          return t.passwordError2;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 5. Confirmação de Password (OBRIGATÓRIO)
                                    _buildLabel(t.passwordLabel2, isRequired: true),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _confirmarCtrl,
                                      hint: t.passwordHint2,
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
                                        if (v == null || v.isEmpty) {
                                          return t.passwordError3;
                                        }
                                        if (v != _passwordCtrl.text) {
                                          return t.passwordError4;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    const Divider(color: LegoColors.lightGrey, thickness: 2),
                                    const SizedBox(height: 8),

                                    // 6. ID LEGO Insiders (OPCIONAL)
                                    _buildLabel(t.legoInsidersLabel),
                                    const SizedBox(height: 4),
                                    _buildInputField(
                                      controller: _idLegoInsidersCtrl,
                                      hint: t.legoInsidersHint,
                                      icon: Icons.card_membership_outlined,
                                    ),
                                    const SizedBox(height: 12),

                                    // 7. Data de Nascimento (OPCIONAL)
                                    _buildLabel(t.dataNascimentoLabel),
                                    const SizedBox(height: 4),
                                    LegoBlockDecorator(
                                      color: LegoColors.lightGrey,
                                      borderRadius: 6,
                                      child: InkWell(
                                        onTap: _selecionarDataNascimento,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.cake_outlined,
                                                  color: LegoColors.yellow, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                _dataNascimento == null
                                                    ? t.dataNascimentoHint
                                                    : '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}',
                                                style: GoogleFonts.varelaRound(
                                                  fontSize: 13,
                                                  color: _dataNascimento == null
                                                      ? Colors.grey
                                                      : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // 8. Sexo (OPCIONAL)
                                    _buildLabel(t.sexoLabel),
                                    const SizedBox(height: 4),
                                    LegoBlockDecorator(
                                      color: LegoColors.lightGrey,
                                      borderRadius: 6,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _sexo,
                                            hint: Text(
                                              t.sexoHint,
                                              style: GoogleFonts.varelaRound(
                                                  color: Colors.grey, fontSize: 13),
                                            ),
                                            isExpanded: true,
                                            icon: const Icon(Icons.arrow_drop_down,
                                                color: LegoColors.yellow),
                                            items: ['Masculino', 'Feminino', 'Outro']
                                                .map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Text(
                                                item,
                                                style: GoogleFonts.varelaRound(
                                                    fontSize: 13),
                                              ),
                                            ))
                                                .toList(),
                                            onChanged: (val) => setState(() => _sexo = val),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Botão Registar
                                    LegoBlockDecorator(
                                      color: LegoColors.green,
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
                                                t.criarConta,
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

                        // Link Voltar
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                t.alredyConta,
                                style: GoogleFonts.varelaRound(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
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

          // Boneco LEGO
          Positioned(
            left: 0,
            right: 0,
            bottom: -15,
            child: IgnorePointer(
              child: Image.asset(
                'assets/lego_minifig.png',
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

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.varelaRound(
            color: LegoColors.blueDark,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.varelaRound(
              color: LegoColors.red,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

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