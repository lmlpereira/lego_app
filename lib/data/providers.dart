import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'repositories/sets_repository.dart';
import 'repositories/drift_sets_repository.dart';

/// Uma única instância da base de dados para toda a app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// O resto da app (UI, dashboard) depende SÓ deste provider.
/// No dia do Firebase, troca-se apenas esta linha — nada mais muda.
final setsRepositoryProvider = Provider<SetsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftSetsRepository(db);
});

// ---- Exemplos de providers para o dashboard (a UI consome estes) ----

final totalComprasProvider = StreamProvider<double>((ref) {
  return ref.watch(setsRepositoryProvider).watchTotalCompras();
});

final totalVendasProvider = StreamProvider<double>((ref) {
  return ref.watch(setsRepositoryProvider).watchTotalVendas();
});

final comprasPorAnoProvider = StreamProvider<List<TotalPorAno>>((ref) {
  return ref.watch(setsRepositoryProvider).watchComprasPorAno();
});

final comprasPorTemaProvider = StreamProvider<List<TotalPorTema>>((ref) {
  return ref.watch(setsRepositoryProvider).watchComprasPorTema();
});

final totalValorSetProvider = StreamProvider<double>((ref) {
  return ref.watch(setsRepositoryProvider).watchTotalValorSet();
});

final contagemPorTemaProvider = StreamProvider<List<TemaResumo>>((ref) {
  return ref.watch(setsRepositoryProvider).watchContagemPorTema();
});

final resumoComprasPorAnoProvider = StreamProvider<List<AnoCompraResumo>>((ref) {
  return ref.watch(setsRepositoryProvider).watchResumoComprasPorAno();
});

// Vamos buscar o tema que mais tenho na coleção
final temaFavoritoProvider = Provider<AsyncValue<TemaResumo?>>((ref) {
  final contagem = ref.watch(contagemPorTemaProvider);
  return contagem.whenData((lista) => lista.isEmpty ? null : lista.first);
});

/// Valor total gasto apenas nos sets já vendidos — para comparar
/// diretamente com o valor das vendas (lucro real), sem incluir sets
/// ainda em stock por vender. Derivado de todosOsSetsProvider em vez de
/// uma query nova na BD, porque é apenas um filtro sobre dados que já
/// vamos buscar de qualquer forma.
final totalComprasVendidosProvider = Provider<AsyncValue<double>>((ref) {
  final sets = ref.watch(todosOsSetsProvider);
  return sets.whenData((lista) => lista
      .where((s) => s.vendido)
      .fold<double>(0, (acc, s) => acc + s.valorComprado * s.quantidade));
});

final todosOsSetsProvider = StreamProvider<List<LegoSet>>((ref) {
  return ref.watch(setsRepositoryProvider).watchAll();
});

final temasProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(setsRepositoryProvider).watchTemas();
});

/// Para o ecrã "Gerir temas" (Definições): todos os temas com a
/// contagem de sets de cada um (0 incluído, ao contrário de
/// contagemPorTemaProvider).
final temasComContagemProvider = StreamProvider<List<TemaComContagem>>((ref) {
  return ref.watch(setsRepositoryProvider).watchTemasComContagem();
});

final totalSetsProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(setsRepositoryProvider);
  return repository.watchTotalSets();
});

final totalPecasProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(setsRepositoryProvider);
  return repository.watchTotalPecas();
});