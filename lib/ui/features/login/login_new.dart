import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/auth_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../utils/lego_block_style.dart';

/// Ecrã de Autenticação / Login com temática lúdica LEGO®
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late final TextEditingController _usuarioController;
  late final TextEditingController _senhaController;

  // Estados de controlo da interface
  bool _mostrarSenha = false;
  bool _isCarregando = false;
  bool _isGoogleCarregando = false;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _usuarioController = TextEditingController();
    _senhaController = TextEditingController();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Lógica de Autenticação Tradicional (Email/Username e Palavra-passe)
  Future<void> _processarLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _mensagemErro = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCarregando = true);

    try {
      final emailOuUser = _usuarioController.text.trim();
      final senha = _senhaController.text;

      // Invoca a função do repositório de autenticação via Riverpod
      await ref.read(authRepositoryProvider).entrarComEmail(
        email: emailOuUser,
        password: senha,
      );

      if (mounted) {
        // Redirecionamento gerido pelas rotas/authNotifier da aplicação
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErro = 'Nome de utilizador ou senha incorretos.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCarregando = false);
      }
    }
  }

  /// Lógica de Login com Conta Google
  Future<void> _processarLoginGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _mensagemErro = null;
      _isGoogleCarregando = true;
    });

    try {
      await ref.read(authRepositoryProvider).entrarComGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemErro = 'Não foi possível autenticar com o Google. Tenta novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleCarregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: LegoColors.blueDark,
      body: Stack(
        children: [
          // 1. Fundo com textura de pinos LEGO (Studs Pattern)
          Positioned.fill(
            child: CustomPaint(
              painter: _LegoStudsPatternPainter(),
            ),
          ),

          // 2. Conteúdo Scrollável Principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Título em estilo de Blocos 3D LEGO
                    _buildLegoTitleBanner(t),

                    const SizedBox(height: 28),

                    // Cartão Flutuante de Formulário
                    _buildLoginCardContainer(context, t),

                    const SizedBox(height: 20),

                    // Ilustração / Minifigura no Rodapé
                    _buildFooterMinifigure(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho em blocos LEGO "INICIAR SESSÃO"
  Widget _buildLegoTitleBanner(AppLocalizations? t) {
    const palavra1 = ['I', 'N', 'I', 'C', 'I', 'A', 'R'];
    const palavra2 = ['S', 'E', 'S', 'S', 'Ã', 'O'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: palavra1
              .map((letra) => _build3DBrickLetter(letra, LegoColors.red))
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: palavra2
              .map((letra) => _build3DBrickLetter(letra, LegoColors.yellow))
              .toList(),
        ),
      ],
    );
  }

  /// Bloco 3D individual para cada letra do título
  Widget _build3DBrickLetter(String letra, Color cor) {
    final isYellow = cor == LegoColors.yellow;
    final textCor = isYellow ? LegoColors.blueDark : Colors.white;

    return Container(
      width: 36,
      height: 42,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            offset: const Offset(0, -2),
            blurRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.black26,
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pino no topo do bloco 3D
          Positioned(
            top: 2,
            child: Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            letra,
            style: GoogleFonts.coiny(
              fontSize: 22,
              color: textCor,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  color: isYellow ? Colors.white70 : Colors.black45,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cartão Branco Elevado com o Formulário e Ações
  Widget _buildLoginCardContainer(BuildContext context, AppLocalizations? t) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LegoColors.yellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Mensagem de Erro
            if (_mensagemErro != null) ...[
              _buildErrorBanner(_mensagemErro!),
              const SizedBox(height: 16),
            ],

            // Campo 1: Utilizador / Email
            _buildFieldLabel('UTILIZADOR / EMAIL'),
            const SizedBox(height: 6),
            _buildInputField(
              controller: _usuarioController,
              hintText: 'O teu username ou email...',
              iconWidget: _buildLegoMinifigIcon(),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Introduz o teu utilizador ou email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campo 2: Senha
            _buildFieldLabel('SENHA'),
            const SizedBox(height: 6),
            _buildInputField(
              controller: _senhaController,
              hintText: 'A tua senha super-secreta...',
              isPassword: true,
              mostrarSenha: _mostrarSenha,
              iconWidget: const Icon(Icons.key_rounded, color: LegoColors.blueDark, size: 22),
              onTogglePassword: () {
                setState(() => _mostrarSenha = !_mostrarSenha);
              },
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Introduz a tua senha';
                }
                return null;
              },
            ),

            const SizedBox(height: 22),

            // Botão Principal "ENTRAR" (Estilo Tijolo Verde 3D)
            _buildLegoButton(
              label: 'ENTRAR',
              cor: LegoColors.green,
              isCarregando: _isCarregando,
              onPressed: _isCarregando || _isGoogleCarregando ? null : _processarLogin,
              icon: Icons.arrow_forward_rounded,
            ),

            const SizedBox(height: 12),

            // Botão "ENTRAR COM GOOGLE"
            _buildGoogleButton(
              label: 'ENTRAR COM GOOGLE',
              onPressed: _isCarregando || _isGoogleCarregando ? null : _processarLoginGoogle,
            ),

            const SizedBox(height: 12),

            // Botão "REGISTAR" (Estilo Tijolo Vermelho 3D)
            _buildLegoButton(
              label: 'REGISTAR',
              cor: LegoColors.red,
              onPressed: _isCarregando || _isGoogleCarregando
                  ? null
                  : () {
                // Navegar para o Ecrã de Registo
              },
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.varelaRound(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: LegoColors.blueDark,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildErrorBanner(String erro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LegoColors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              erro,
              style: GoogleFonts.varelaRound(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required Widget iconWidget,
    bool isPassword = false,
    bool mostrarSenha = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !mostrarSenha,
      validator: validator,
      style: GoogleFonts.varelaRound(
        color: LegoColors.blueDark,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.varelaRound(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: iconWidget,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            mostrarSenha ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
            size: 20,
          ),
          onPressed: onTogglePassword,
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LegoColors.blueDark, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LegoColors.yellow, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LegoColors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LegoColors.red, width: 2.5),
        ),
      ),
    );
  }

  /// Ícone estilizado de Cabeça de Minifigura LEGO
  Widget _buildLegoMinifigIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: LegoColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: LegoColors.blueDark, width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 6,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: LegoColors.blueDark, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Botão Estilo Bloco LEGO 3D
  Widget _buildLegoButton({
    required String label,
    required Color cor,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isCarregando = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tag de marca LEGO mini
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: LegoColors.red,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.yellow, width: 1),
                  ),
                  child: Text(
                    'LEGO',
                    style: GoogleFonts.coiny(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.coiny(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                if (isCarregando)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botão Google Estilizado
  Widget _buildGoogleButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleGLogo(),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.coiny(
                    color: LegoColors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleGLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.coiny(
            color: Colors.blue[700],
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Minifigura Espreitando no Rodapé
  Widget _buildFooterMinifigure() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
            color: LegoColors.yellow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
            border: Border.all(color: LegoColors.blueDark, width: 2),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Olhos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 8,
                    decoration: BoxDecoration(
                      color: LegoColors.blueDark,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 6,
                    height: 8,
                    decoration: BoxDecoration(
                      color: LegoColors.blueDark,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Sorriso
              Container(
                width: 20,
                height: 8,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: LegoColors.blueDark, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// CustomPainter para gerar o padrão repetitivo de pinos LEGO no fundo do ecrã
class _LegoStudsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint();
    final color = LegoColors.blueDark;

    final paintStudTop = Paint()
      ..color = const Color(0xFF0F2642)
      ..style = PaintingStyle.fill;

    final paintStudHighlight = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paintBase);

    const double spacing = 36.0;
    const double radius = 8.0;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        final center = Offset(x, y);

        // Corpo do pino
        canvas.drawCircle(center, radius, paintStudTop);

        // Brilho do pino 3D
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStudHighlight..strokeWidth = 2.0..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}