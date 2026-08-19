import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/barcode/set_found_sheet.dart';

import '../../../data/brickset_settings.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import '../../../services/brickset_service.dart';
import '../../../services/upc_lookup_service.dart';
import '../settings/brickset_api_key_dialog.dart';
import '../settings/brickset_search_sheet.dart';
import 'barcode_scanner_screen.dart';



/// Ponto de entrada único do fluxo de scan. Chama isto a partir de um
/// botão (FAB, ícone na AppBar, etc).
///
/// Como não dá para pesquisar sets por código de barras nem na Brickset
/// nem na Rebrickable (só devolvem o EAN/UPC quando já sabes o set, não
/// permitem pesquisar por ele), o fluxo tem sempre dois passos:
///   1. UpcLookupService traduz o código lido num nome de produto (ex:
///      "LEGO Star Wars Millennium Falcon 75192") e extrai números
///      candidatos a número de set.
///   2. Cada candidato é confirmado com BricksetService.getBySetNumber —
///      prioriza-se o candidato cujo EAN/UPC oficial bate certo com o
///      código lido (ver BricksetSet.correspondeAoCodigo); se nenhum
///      bater certo, usa-se o primeiro candidato que a Brickset reconheça.
/// Se nada disto resultar (produto desconhecido da UPCitemdb, ou nenhum
/// candidato reconhecido pela Brickset), cai-se para a pesquisa manual
/// já existente, pré-preenchida com o que foi encontrado.
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

  final upcLookup = UpcLookupService();
  try {
    final identificacao = await _identificarSet(brickset, upcLookup, code);

    if (!context.mounted) return;
    Navigator.pop(context); // fecha o loading

    if (identificacao.set == null) {
      // Não conseguimos identificar o set sozinhos — cai para a pesquisa
      // manual já existente. Se a UPCitemdb pelo menos reconheceu o
      // produto, pré-preenche a pesquisa com o nome dele (poupa ao
      // utilizador ter de escrever); senão fica vazia.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível identificar este set automaticamente. Tenta pesquisar manualmente.'),
      ));
      final escolhido = await showBricksetSearchSheet(
        context,
        ref,
        queryInicial: identificacao.tituloProduto ?? '',
      );
      if (escolhido == null || !context.mounted) return;
      await _mostrarResultado(context, ref, escolhido, onSetNaoEncontrado);
      return;
    }

    await _mostrarResultado(context, ref, identificacao.set!, onSetNaoEncontrado);
  } on BricksetException catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } on UpcLookupException catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro inesperado ao identificar o set.')),
    );
  } finally {
    // Estes services são criados ad-hoc (não vêm de providers geridos
    // pelo Riverpod), por isso temos de os fechar nós, senão as ligações
    // http ficam abertas.
    brickset.dispose();
    upcLookup.dispose();
  }
}

/// Resultado interno de [_identificarSet]: o set confirmado no Brickset
/// (se algum candidato bateu certo), mais o título do produto devolvido
/// pela UPCitemdb (para pré-preencher a pesquisa manual se nada bater
/// certo — evita uma segunda chamada à UPCitemdb só para isso).
class _Identificacao {
  final BricksetSet? set;
  final String? tituloProduto;
  const _Identificacao({this.set, this.tituloProduto});
}

/// Traduz o código de barras num set do Brickset, em dois passos (ver
/// doc de [iniciarFluxoDeScan]).
Future<_Identificacao> _identificarSet(
    BricksetService brickset,
    UpcLookupService upcLookup,
    String code,
    ) async {
  final lookup = await upcLookup.procurar(code);
  if (lookup == null || lookup.candidatosNumeroSet.isEmpty) {
    return _Identificacao(tituloProduto: lookup?.titulo);
  }

  BricksetSet? primeiroValido;
  for (final candidato in lookup.candidatosNumeroSet) {
    final set = await brickset.getBySetNumber(candidato);
    if (set == null) continue;

    // Melhor caso: o EAN/UPC oficial deste set bate certo com o código
    // lido — confiança máxima, para de procurar já.
    if (set.correspondeAoCodigo(code)) {
      return _Identificacao(set: set, tituloProduto: lookup.titulo);
    }

    // Guarda o primeiro candidato válido como rede de segurança, caso
    // nenhum bata certo pelo código (a Brickset nem sempre tem o
    // EAN/UPC preenchido para todos os sets).
    primeiroValido ??= set;
  }
  return _Identificacao(set: primeiroValido, tituloProduto: lookup.titulo);
}

Future<void> _mostrarResultado(
    BuildContext context,
    WidgetRef ref,
    BricksetSet set,
    void Function(BricksetSet set)? onSetNaoEncontrado,
    ) async {
  // Comparação por número: o teu numeroSet é int e não inclui a
  // variante (-1), tal como set.number (só a parte base do Brickset).
  final numeroProcurado = int.tryParse(set.number);
  final todos = await ref.read(todosOsSetsProvider.future);
  final existentes = numeroProcurado == null
      ? const <LegoSet>[]
      : todos.where((s) => s.numeroSet == numeroProcurado).toList();
  final quantidadeNaColecao = existentes.fold<int>(0, (acc, s) => acc + s.quantidade);

  if (!context.mounted) return;

  await SetFoundSheet.show(
    context,
    set: set,
    jaNaColecao: existentes.isNotEmpty,
    quantidadeNaColecao: quantidadeNaColecao > 0 ? quantidadeNaColecao : null,
    // Disponível sempre — mesmo já tendo o set, para poderes registar
    // duplicados que compraste (ver pedido do utilizador).
    onAdicionar: () => _adicionar(context, ref, set, onSetNaoEncontrado),
  );
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