import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database.dart';
import '../../../data/providers.dart';

/// Ecrã "Gerir temas" (Definições): mostra todos os temas com o número
/// de sets de cada um, e permite apagar os que estiverem a zero — um
/// tema com sets associados não pode ser apagado (evita ficares com
/// sets "órfãos" sem tema).
class TemasScreen extends ConsumerWidget {
  const TemasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temasAsync = ref.watch(temasComContagemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gerir temas')),
      body: temasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro a carregar temas: $e')),
        data: (temas) {
          if (temas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ainda não tens nenhum tema criado.', textAlign: TextAlign.center),
              ),
            );
          }

          return ListView.separated(
            itemCount: temas.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final tema = temas[i];
              final vazio = tema.quantidade == 0;

              return ListTile(
                title: Text(tema.nome),
                subtitle: Text(
                  vazio ? 'Nenhum set' : '${tema.quantidade} set${tema.quantidade == 1 ? '' : 's'}',
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: vazio
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).disabledColor,
                  ),
                  tooltip: vazio
                      ? 'Apagar tema'
                      : 'Não é possível apagar: ainda tem sets associados',
                  onPressed: () => _tocarApagar(context, ref, tema),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _tocarApagar(BuildContext context, WidgetRef ref, TemaComContagem tema) async {
    if (tema.quantidade > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'O tema "${tema.nome}" tem ${tema.quantidade} set${tema.quantidade == 1 ? '' : 's'} — '
                'muda-lhes o tema antes de o apagar.'),
      ));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar tema?'),
        content: Text('Vais apagar o tema "${tema.nome}". Não dá para desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final apagado = await ref.read(setsRepositoryProvider).apagarTema(tema.temaId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(apagado
          ? 'Tema "${tema.nome}" apagado.'
          : 'Não foi possível apagar — o tema deixou de estar vazio entretanto.'),
    ));
  }
}
