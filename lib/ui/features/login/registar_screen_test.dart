import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _ocultarPassword = true;
  bool _aRegistar = false;
  String? _erro;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _registar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _aRegistar = true;
      _erro = null;
    });
    try {
      await ref.read(authRepositoryProvider).registarComEmail(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      // O AuthGate trata da navegação assim que a sessão fica ativa.
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _aRegistar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome de utilizador',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Palavra-passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmarCtrl,
                  obscureText: _ocultarPassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar palavra-passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                  (v != _passwordCtrl.text) ? 'As palavras-passe não coincidem' : null,
                  onFieldSubmitted: (_) => _registar(),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _aRegistar ? null : _registar,
                  child: _aRegistar
                      ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}