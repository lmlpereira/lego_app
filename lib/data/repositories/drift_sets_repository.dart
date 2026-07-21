import 'package:drift/drift.dart';

import '../database.dart';
import 'sets_repository.dart';

/// Implementação de hoje: tudo guardado localmente com Drift/SQLite.
///
/// Quando quiseres Firebase, cria uma FirebaseSetsRepository (mesma
/// interface) e troca-se num único sítio (o provider que a fornece à app) —
/// ver lib/data/providers.dart quando o criarmos.
class DriftSetsRepository implements SetsRepository {
  final AppDatabase db;

  DriftSetsRepository(this.db);

  // ---------------- CRUD básico ----------------

  @override
  Stream<List<LegoSet>> watchAll() {
    final query = db.select(db.setEntries).join([
      innerJoin(db.temas, db.temas.id.equalsExp(db.setEntries.temaId)),
    ]);
    return query.watch().map(
        (rows) => rows.map((r) => _toDomain(r.readTable(db.setEntries), r.readTable(db.temas).nome)).toList());
  }

  @override
  Future<LegoSet?> getById(int id) async {
    final query = db.select(db.setEntries).join([
      innerJoin(db.temas, db.temas.id.equalsExp(db.setEntries.temaId)),
    ])
      ..where(db.setEntries.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row.readTable(db.setEntries), row.readTable(db.temas).nome);
  }

  @override
  Future<int> add(LegoSet set) async {
    final temaId = await _temaIdPorNome(set.tema);
    return db.into(db.setEntries).insert(_toCompanion(set, temaId));
  }

  @override
  Future<void> update(LegoSet set) async {
    if (set.id == null) {
      throw ArgumentError('Não é possível atualizar um LegoSet sem id');
    }
    final temaId = await _temaIdPorNome(set.tema);
    await (db.update(db.setEntries)..where((t) => t.id.equals(set.id!)))
        .write(_toCompanion(set, temaId));
  }

  @override
  Future<void> delete(int id) async {
    await (db.delete(db.setEntries)..where((t) => t.id.equals(id))).go();
  }

  // ---------------- Temas ----------------

  @override
  Stream<List<String>> watchTemas() {
    return db.select(db.temas).watch().map((rows) => rows.map((t) => t.nome).toList());
  }

  @override
  Future<void> addTema(String nome) async {
    await db.into(db.temas).insertOnConflictUpdate(TemasCompanion.insert(nome: nome));
  }

  Future<int> _temaIdPorNome(String nome) async {
    final existente = await (db.select(db.temas)..where((t) => t.nome.equals(nome))).getSingleOrNull();
    if (existente != null) return existente.id;
    return db.into(db.temas).insert(TemasCompanion.insert(nome: nome));
  }

  // ---------------- Dashboard: totais ----------------

  @override
  Stream<double> watchTotalCompras() => db.watchTotalCompras();

  @override
  Stream<double> watchTotalVendas() => db.watchTotalVendas();

  @override
  Stream<List<TotalPorAno>> watchComprasPorAno() => db.watchComprasPorAno();

  @override
  Stream<List<TotalPorAno>> watchVendasPorAno() => db.watchVendasPorAno();

  @override
  Stream<List<TotalPorTema>> watchComprasPorTema() => db.watchComprasPorTema();

  // ---------------- Comparação de períodos ----------------

  @override
  Future<double> totalComprasEntre(DateTime inicio, DateTime fimExclusivo) =>
      db.totalComprasEntre(inicio, fimExclusivo);

  @override
  Future<double> totalVendasEntre(DateTime inicio, DateTime fimExclusivo) =>
      db.totalVendasEntre(inicio, fimExclusivo);

  // ---------------- Import / export ----------------

  @override
  Future<ImportResult> addAll(List<LegoSet> sets) async {
    var inseridos = 0;
    var duplicados = 0;
    await db.transaction(() async {
      for (final set in sets) {
        if (await _jaExiste(set)) {
          duplicados++;
          continue;
        }
        final temaId = await _temaIdPorNome(set.tema);
        await db.into(db.setEntries).insert(_toCompanion(set, temaId));
        inseridos++;
      }
    });
    return ImportResult(inseridos: inseridos, duplicadosIgnorados: duplicados);
  }

  /// Considera-se duplicado um set com o mesmo número, a mesma data de
  /// compra e o mesmo valor pago. Isto permite reimportar o mesmo ficheiro
  /// várias vezes sem duplicar linhas, mas continua a deixar registares o
  /// mesmo set comprado de novo se o preço ou a data forem diferentes.
  Future<bool> _jaExiste(LegoSet set) async {
    final query = db.select(db.setEntries)
      ..where((t) => t.numeroSet.equals(set.numeroSet) & t.valorComprado.equals(set.valorComprado));

    final candidatos = await query.get();
    return candidatos.any((c) => _mesmaData(c.dataCompra, set.dataCompra));
  }

  bool _mesmaData(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  }

  // ---------------- Conversões internas ----------------

  LegoSet _toDomain(SetEntry row, String temaNome) {
    return LegoSet(
      id: row.id,
      numeroSet: row.numeroSet,
      tema: temaNome,
      descricao: row.descricao,
      ano: row.ano,
      valorSet: row.valorSet,
      valorComprado: row.valorComprado,
      dataCompra: row.dataCompra,
      quantidade: row.quantidade,
      vendido: row.vendido,
      valorVenda: row.valorVenda,
      dataVenda: row.dataVenda,
      notas: row.notas,
    );
  }

  SetEntriesCompanion _toCompanion(LegoSet set, int temaId) {
    return SetEntriesCompanion(
      numeroSet: Value(set.numeroSet),
      temaId: Value(temaId),
      descricao: Value(set.descricao),
      ano: Value(set.ano),
      valorSet: Value(set.valorSet),
      valorComprado: Value(set.valorComprado),
      dataCompra: Value(set.dataCompra),
      quantidade: Value(set.quantidade),
      vendido: Value(set.vendido),
      valorVenda: Value(set.valorVenda),
      dataVenda: Value(set.dataVenda),
      notas: Value(set.notas),
    );
  }

