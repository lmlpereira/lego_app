import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/brickset_settings.dart';
import '../../../services/brickset_service.dart';

/// Abre uma folha modal para pesquisar sets no Brickset (por número, nome,
/// tema...) e devolve o set escolhido, ou `null` se o utilizador cancelar.
Future<BricksetSet?> showBricksetSearchSheet(
    BuildContext context, WidgetRef ref, {String queryInicial = ''}) {
  return showModalBottomSheet<BricksetSet>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BricksetSearchSheet(queryInicial: queryInicial),
  );
}

class _BricksetSearchSheet extends ConsumerStatefulWidget {
  final String queryInicial;
  const _BricksetSearchSheet({required this.queryInicial});

  @override
  ConsumerState<_BricksetSearchSheet> createState() => _BricksetSearchSheetState();
}

class _BricksetSearchSheetState extends ConsumerState<_BricksetSearchSheet> {
  late final TextEditingController _queryCtrl;
  List<BricksetSet>? _resultados;
  bool _aPesquisar = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.queryInicial);
    if (widget.queryInicial.trim().isNotEmpty) {
      // Dispara a pesquisa inicial já com o número/nome escrito no formulário.
      WidgetsBinding.instance.addPostFrameCallback((_) => _pesquisar());
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pesquisar() async {
    final service = ref.read(bricksetServiceProvider);
    if (service == null) {
      setState(() => _erro =
      'Falta configurar a API key do Brickset (ícone de definições no ecrã anterior).');
      return;
    }
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _aPesquisar = true;
      _erro = null;
    });

    try {
      final resultados = await service.search(query);
      if (!mounted) return;
      setState(() => _resultados = resultados);
    } on BricksetException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _aPesquisar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alturaDisponivel = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: alturaDisponivel,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      autofocus: widget.queryInicial.trim().isEmpty,
                      decoration: const InputDecoration(
                        labelText: 'Número ou nome do set',
                        hintText: 'ex: 75894 ou Millennium Falcon',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _pesquisar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _aPesquisar ? null : _pesquisar,
                    child: _aPesquisar
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Expanded(child: _corpo()),
          ],
        ),
      ),
    );
  }

  Widget _corpo() {
    if (_aPesquisar && _resultados == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final resultados = _resultados;
    if (resultados == null) {
      return const Center(child: Text('Escreve algo e pesquisa.'));
    }
    if (resultados.isEmpty) {
      return const Center(child: Text('Nenhum set encontrado.'));
    }
    return ListView.separated(
      itemCount: resultados.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = resultados[i];
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: s.thumbnailUrl != null
                ? Image.network(
              s.thumbnailUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
            )
                : const Icon(Icons.image_not_supported),
          ),
          title: Text('${s.numeroCompleto} — ${s.name}'),
          subtitle: Text([
            if (s.theme.isNotEmpty) s.theme,
            if (s.year != null) '${s.year}',
            if (s.pieces != null) '${s.pieces} peças',
          ].join(' · ')),
          onTap: () => Navigator.of(context).pop(s),
        );
      },
    );
  }
}