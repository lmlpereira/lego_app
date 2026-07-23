import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/brickset_settings.dart';
import '../../../services/brickset_service.dart';

const _urlPedirChave = 'https://brickset.com/tools/webservices/requestkey';

/// Abre um diálogo para o utilizador colocar (ou apagar) a sua API key do
/// Brickset. A key é pedida aqui: https://brickset.com/tools/webservices/requestkey
Future<void> showBricksetApiKeyDialog(BuildContext context, WidgetRef ref) async {
  final apiKeyAtual =
      await ref.read(bricksetApiKeyProvider.notifier).obterQuandoPronto() ?? '';
  if (!context.mounted) return;
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
  bool _aGuardar = false;
  String? _resultado;
  bool? _valida;
  // Valor exato que foi verificado pela última vez — permite perceber
  // que o resultado ficou desatualizado assim que o texto muda.
  String? _chaveVerificada;
  bool _oculto = true;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.apiKeyAtual);
    _ctrl.addListener(_aoMudarTexto);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_aoMudarTexto);
    _ctrl.dispose();
    super.dispose();
  }

  void _aoMudarTexto() {
    // O resultado de "válida"/"inválida" só é válido para o texto que foi
    // efetivamente verificado — assim que o utilizador mexe no campo,
    // deixa de fazer sentido continuar a mostrá-lo.
    final mudou = _chaveVerificada != null && _ctrl.text.trim() != _chaveVerificada;
    setState(() {
      if (mudou) {
        _resultado = null;
        _valida = null;
      }
      // setState sem alterações adicionais serve só para o botão
      // Verificar/Guardar reagir ao campo estar vazio ou não.
    });
  }

  Future<bool> _verificar() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return false;

    setState(() {
      _aVerificar = true;
      _resultado = null;
      _valida = null;
    });

    final service = BricksetService(apiKey: key);
    final ok = await service.checkKey();
    service.dispose();
    _chaveVerificada = key;

    if (!mounted) return ok;
    setState(() {
      _aVerificar = false;
      _valida = ok;
      _resultado = ok ? 'API key válida.' : 'API key inválida.';
    });
    return ok;
  }

  Future<void> _guardar() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;

    setState(() => _aGuardar = true);

    // Se ainda não sabemos se esta chave (exata) é válida, verifica
    // antes de gravar — evita gravares por engano uma key com um erro
    // de dedo sem dares por isso até à próxima pesquisa.
    if (_valida != true || _chaveVerificada != key) {
      final ok = await _verificar();
      if (!ok && mounted) {
        final continuar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chave possivelmente inválida'),
            content: const Text(
                'Não consegui confirmar esta chave junto do Brickset. '
                    'Queres guardá-la mesmo assim?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar na mesma'),
              ),
            ],
          ),
        );
        if (continuar != true) {
          if (mounted) setState(() => _aGuardar = false);
          return;
        }
      }
    }

    if (!mounted) return;
    await ref.read(bricksetApiKeyProvider.notifier).guardar(key);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _colar() async {
    final dados = await Clipboard.getData('text/plain');
    final texto = dados?.text?.trim();
    if (texto == null || texto.isEmpty) return;
    _ctrl.text = texto;
    _ctrl.selection = TextSelection.collapsed(offset: texto.length);
  }

  Future<void> _copiarLink() async {
    await Clipboard.setData(const ClipboardData(text: _urlPedirChave));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado.'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vazio = _ctrl.text.trim().isEmpty;

    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('API key do Brickset'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Precisas de uma API key gratuita para ir buscar dados de sets '
                'ao Brickset (nome, tema, peças, imagem, ...). Pede uma aqui '
                '(toca para copiar o link):',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: _copiarLink,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _urlPedirChave,
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.copy, size: 14, color: Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _oculto,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'API key',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Colar',
                    icon: const Icon(Icons.content_paste, size: 20),
                    onPressed: _colar,
                  ),
                  IconButton(
                    tooltip: _oculto ? 'Mostrar' : 'Ocultar',
                    icon: Icon(
                      _oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  ),
                ],
              ),
            ),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _valida == true ? Icons.check_circle : Icons.error_outline,
                  size: 16,
                  color: _valida == true ? Colors.green : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  _resultado!,
                  style: TextStyle(
                    color: _valida == true ? Colors.green : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // Grupo esquerdo: ações utilitárias (não fecham o diálogo,
        // exceto Remover).
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: (_aVerificar || vazio) ? null : _verificar,
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
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Remover'),
              ),
          ],
        ),
        // Grupo direito: ações principais (cancelar / confirmar).
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: (_aGuardar || vazio) ? null : _guardar,
              child: _aGuardar
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }
}