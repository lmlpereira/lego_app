import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import 'profile_form_fields.dart';

/// Mostrado pelo AuthGate quando há sessão ativa mas ainda não há
/// username (normalmente logo a seguir a um primeiro "Entrar com
/// Google" — o Google não dá um username, só nome/email/foto).
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nomeCtrl;
  final _idLegoInsidersCtrl = TextEditingController();

  DateTime? _dataNascimento;
  String? _sexo;
  bool _aGuardar = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Pré-preenche o nome com o que o Google já sabe — poupa trabalho,
    // a pessoa só tem mesmo de escolher o username.
    final nomeGoogle = fb.FirebaseAuth.instance.currentUser?.displayName ?? '';
    _usernameCtrl = TextEditingController();
    _nomeCtrl = TextEditingController(text: nomeGoogle);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nomeCtrl.dispose();
    _idLegoInsidersCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _aGuardar = true;
      _erro = null;
    });
    try {
      await ref.read(authRepositoryProvider).completarPerfil(
        username: _usernameCtrl.text,
        nome: _nomeCtrl.text,
        dataNascimento: _dataNascimento,
        idLegoInsiders: _idLegoInsidersCtrl.text,
        sexo: _sexo,
      );
      // O AuthGate só reage a mudanças no *estado de sessão* (login/
      // logout), não a alterações no documento de perfil — a sessão não
      // mudou aqui, só o perfil. Por isso forçamos o provider a
      // reler o utilizador, o que faz o AuthGate avançar para a
      // HomeShell assim que perfilIncompleto passar a false.
      ref.invalidate(utilizadorAtualProvider);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeShell()),
              (route) => false,
        );
      }

    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _aGuardar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = fb.FirebaseAuth.instance.currentUser?.email;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.titleCompleteProfile), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.subtitleCompleteProfile(email != null ? ' ($email)' : ''),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                ProfileFormFields(
                  usernameCtrl: _usernameCtrl,
                  nomeCtrl: _nomeCtrl,
                  idLegoInsidersCtrl: _idLegoInsidersCtrl,
                  dataNascimento: _dataNascimento,
                  onDataNascimentoChanged: (d) => setState(() => _dataNascimento = d),
                  sexo: _sexo,
                  onSexoChanged: (s) => setState(() => _sexo = s),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _aGuardar ? null : _guardar,
                  child: _aGuardar
                      ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.concluir),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}