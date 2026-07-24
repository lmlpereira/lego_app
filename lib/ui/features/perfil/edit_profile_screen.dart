import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/auth_providers.dart';
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
          // Caso a tua classe User tenha estes campos no futuro:
          // _nomeController.text = user.nome ?? '';
          // _legoInsidersController.text = user.legoInsidersId ?? '';
          // _dataNascimento = user.dataNascimento;
          // _sexoSelecionado = user.sexo;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCarregando = true);

    try {
      // TODO: Adicionar o método de guardar no teu authRepository ou profileRepository
      // await ref.read(authRepositoryProvider).atualizarPerfil(...);

      await Future.delayed(const Duration(seconds: 1)); // Simulação de envio

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perfil atualizado com sucesso!',
              style: GoogleFonts.varelaRound(fontWeight: FontWeight.bold),
            ),
            backgroundColor: LegoColors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao atualizar perfil: $e',
              style: GoogleFonts.varelaRound(fontWeight: FontWeight.bold),
            ),
            backgroundColor: LegoColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LegoColors.blue,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar com botão de voltar e Título
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              leadingWidth: 56,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
                child: LegoBlockDecorator(
                  color: Colors.yellow,
                  borderRadius: 10,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: LegoColors.blueDark,
                      size: 22,
                    ),
                  ),
                ),
              ),
              title: Text(
                'EDITAR PERFIL',
                style: GoogleFonts.coiny(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Formulário Principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LegoColors.blueDark, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, offset: Offset(3, 3), blurRadius: 3),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo: Username*
                        _buildInputField(
                          controller: _usernameController,
                          label: 'Username *',
                          icon: Icons.alternate_email,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'O username é obrigatório';
                            }
                            if (value.trim().length < 3) {
                              return 'O username deve ter pelo menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo: Nome*
                        _buildInputField(
                          controller: _nomeController,
                          label: 'Nome *',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'O nome é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo: Email* (NÃO EDITÁVEL)
                        _buildInputField(
                          controller: _emailController,
                          label: 'E-mail * (Não editável)',
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),

                        // Campo: Data de Nascimento
                        _buildDatePickerField(),
                        const SizedBox(height: 16),

                        // Campo: Sexo
                        _buildDropdownSexo(),
                        const SizedBox(height: 16),

                        // Campo: ID LEGO Insiders
                        _buildInputField(
                          controller: _legoInsidersController,
                          label: 'ID LEGO Insiders',
                          icon: Icons.card_membership_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 28),

                        // Botão de Guardar
                        LegoBlockDecorator(
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
                                    'GUARDAR ALTERAÇÕES',
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper genérico para criar TextFormFields estilizados
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.varelaRound(
          color: enabled ? LegoColors.blueDark : Colors.grey[500],
        ),
        prefixIcon: Icon(icon, color: enabled ? LegoColors.blueDark : Colors.grey[400]),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.blueDark, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.blueDark, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.red, width: 2),
        ),
      ),
    );
  }

  /// Widget do Seletor de Data de Nascimento
  Widget _buildDatePickerField() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final textoData = _dataNascimento != null
        ? dateFormat.format(_dataNascimento!)
        : 'Selecionar data';

    return InkWell(
      onTap: _selecionarDataNascimento,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data de Nascimento',
          labelStyle: GoogleFonts.varelaRound(color: LegoColors.blueDark),
          prefixIcon: const Icon(Icons.cake_outlined, color: LegoColors.blueDark),
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
          ),
        ),
        child: Text(
          textoData,
          style: GoogleFonts.varelaRound(
            color: _dataNascimento != null ? LegoColors.blueDark : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Widget do Dropdown para Seleção de Sexo
  Widget _buildDropdownSexo() {
    return DropdownButtonFormField<String>(
      initialValue: _sexoSelecionado,
      icon: const Icon(Icons.arrow_drop_down, color: LegoColors.blueDark),
      decoration: InputDecoration(
        labelText: 'Sexo',
        labelStyle: GoogleFonts.varelaRound(color: LegoColors.blueDark),
        prefixIcon: const Icon(Icons.people_outline, color: LegoColors.blueDark),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LegoColors.blueDark, width: 2.5),
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
}