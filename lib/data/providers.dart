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

final todosOsSetsProvider = StreamProvider<List<LegoSet>>((ref) {
  return ref.watch(setsRepositoryProvider).watchAll();
});

final temasProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(setsRepositoryProvider).watchTemas();
});
