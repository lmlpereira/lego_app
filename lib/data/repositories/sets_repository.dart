import '../database.dart';

/// Modelo de domínio simples (não depende do código gerado pelo Drift),
/// para a UI e os providers não terem de conhecer a camada de BD.
class LegoSet {
  final int? id;
  final int numeroSet;
  final String tema;
  final String descricao;
  final int? ano;
  final double valorSet;
  final double valorComprado;
  final DateTime? dataCompra;
  final int quantidade;
  final bool vendido;
  final double? valorVenda;
  final DateTime? dataVenda;
  final String? notas;
  final String? imagemUrl; // preenchido automaticamente a partir do Brickset
  final int? pecas; // número de peças, também vindo do Brickset

  const LegoSet({
    this.id,
    required this.numeroSet,
    required this.tema,
    required this.descricao,
    this.ano,
    required this.valorSet,
    required this.valorComprado,
    this.dataCompra,
    this.quantidade = 1,
    this.vendido = false,
    this.valorVenda,
    this.dataVenda,
    this.notas,
    this.imagemUrl,
    this.pecas,
  });

  /// Desconto % sobre o valor de tabela. Calculado, nunca guardado.
  double get descontoPercent {
    if (valorSet <= 0) return 0;
    return (1 - (valorComprado / valorSet)) * 100;
  }

  /// Margem de venda (%) sobre o valor comprado. Só faz sentido se vendido.
  double? get margemVendaPercent {
    if (!vendido || valorVenda == null || valorComprado <= 0) return null;
    return ((valorVenda! - valorComprado) / valorComprado) * 100;
  }

  /// Cópia com o [id] substituído — usado quando descobrimos que um set
  /// vindo de fora (ex: import) corresponde a um registo já existente.
  LegoSet withId(int novoId) => LegoSet(
    id: novoId,
    numeroSet: numeroSet,
    tema: tema,
    descricao: descricao,
    ano: ano,
    valorSet: valorSet,
    valorComprado: valorComprado,
    dataCompra: dataCompra,
    quantidade: quantidade,
    vendido: vendido,
    valorVenda: valorVenda,
    dataVenda: dataVenda,
    notas: notas,
    imagemUrl: imagemUrl,
    pecas: pecas,
  );
}

/// Contrato que a UI e os providers usam. Hoje tem uma única implementação
/// (DriftSetsRepository); no futuro pode ganhar uma FirebaseSetsRepository
/// ou uma versão híbrida com sincronização, sem alterar quem a consome.
abstract class SetsRepository {
  // ---- CRUD básico ----
  Stream<List<LegoSet>> watchAll();
  Future<LegoSet?> getById(int id);
  Future<int> add(LegoSet set);
  Future<void> update(LegoSet set);
  Future<void> delete(int id);

  // ---- Temas ----
  Stream<List<String>> watchTemas();
  Future<void> addTema(String nome);

  // ---- Dashboard: totais ----
  Stream<double> watchTotalCompras();
  Stream<double> watchTotalVendas();
  Stream<double> watchTotalValorSet();
  Stream<List<TotalPorAno>> watchComprasPorAno();
  Stream<List<TotalPorAno>> watchVendasPorAno();
  Stream<List<TotalPorTema>> watchComprasPorTema();
  Stream<List<TemaResumo>> watchContagemPorTema();
  Stream<List<AnoCompraResumo>> watchResumoComprasPorAno();

  // ---- Dashboard: comparação de períodos ----
  Future<double> totalComprasEntre(DateTime inicio, DateTime fimExclusivo);
  Future<double> totalVendasEntre(DateTime inicio, DateTime fimExclusivo);

  // ---- Import / export ----
  /// Insere em bloco (usado pelo import do xlsx). Uma linha que já exista
  /// (mesmo número de set + mesma data de compra) não é duplicada — todos
  /// os restantes campos (valor pago, quantidade, vendido, valor de venda,
  /// etc.) são atualizados com os valores do ficheiro importado.
  Future<ImportResult> addAll(List<LegoSet> sets);
}

/// Resultado de uma importação em bloco.
class ImportResult {
  final int inseridos;
  final int atualizados;

  const ImportResult({required this.inseridos, required this.atualizados});
}