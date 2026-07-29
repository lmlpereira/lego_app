import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/utils/lego_set_card.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'edit_set_screen_new.dart';

class SetsListScreenNew extends ConsumerStatefulWidget {
  const SetsListScreenNew({super.key});

  @override
  ConsumerState<SetsListScreenNew> createState() => _SetsListScreenStateNew();
}

class _SetsListScreenStateNew extends ConsumerState<SetsListScreenNew> {
  final _pesquisaCtrl = TextEditingController();
  String _pesquisa = '';
  // null = sem filtro de tema (mostra todos)
  String? _temaFiltro;

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

  bool _correspondeTema(LegoSet s) => _temaFiltro == null || s.tema == _temaFiltro;

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(todosOsSetsProvider);
    final temasAsync = ref.watch(temasProvider);
    //final euro = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.mysetsScreenTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _pesquisaCtrl,
                  onChanged: (v) => setState(() => _pesquisa = v),
                  decoration: InputDecoration(
                    hintText: t.mysetsScreenSearch,
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
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: temasAsync.when(
                    data: (temas) => _filtroTemas(temas),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.mysetsScreenLoadingError(e))),
        data: (todosOsSets) {
          if (todosOsSets.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(t.mysetsScreenNoData,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sets = todosOsSets
              .where(_correspondePesquisa)
              .where(_correspondeTema)
              .toList();

          if (sets.isEmpty) {
            return  Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  t.mysetsScreenNoDataFilter,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: sets.length,
            //separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final set = sets[i];

              return Dismissible(
                  key: ValueKey(set.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  confirmDismiss: (_) => _confirmarApagar(context, set),
                  onDismissed: (_) => ref.read(setsRepositoryProvider).delete(set.id!),
                  child:LegoSetCard(
                legoSet: set,
                onTap: ()  {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditSetScreenNew(set: set)),
                  );
                },
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditSetScreenNew()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Fila horizontal de chips para filtrar por tema — "Todos" mais um
  /// chip por cada tema já existente na coleção.
  Widget _filtroTemas(List<String> temas) {
    final t = AppLocalizations.of(context)!;

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(t.mysetsScreenFilterAll),
            selected: _temaFiltro == null,
            onSelected: (_) => setState(() => _temaFiltro = null),
          ),
        ),
        for (final tema in temas)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(tema),
              selected: _temaFiltro == tema,
              onSelected: (_) => setState(
                      () => _temaFiltro = _temaFiltro == tema ? null : tema),
            ),
          ),
      ],
    );
  }

  Future<bool> _confirmarApagar(BuildContext context, LegoSet set) async {

    final t = AppLocalizations.of(context)!;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.mysetsScreenDialogDeleteTitle),
        content: Text(t.mysetsScreenDialogDeleteContent(set.descricao, set.numeroSet)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(t.commonDelete),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }
}