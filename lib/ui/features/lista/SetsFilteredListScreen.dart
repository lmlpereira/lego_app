import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lego_app/ui/features/lista/edit_set_screen_new.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import 'edit_set_screen.dart';

final _moeda = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
final _data = DateFormat('dd/MM/yyyy');

/// Ecrã de lista reutilizável, usado a partir do dashboard (ex: sets de
/// um ano, de um tema, ou todos os vendidos). Recebe um [filtro] em vez
/// de uma lista já calculada, e observa `todosOsSetsProvider` — assim
/// fica sempre atualizado (ex: depois de editares ou apagares um set
/// aqui dentro, a lista reflete isso de imediato, tal como a lista
/// principal).
class SetsFilteredListScreen extends ConsumerStatefulWidget {
  final String titulo;
  final bool Function(LegoSet) filtro;

  const SetsFilteredListScreen({
    super.key,
    required this.titulo,
    required this.filtro,
  });

  @override
  ConsumerState<SetsFilteredListScreen> createState() =>
      _SetsFilteredListScreenState();
}

class _SetsFilteredListScreenState extends ConsumerState<SetsFilteredListScreen> {
  final _pesquisaCtrl = TextEditingController();
  String _pesquisa = '';

  @override
  void dispose() {
    _pesquisaCtrl.dispose();
    super.dispose();
  }

  bool _correspondePesquisa(LegoSet s) {
    if (_pesquisa.isEmpty) return true;
    final termo = _pesquisa.toLowerCase();
    return s.numeroSet.toString().contains(termo) ||
        s.descricao.toLowerCase().contains(termo);
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(todosOsSetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _pesquisaCtrl,
              onChanged: (v) => setState(() => _pesquisa = v),
              decoration: InputDecoration(
                hintText: 'Pesquisar por número ou nome...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _pesquisa.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _pesquisaCtrl.clear();
                    setState(() => _pesquisa = '');
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro a carregar: $e')),
        data: (todos) {
          final sets = todos
              .where(widget.filtro)
              .where(_correspondePesquisa)
              .toList();

          if (sets.isEmpty) {
            return Center(
              child: Text(
                _pesquisa.isEmpty
                    ? 'Nenhum set encontrado.'
                    : 'Nenhum set corresponde a "$_pesquisa".',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${sets.length} ${sets.length == 1 ? 'set' : 'sets'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: sets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final set = sets[i];
                    return _LinhaSet(
                      set: set,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditSetScreenNew(set: set)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LinhaSet extends StatelessWidget {
  final LegoSet set;
  final VoidCallback onTap;

  const _LinhaSet({required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final detalhes = <String>[
      set.tema,
      if (set.dataCompra != null) 'comprado em ${_data.format(set.dataCompra!)}',
      if (set.quantidade > 1) 'x${set.quantidade}',
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      title: Text('${set.numeroSet} — ${set.descricao}'),
      subtitle: Text(detalhes),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_moeda.format(set.valorComprado)),
          if (set.vendido)
            Text(
              set.valorVenda != null
                  ? 'Vendido: ${_moeda.format(set.valorVenda!)}'
                  : 'Vendido',
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
        ],
      ),
    );
  }
}