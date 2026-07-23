import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/brickset_settings.dart';
import '../../../services/brickset_service.dart';

/// Abre um diálogo para o utilizador colocar (ou apagar) a sua API key do
/// Brickset. A key é pedida aqui: https://brickset.com/tools/webservices/requestkey
Future<void> showBricksetApiKeyDialog(BuildContext context, WidgetRef ref) {
  final apiKeyAtual = ref.read(bricksetApiKeyProvider).value ?? '';
  return showDialog(
    context: context,
    builder: (context) => _BricksetApiKeyDialog(apiKeyAtual: apiKeyAtual),
  );
}

class _BricksetApiKeyDialog extends ConsumerStatefulWidget {
  final String apiKeyAtual;
  const _BricksetApiKeyDialog({required this.apiKeyAtual});

  @override
  ConsumerState<_BricksetApiKeyDialog> createState() => _BricksetApiKeyDialogState();
}

class _BricksetApiKeyDialogState extends ConsumerState<_BricksetApiKeyDialog> {
  late final TextEditingController _ctrl;
  bool _aVerificar = false;
  String? _resultado;
  bool? _valida;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.apiKeyAtual);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _aVerificar = true;
      _resultado = null;
      _valida = null;
    });
    final service = BricksetService(apiKey: key);
    final ok = await service.checkKey();
    service.dispose();
    if (!mounted) return;
    setState(() {
      _aVerificar = false;
      _valida = ok;
      _resultado = ok ? 'API key válida.' : 'API key inválida.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('API key do Brickset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Precisas de uma API key gratuita para ir buscar dados de sets '
                'ao Brickset (nome, tema, peças, imagem, ...). Pede uma aqui:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          const SelectableText(
            'https://brickset.com/tools/webservices/requestkey',
            style: TextStyle(fontSize: 13, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'API key',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 8),
            Text(
              _resultado!,
              style: TextStyle(
                color: _valida == true ? Colors.green : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _aVerificar ? null : _verificar,
          child: _aVerificar
              ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verificar'),
        ),
        if (widget.apiKeyAtual.isNotEmpty)
          TextButton(
            onPressed: () async {
              await ref.read(bricksetApiKeyProvider.notifier).limpar();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Remover'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final key = _ctrl.text.trim();
            if (key.isEmpty) return;
            await ref.read(bricksetApiKeyProvider.notifier).guardar(key);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}