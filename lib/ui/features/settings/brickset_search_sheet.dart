import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/brickset_settings.dart';
import '../../../l10n/generated/app_localizations.dart';
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
  int _matches = 0;
  int _pagina = 1;
  bool _aPesquisar = false;
  bool _aCarregarMais = false;
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
    final t = AppLocalizations.of(context)!;

    final service = ref.read(bricksetServiceProvider);
    if (service == null) {
      setState(() => _erro =
      t.noAPIKEY);
      return;
    }
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _aPesquisar = true;
      _erro = null;
      _pagina = 1;
    });

    try {
      final resultado = await service.search(query, pageNumber: 1);
      if (!mounted) return;
      setState(() {
        _resultados = resultado.sets;
        _matches = resultado.matches;
      });
    } on BricksetException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _aPesquisar = false);
    }
  }

  Future<void> _carregarMais() async {
    final service = ref.read(bricksetServiceProvider);
    if (service == null) return;
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _aCarregarMais = true);
    try {
      final proximaPagina = _pagina + 1;
      final resultado = await service.search(query, pageNumber: proximaPagina);
      if (!mounted) return;
      setState(() {
        _resultados = [...?_resultados, ...resultado.sets];
        _matches = resultado.matches;
        _pagina = proximaPagina;
      });
    } on BricksetException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _aCarregarMais = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alturaDisponivel = MediaQuery.of(context).size.height * 0.85;
    final t = AppLocalizations.of(context)!;

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
                      decoration: InputDecoration(
                        labelText: t.labelNumber,
                        hintText: t.labelNumberHint,
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

    final t = AppLocalizations.of(context)!;

    if (_aPesquisar && _resultados == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final resultados = _resultados;
    if (resultados == null) {
      return  Center(child: Text(t.searchResultLabel));
    }
    if (resultados.isEmpty) {
      return Center(child: Text(t.searchNoResults));
    }

    final temMais = resultados.length < _matches;

    return ListView.separated(
      itemCount: resultados.length + 1, // +1 para o cabeçalho com o total
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.resultsMatches(_matches),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final s = resultados[i - 1];
        final ultimoItem = i - 1 == resultados.length - 1;
        return Column(
          children: [
            ListTile(
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
                if (s.pieces != null)  t.pecas(s.pieces.toString()),
              ].join(' · ')),
              onTap: () => Navigator.of(context).pop(s),
            ),
            if (ultimoItem && temMais)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _aCarregarMais
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                  onPressed: _carregarMais,
                  child: Text(t.loadMore),
                ),
              ),
          ],
        );
      },
    );
  }
}