import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import 'edit_set_screen.dart';



class SetsListScreen extends ConsumerWidget {
  const SetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(todosOsSetsProvider);
    final euro = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Scaffold(
      appBar: AppBar(title: const Text('Os meus sets')),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro a carregar: $e')),
        data: (sets) {
          if (sets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não tens nenhum set registado.\n'
                  'Importa o teu xlsx ou adiciona um manualmente com o botão "+".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: sets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
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
                child: ListTile(
                  leading: CircleAvatar(child: Text(set.tema.characters.first)),
                  title: Text('${set.numeroSet} — ${set.descricao}'),
                  subtitle: Text(
                    '${set.tema} · ${euro.format(set.valorComprado)}'
                    '${set.vendido ? ' · vendido' : ''}',
                  ),
                  trailing: set.vendido
                      ? Icon(Icons.sell, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditSetScreen(set: set)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditSetScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmarApagar(BuildContext context, LegoSet set) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar set?'),
        content: Text('Vais apagar "${set.numeroSet} — ${set.descricao}". Não dá para desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }
}
