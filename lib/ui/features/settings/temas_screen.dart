import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/utils/lego_brick_loading.dart';

import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Ecrã "Gerir temas" (Definições): mostra todos os temas com o número
/// de sets de cada um, e permite apagar os que estiverem a zero — um
/// tema com sets associados não pode ser apagado (evita ficares com
/// sets "órfãos" sem tema).
class TemasScreen extends ConsumerWidget {
  const TemasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temasAsync = ref.watch(temasComContagemProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsManageThemes)),
      body: temasAsync.when(
        loading: () => const Center(child: LegoBrickLoading()),
        error: (e, _) => Center(child: Text(t.themesErrorLoading(e.toString()))),
        data: (temas) {
          if (temas.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(t.themesEmpty, textAlign: TextAlign.center),
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
                  vazio ? t.themesNoSets : t.themesSetCount(tema.quantidade),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: vazio
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).disabledColor,
                  ),
                  tooltip: vazio
                      ? t.themesDeleteTooltip
                      : t.themesDeleteDisabledTooltip,
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
    final t = AppLocalizations.of(context)!;

    if (tema.quantidade > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            t.themesDeleteBlockedMessage(tema.nome, tema.quantidade)),
      ));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.themesConfirmDeleteTitle),
        content: Text(t.themesConfirmDeleteBody(tema.nome)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(t.commonDelete),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final apagado = await ref.read(setsRepositoryProvider).apagarTema(tema.temaId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(apagado
          ? t.themesDeletedMessage(tema.nome)
          : t.themesDeleteRaceMessage),
    ));
  }
}
