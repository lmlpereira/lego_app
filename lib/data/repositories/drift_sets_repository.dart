import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import 'sets_repository.dart';

const _uuidGen = Uuid();

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
    ])
      ..where(db.setEntries.deletado.equals(false));
    return query.watch().map(
            (rows) =>
            rows.map((r) =>
                _toDomain(r.readTable(db.setEntries), r
                    .readTable(db.temas)
                    .nome)).toList());
  }

  @override
  Future<LegoSet?> getById(int id) async {
    final query = db.select(db.setEntries).join([
      innerJoin(db.temas, db.temas.id.equalsExp(db.setEntries.temaId)),
    ])
      ..where(db.setEntries.id.equals(id) & db.setEntries.deletado.equals(false));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row.readTable(db.setEntries), row
        .readTable(db.temas)
        .nome);
  }

  @override
  Future<int> add(LegoSet set) async {
    final temaId = await _temaIdPorNome(set.tema);
    return db.into(db.setEntries).insert(_toInsertCompanion(set, temaId));
  }

  @override
  Future<void> update(LegoSet set) async {
    if (set.id == null) {
      throw ArgumentError('Não é possível atualizar um LegoSet sem id');
    }
    final temaId = await _temaIdPorNome(set.tema);
    await (db.update(db.setEntries)
      ..where((t) => t.id.equals(set.id!)))
        .write(_toUpdateCompanion(set, temaId));
  }

  @override
  Future<void> delete(int id) async {
    // Soft delete: se apagássemos a linha de vez, a eliminação nunca
    // chegava a propagar-se para o Firestore nem para outros
    // dispositivos. Fica marcada como apagada e escondida da UI (ver
    // watchAll/getById acima); o SyncService confirma a eliminação no
    // Firestore e só depois é que a linha é removida de vez (ver
    // AppDatabase.purgarApagadosSincronizados).
    await (db.update(db.setEntries)..where((t) => t.id.equals(id))).write(
      SetEntriesCompanion(
        deletado: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------- Temas ----------------

  @override
  Stream<List<String>> watchTemas() {
    return db.select(db.temas).watch().map((rows) =>
        rows.map((t) => t.nome).toList());
  }

  @override
  Future<void> addTema(String nome) async {
    await db.into(db.temas).insertOnConflictUpdate(
        TemasCompanion.insert(nome: nome));
  }

  Future<int> _temaIdPorNome(String nome) => db.temaIdPorNome(nome);

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

  @override
  Stream<double> watchTotalValorSet() => db.watchTotalValorSet();

  @override
  Stream<List<TemaResumo>> watchContagemPorTema() => db.watchContagemPorTema();

  @override
  Stream<List<AnoCompraResumo>> watchResumoComprasPorAno() =>
      db.watchResumoComprasPorAno();

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
    var atualizados = 0;
    await db.transaction(() async {
      for (final set in sets) {
        final existenteId = await _encontrarExistenteId(set);
        final temaId = await _temaIdPorNome(set.tema);

        if (existenteId != null) {
          await (db.update(db.setEntries)
            ..where((t) => t.id.equals(existenteId)))
              .write(_toUpdateCompanion(set, temaId));
          atualizados++;
        } else {
          await db.into(db.setEntries).insert(_toInsertCompanion(set, temaId));
          inseridos++;
        }
      }
    });
    return ImportResult(inseridos: inseridos, atualizados: atualizados);
  }

  /// Considera-se o mesmo set (para efeitos de import) um registo com o
  /// mesmo número e a mesma data de compra — o valor pago NÃO entra no
  /// critério de propósito, para permitir corrigir um preço errado no
  /// Excel sem que isso crie um registo duplicado. Devolve o id do
  /// registo existente, para poder ser atualizado em vez de duplicado.
  ///
  /// Nota: se comprares o mesmo set mais do que uma vez na mesma data,
  /// este critério não os distingue e a segunda linha do import vai
  /// atualizar (sobrepor-se a) a primeira em vez de criar uma segunda
  /// entrada. Se isso for um cenário real para ti, diz-me e mudamos o
  /// critério (ex: usar um id de linha do próprio ficheiro Excel).
  Future<int?> _encontrarExistenteId(LegoSet set) async {
    final query = db.select(db.setEntries)
      ..where((t) => t.numeroSet.equals(set.numeroSet) & t.deletado.equals(false));

    final candidatos = await query.get();
    for (final c in candidatos) {
      if (_mesmaData(c.dataCompra, set.dataCompra)) return c.id;
    }
    return null;
  }

  bool _mesmaData(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
      imagemUrl: row.imagemUrl,
      pecas: row.pecas,
      uuid: row.uuid,
      updatedAt: row.updatedAt,
      syncedAt: row.syncedAt,
      deletado: row.deletado,
      ownerUid: row.ownerUid,
    );
  }

  /// Campos partilhados entre inserção e atualização. Propositadamente
  /// NÃO inclui uuid/ownerUid/syncedAt/deletado — ver [_toInsertCompanion]
  /// e [_toUpdateCompanion] para saber porquê cada um trata esses campos
  /// de forma diferente.
  SetEntriesCompanion _camposComuns(LegoSet set, int temaId) {
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
      imagemUrl: Value(set.imagemUrl),
      pecas: Value(set.pecas),
      // Toda a escrita (criação ou edição) conta como "alteração agora" —
      // é isto que marca a linha como pendente de envio na próxima
      // sincronização (ver AppDatabase.linhasPendentesEnvio).
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Um set novo precisa de um uuid — gera um se ainda não vier com um
  /// (ex: vindo de um import). ownerUid fica por preencher de propósito:
  /// é o SyncService que o atribui ao utilizador atual no primeiro envio.
  SetEntriesCompanion _toInsertCompanion(LegoSet set, int temaId) {
    final uuid = (set.uuid != null && set.uuid!.isNotEmpty) ? set.uuid! : _uuidGen.v4();
    return _camposComuns(set, temaId).copyWith(
      uuid: Value(uuid),
      ownerUid: set.ownerUid != null ? Value(set.ownerUid) : const Value.absent(),
    );
  }

  /// Uma edição NUNCA deve tocar em uuid/ownerUid/syncedAt/deletado —
  /// são deixados de fora do companion (Value.absent implícito) para que
  /// o UPDATE preserve exatamente o que já lá estava. Se regenerássemos
  /// o uuid aqui, cada edição "perdia" a ligação ao documento já
  /// existente no Firestore e criava um duplicado lá.
  SetEntriesCompanion _toUpdateCompanion(LegoSet set, int temaId) {
    return _camposComuns(set, temaId);
  }

  @override
  Stream<double> watchTotalPecas() => db.watchTotalPecas();

  @override
  Stream<double> watchTotalSets() => db.watchTotalSets();
}