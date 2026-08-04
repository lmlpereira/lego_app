import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/barcode/set_found_sheet.dart';

import '../../../data/brickset_settings.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import '../../../services/brickset_service.dart';
import '../settings/brickset_api_key_dialog.dart';
import 'barcode_scanner_screen.dart';



/// Ponto de entrada único do fluxo de scan. Chama isto a partir de um
/// botão (FAB, ícone na AppBar, etc).
///
/// [onSetNaoEncontrado] é chamado quando o set lido AINDA NÃO está na
/// coleção e o utilizador carrega em "Adicionar à coleção". É o teu
/// ponto de integração com o ecrã "Novo Set" que já tens (o que usa
/// BricksetService.search para autocomplete) — usa-o para abrir esse
/// ecrã pré-preenchido com os dados do [BricksetSet] recebido, para o
/// utilizador só ter de indicar valor pago / data de compra.
///
/// Se não passares [onSetNaoEncontrado], o set é adicionado de imediato
/// à coleção com valores por omissão (valorComprado: 0, quantidade: 1,
/// data de hoje) — fica a residir logo na lista, mas vais ter de editar
/// esses campos financeiros manualmente depois.
///
/// Exemplo de uso (com o teu ecrã de novo set):
///
/// floatingActionButton: FloatingActionButton(
///   onPressed: () => iniciarFluxoDeScan(
///     context,
///     ref,
///     onSetNaoEncontrado: (set) => Navigator.push(
///       context,
///       MaterialPageRoute(builder: (_) => NovoSetScreen.fromBrickset(set)),
///     ),
///   ),
///   child: const Icon(Icons.qr_code_scanner),
/// ),
Future<void> iniciarFluxoDeScan(
    BuildContext context,
    WidgetRef ref, {
      void Function(BricksetSet set)? onSetNaoEncontrado,
    }) async {
  // Verifica a API key ANTES de abrir a câmara — não faz sentido pedir
  // ao utilizador para apontar e ler um código só para, no fim, lhe
  // dizermos que falta configurar a key.
  final brickset = await obterBricksetServiceQuandoPronto(ref);
  if (brickset == null) {
    if (!context.mounted) return;
    final configurar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API key do Brickset em falta'),
        content: const Text(
          'Para identificar sets pelo código de barras precisas de configurar '
              'a tua API key do Brickset em Definições. Queres configurar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
    if (configurar == true && context.mounted) {
      await showBricksetApiKeyDialog(context, ref);
    }
    return;
  }

  final code = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
  );
  if (code == null || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final set = await brickset.getByBarcode(code);

    if (!context.mounted) return;
    Navigator.pop(context); // fecha o loading

    if (set == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Não foi possível identificar este set. Tenta pesquisar manualmente.',
        ),
      ));
      return;
    }

    // Comparação por número: o teu numeroSet é int e não inclui a
    // variante (-1), tal como set.number (só a parte base do Brickset).
    final numeroProcurado = int.tryParse(set.number);
    final todos = await ref.read(todosOsSetsProvider.future);
    final jaTenho = numeroProcurado != null &&
        todos.any((s) => s.numeroSet == numeroProcurado);

    if (!context.mounted) return;

    await SetFoundSheet.show(
      context,
      set: set,
      jaNaColecao: jaTenho,
      onAdicionar: jaTenho
          ? null
          : () => _adicionar(context, ref, set, onSetNaoEncontrado),
    );
  } on BricksetException catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro inesperado ao consultar o Brickset.')),
    );
  } finally {
    // Este service é criado ad-hoc (não vem de um provider gerido pelo
    // Riverpod, ver obterBricksetServiceQuandoPronto), por isso temos de
    // o fechar nós, senão a ligação http fica aberta.
    brickset.dispose();
  }
}

void _adicionar(
    BuildContext context,
    WidgetRef ref,
    BricksetSet set,
    void Function(BricksetSet set)? onSetNaoEncontrado,
    ) {
  if (onSetNaoEncontrado != null) {
    onSetNaoEncontrado(set);
    return;
  }

  // Fallback sem ecrã de "Novo Set" ligado: insere já com valores por
  // omissão. Substitui isto passando onSetNaoEncontrado quando ligares
  // ao teu formulário real.
  final numero = int.tryParse(set.number);
  if (numero == null) return;

  ref.read(setsRepositoryProvider).add(LegoSet(
    numeroSet: numero,
    tema: set.theme.isNotEmpty ? set.theme : 'Sem tema',
    descricao: set.descricaoSugerida,
    ano: set.year,
    valorSet: set.precoSugeridoEUR ?? 0,
    valorComprado: 0,
    dataCompra: DateTime.now(),
    quantidade: 1,
    imagemUrl: set.imageUrl ?? set.thumbnailUrl,
    pecas: set.pieces,
  ));

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('${set.name} adicionado — edita o valor pago quando puderes'),
  ));
}