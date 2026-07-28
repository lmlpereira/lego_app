import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Mostra o fluxo completo de apagar conta: aviso de irreversibilidade
/// -> reautenticação (palavra-passe ou Google, consoante como a pessoa
/// entrou) -> apagar. Chamável a partir de qualquer botão, em qualquer
/// ecrã (Definições, Perfil, ...) — só precisa de context e ref.
Future<void> showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context)!;

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.titleDeleteAccount),
      content: Text(t.contentDeleteAccount),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: Text(t.commonContinuar),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return;

  final apagou = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _ConfirmarEApagarDialog(),
  );

  if (apagou == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.resultDeleteAccount)),
    );
  }
}

class _ConfirmarEApagarDialog extends ConsumerStatefulWidget {
  const _ConfirmarEApagarDialog();

  @override
  ConsumerState<_ConfirmarEApagarDialog> createState() => _ConfirmarEApagarDialogState();
}

class _ConfirmarEApagarDialogState extends ConsumerState<_ConfirmarEApagarDialog> {
  final _passwordCtrl = TextEditingController();
  bool _aProcessar = false;
  String? _erro;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _usaPassword =>
      ref.read(authRepositoryProvider).provedoresAtuais.contains('password');

  Future<void> _confirmarEApagar() async {
    final repo = ref.read(authRepositoryProvider);
    final t = AppLocalizations.of(context)!;

    if (_usaPassword && _passwordCtrl.text.isEmpty) {
      setState(() => _erro = t.writePassword);
      return;
    }

    setState(() {
      _aProcessar = true;
      _erro = null;
    });

    try {
      if (_usaPassword) {
        await repo.reautenticarComPassword(_passwordCtrl.text);
      } else {
        await repo.reautenticarComGoogle();
      }
      await repo.apagarConta();
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _aProcessar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(t.confirmIsYou),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _usaPassword
                ? t.secPass
                : t.secGoogle,
          ),
          if (_usaPassword) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: t.passwordLabel),
              onSubmitted: (_) => _confirmarEApagar(),
            ),
          ],
          if (_erro != null) ...[
            const SizedBox(height: 8),
            Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _aProcessar ? null : () => Navigator.of(context).pop(false),
          child: Text(t.commonCancel),
        ),
        FilledButton(
          onPressed: _aProcessar ? null : _confirmarEApagar,
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: _aProcessar
              ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_usaPassword ? t.cPass : t.cGoogle),
        ),
      ],
    );
  }
}