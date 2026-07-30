import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/auth_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../utils/lego_block_style.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _legoInsidersController;

  DateTime? _dataNascimento;
  String? _sexoSelecionado;
  bool _isCarregando = false;

  final List<String> _opcoesSexo = [
    'Masculino',
    'Feminino',
    'Outro',
    'Preferir não dizer',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _nomeController = TextEditingController();
    _emailController = TextEditingController();
    _legoInsidersController = TextEditingController();

    // Carregar dados existentes do utilizador
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(utilizadorAtualProvider).value;
      if (user != null) {
        setState(() {
          _usernameController.text = user.username ?? '';
          _emailController.text = user.email ?? '';
          _nomeController.text = user.nome ?? '';
          _legoInsidersController.text = user.idLegoInsiders ?? '';
          _dataNascimento = user.dataNascimento;
          _sexoSelecionado = user.sexo;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _legoInsidersController.dispose();
    super.dispose();
  }

  /// Abrir o Seletor de Data
  Future<void> _selecionarDataNascimento() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: LegoColors.blueDark,
              onPrimary: Colors.white,
              onSurface: LegoColors.blueDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dataNascimento) {
      setState(() {
        _dataNascimento = picked;
      });
    }
  }

  /// Guardar as alterações
  Future<void> _guardarPerfil() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCarregando = true);

    try {
      await ref.read(authRepositoryProvider).atualizarPerfil(
        nome: _nomeController.text,
        dataNascimento: _dataNascimento,
        idLegoInsiders: _legoInsidersController.text,
        sexo: _sexoSelecionado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.profileSaveSucess,
              style: GoogleFonts.varelaRound(fontWeight: FontWeight.bold),
            ),
            backgroundColor: LegoColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.profileSaveError(e.toString()),
              style: GoogleFonts.varelaRound(fontWeight: FontWeight.bold),
            ),
            backgroundColor: LegoColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // Header Top Bar
          _buildCustomAppBar(context, t),

          // Scrollable Content
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Avatar Card
                      _buildHeaderAvatarCard(),

                      const SizedBox(height: 20),

                      // Secção: Informações da Conta
                      _buildSectionTitle(t.dadosdacontaLabel),
                      const SizedBox(height: 10),
                      _buildCardGroup([
                        _buildInputField(
                          enabled: false,
                          controller: _usernameController,
                          label: t.usernamePerfilLabel,
                          icon: Icons.alternate_email,
                          suffixIcon: Icons.lock_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t.usernameValidator;
                            }
                            if (value.trim().length < 3) {
                              return t.usernameValidatorLenght;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: _emailController,
                          label: t.emailPerfilLabel,
                          icon: Icons.email_outlined,
                          suffixIcon: Icons.lock_outline_rounded,
                          enabled: false,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Secção: Informações Pessoais
                      _buildSectionTitle(t.personalDetailsLabel),
                      const SizedBox(height: 10),
                      _buildCardGroup([
                        _buildInputField(
                          controller: _nomeController,
                          label: t.nomePerfilLabel,
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t.nomeValidator;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildDatePickerField(),
                        const SizedBox(height: 14),
                        _buildDropdownSexo(),
                      ]),

                      const SizedBox(height: 24),

                      // Secção: LEGO Insiders VIP
                      _buildSectionTitle(t.programaLegoInsidersLabel),
                      const SizedBox(height: 10),
                      _buildInsidersCardGroup(t),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Save Action Bar
          _buildBottomActionBar(t),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, AppLocalizations t) {
    return Container(
      color: LegoColors.red,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              LegoBlockDecorator(
                color: LegoColors.yellow,
                borderRadius: 10,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: LegoColors.blueDark,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                t.editProfileTitle,
                style: GoogleFonts.varelaRound(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAvatarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: LegoColors.yellow,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: LegoColors.blueDark,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: LegoColors.blueDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _nomeController.text.isNotEmpty
                ? _nomeController.text
                : (_usernameController.text.isNotEmpty ? _usernameController.text : ''),
            style: GoogleFonts.varelaRound(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LegoColors.blueDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _emailController.text,
            style: GoogleFonts.varelaRound(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.varelaRound(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildInsidersCardGroup(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LegoColors.yellow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: LegoColors.blueDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  color: LegoColors.yellow,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.digitalCardInsidersLabel,
                      style: GoogleFonts.varelaRound(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: LegoColors.blueDark,
                      ),
                    ),
                    Text(
                      t.digitalCardInsidersContent,
                      style: GoogleFonts.varelaRound(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _legoInsidersController,
            label: t.idlegoinsidersLabel,
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.varelaRound(
        color: enabled ? LegoColors.blueDark : Colors.grey[600],
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.varelaRound(
          color: enabled ? LegoColors.blueDark : Colors.grey[500],
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? LegoColors.blueDark : Colors.grey[400],
          size: 20,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[400], size: 18)
            : null,
        filled: true,
        fillColor: enabled ? const Color(0xFFFAFAFA) : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.blueDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    final t = AppLocalizations.of(context)!;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final textoData = _dataNascimento != null
        ? dateFormat.format(_dataNascimento!)
        : t.datanacimentoHint;

    return InkWell(
      onTap: _selecionarDataNascimento,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.dataNascimentoLabel,
          labelStyle: GoogleFonts.varelaRound(color: LegoColors.blueDark, fontSize: 13),
          prefixIcon: const Icon(Icons.cake_outlined, color: LegoColors.blueDark, size: 20),
          suffixIcon: const Icon(Icons.calendar_month_rounded, color: LegoColors.blueDark, size: 18),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Text(
          textoData,
          style: GoogleFonts.varelaRound(
            color: _dataNascimento != null ? LegoColors.blueDark : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSexo() {
    final t = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      value: _sexoSelecionado,
      icon: const Icon(Icons.arrow_drop_down, color: LegoColors.blueDark),
      decoration: InputDecoration(
        labelText: t.sexoPerfilLabel,
        labelStyle: GoogleFonts.varelaRound(color: LegoColors.blueDark, fontSize: 13),
        prefixIcon: const Icon(Icons.people_outline, color: LegoColors.blueDark, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.blueDark, width: 2),
        ),
      ),
      items: _opcoesSexo.map((String sexo) {
        return DropdownMenuItem<String>(
          value: sexo,
          child: Text(
            sexo,
            style: GoogleFonts.varelaRound(
              color: LegoColors.blueDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      onChanged: (novoValor) {
        setState(() {
          _sexoSelecionado = novoValor;
        });
      },
    );
  }

  Widget _buildBottomActionBar(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: LegoBlockDecorator(
        color: LegoColors.green,
        borderRadius: 12,
        child: InkWell(
          onTap: _isCarregando ? null : _guardarPerfil,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _isCarregando
                ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  t.commonSave,
                  style: GoogleFonts.varelaRound(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}