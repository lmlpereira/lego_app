import '../data/database.dart';

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
  Stream<List<TotalPorAno>> watchComprasPorAno();
  Stream<List<TotalPorAno>> watchVendasPorAno();
  Stream<List<TotalPorTema>> watchComprasPorTema();

  // ---- Dashboard: comparação de períodos ----
  Future<double> totalComprasEntre(DateTime inicio, DateTime fimExclusivo);
  Future<double> totalVendasEntre(DateTime inicio, DateTime fimExclusivo);

  // ---- Import / export ----
  /// Insere em bloco (usado pelo import do xlsx), ignorando linhas que já
  /// existem (mesmo número de set + mesma data de compra + mesmo valor
  /// pago), para poderes reimportar o mesmo ficheiro sem duplicar dados.
  Future<ImportResult> addAll(List<LegoSet> sets);
}

/// Resultado de uma importação em bloco.
class ImportResult {
  final int inseridos;
  final int duplicadosIgnorados;

  const ImportResult(
      {required this.inseridos, required this.duplicadosIgnorados});
}
