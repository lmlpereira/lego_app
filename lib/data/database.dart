import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Lista de temas (Ideas, Speed Champions, City, ...).
/// É uma tabela em vez de um enum fixo para o utilizador poder
/// adicionar temas novos sem precisar de uma nova versão da app.
@DataClassName('Tema')
class Temas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text().unique()();
}

/// Um set Lego na coleção (comprado, em stock, ou já vendido).
///
/// Nota: chama-se "SetEntries" (não "Sets") de propósito — "Sets" faria
/// o Drift gerar uma classe de dados chamada "Set", que colide com a
/// classe `Set` do próprio Dart (dart:core) e parte a compilação do
/// código gerado. `id` é a chave interna da app (não o número oficial
/// do set), porque o mesmo set pode ser comprado mais do que uma vez.
@DataClassName('SetEntry')
class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get numeroSet => integer()(); // ex: 75894
  IntColumn get temaId => integer().references(Temas, #id)();
  TextColumn get descricao => text()();
  IntColumn get ano => integer().nullable()(); // ano de lançamento do set

  RealColumn get valorSet => real()(); // preço de tabela (RRP)
  RealColumn get valorComprado => real()(); // preço efetivamente pago
  DateTimeColumn get dataCompra => dateTime().nullable()();
  IntColumn get quantidade => integer().withDefault(const Constant(1))();

  BoolColumn get vendido => boolean().withDefault(const Constant(false))();
  RealColumn get valorVenda => real().nullable()();
  DateTimeColumn get dataVenda => dateTime().nullable()();

  // Campos livres para expansão futura (ex: nº de peças, estado da caixa)
  TextColumn get notas => text().nullable()();

  // URL da imagem do set (preenchido automaticamente a partir do Brickset,
  // mas também pode ficar vazio se o set foi criado à mão).
  TextColumn get imagemUrl => text().nullable()();

  // Número de peças do set (preenchido automaticamente a partir do Brickset).
  IntColumn get pecas => integer().nullable()();

  // ---- Sincronização com o Firestore (ver SyncService) ----
  // uuid identifica este set de forma estável entre dispositivos — NÃO
  // é o mesmo que `id` (que é só a chave local, autoincrement, e pode
  // ser diferente em cada telemóvel para o "mesmo" set). Não é marcado
  // .unique() ao nível da BD de propósito (evita uma migração com SQL à
  // mão para criar o índice); a app garante a unicidade ao gerá-lo
  // sempre com o pacote uuid (v4 = praticamente impossível colidir).
  TextColumn get uuid => text().withDefault(const Constant(''))();

  // Última alteração local. syncedAt < updatedAt (ou syncedAt nulo)
  // significa "ainda por enviar" — é assim que o SyncService decide o
  // que enviar, sem precisar de uma flag "dirty" à parte.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  // "Apagado" localmente mas mantido na BD até a eliminação ser
  // confirmada no Firestore (senão nunca se propagava a outros
  // dispositivos). Ver AppDatabase.purgarApagadosSincronizados().
  BoolColumn get deletado => boolean().withDefault(const Constant(false))();

  // uid do Firebase a quem este set pertence. Fica nulo em sets criados
  // antes desta funcionalidade existir — a primeira sincronização
  // "reclama-os" automaticamente para o utilizador que tiver sessão
  // iniciada nesse momento.
  TextColumn get ownerUid => text().nullable()();
}

// Nota: "desconto %" e "margem de venda" NÃO são colunas — são calculados
// a partir de valorSet/valorComprado/valorVenda sempre que são precisos
// (ver `sets_repository.dart`). Isto evita ficarem dessincronizados
// se um dia editares o preço de um set já registado.

@DriftDatabase(tables: [Temas, SetEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Sobe este número sempre que alterares uma tabela; o Drift trata
  // das migrações a partir daqui (ver secção migration abaixo).
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: adicionado imagemUrl (preenchido pela pesquisa ao Brickset).
      if (from < 2) {
        await m.addColumn(setEntries, setEntries.imagemUrl);
      }
      // v2 -> v3: adicionado pecas (número de peças, também vindo do Brickset).
      if (from < 3) {
        await m.addColumn(setEntries, setEntries.pecas);
      }
      // v3 -> v4: colunas para a sincronização com o Firestore.
      if (from < 4) {
        await m.addColumn(setEntries, setEntries.uuid);
        await m.addColumn(setEntries, setEntries.updatedAt);
        await m.addColumn(setEntries, setEntries.syncedAt);
        await m.addColumn(setEntries, setEntries.deletado);
        await m.addColumn(setEntries, setEntries.ownerUid);

        // Backfill: os sets que já existiam antes desta versão não têm
        // uuid nem updatedAt — sem isto, ficariam de fora da sincronização
        // (uuid vazio não é um identificador válido para o Firestore).
        // Gera um uuid aleatório para cada linha (lower(hex(randomblob(16)))
        // é uma forma simples de gerar algo com colisão praticamente
        // impossível diretamente em SQL) e marca-as como alteradas agora,
        // para que a primeira sincronização as envie todas.
        await m.database.customStatement('''
          UPDATE set_entries
          SET uuid = lower(hex(randomblob(16))),
              updated_at = ${DateTime.now().millisecondsSinceEpoch ~/ 1000}
          WHERE uuid IS NULL OR uuid = ''
        ''');
      }
    },
  );

  // ---------- Queries usadas pelo dashboard ----------

  /// Total gasto em compras (soma de valorComprado * quantidade).
  Stream<double> watchTotalCompras() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorComprado, setEntries.quantidade])
      ..where(setEntries.deletado.equals(false));
    return query.watch().map((rows) => rows.fold<double>(
        0,
            (acc, r) =>
        acc + (r.read(setEntries.valorComprado) ?? 0) * (r.read(setEntries.quantidade) ?? 1)));
  }

  /// Total de vendas (soma de valorVenda apenas para sets vendidos).
  Stream<double> watchTotalVendas() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorVenda])
      ..where(setEntries.vendido.equals(true) & setEntries.deletado.equals(false));
    return query.watch().map(
            (rows) => rows.fold<double>(0, (acc, r) => acc + (r.read(setEntries.valorVenda) ?? 0)));
  }

  /// Compras agrupadas por ano de compra — alimenta o gráfico de evolução anual.
  Stream<List<TotalPorAno>> watchComprasPorAno() {
    final ano = setEntries.dataCompra.year;
    // quantidade é IntColumn — precisa de cast<double>() antes de
    // multiplicar por valorComprado (RealColumn), senão o Drift não
    // consegue combinar Expression<int> com Expression<double>.
    final total = (setEntries.valorComprado * setEntries.quantidade.cast<double>()).sum();

    final query = selectOnly(setEntries)
      ..addColumns([ano, total])
      ..where(setEntries.deletado.equals(false))
      ..groupBy([ano])
      ..orderBy([OrderingTerm.asc(ano)]);

    return query.watch().map((rows) => rows
        .map((r) => TotalPorAno(
      ano: r.read(ano) ?? 0,
      total: r.read(total) ?? 0,
    ))
        .toList());
  }

  /// Vendas agrupadas por ano de venda.
  Stream<List<TotalPorAno>> watchVendasPorAno() {
    final ano = setEntries.dataVenda.year;
    final total = setEntries.valorVenda.sum();

    final query = selectOnly(setEntries)
      ..addColumns([ano, total])
      ..where(setEntries.vendido.equals(true) & setEntries.deletado.equals(false))
      ..groupBy([ano])
      ..orderBy([OrderingTerm.asc(ano)]);

    return query.watch().map((rows) => rows
        .map((r) => TotalPorAno(
      ano: r.read(ano) ?? 0,
      total: r.read(total) ?? 0,
    ))
        .toList());
  }

  /// Compras agrupadas por tema — alimenta o gráfico de distribuição por tema.
  Stream<List<TotalPorTema>> watchComprasPorTema() {
    final query = select(setEntries).join([
      innerJoin(temas, temas.id.equalsExp(setEntries.temaId)),
    ])
      ..where(setEntries.deletado.equals(false));
    // Agregamos do lado do Dart porque juntar select+join+groupBy tem
    // limitações na API do Drift; para o volume de dados desta coleção
    // (algumas centenas de sets) isto é perfeitamente rápido.
    return query.watch().map((rows) {
      final Map<String, double> acumulado = {};
      for (final row in rows) {
        final tema = row.readTable(temas).nome;
        final s = row.readTable(setEntries);
        acumulado[tema] = (acumulado[tema] ?? 0) + s.valorComprado * s.quantidade;
      }
      return acumulado.entries
          .map((e) => TotalPorTema(tema: e.key, total: e.value))
          .toList()
        ..sort((a, b) => b.total.compareTo(a.total));
    });
  }

  /// Total de compras dentro de um intervalo de datas — usado para
  /// comparar dois períodos (ex: 2024 vs 2025, ou dois trimestres).
  Future<double> totalComprasEntre(DateTime inicio, DateTime fimExclusivo) async {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorComprado, setEntries.quantidade])
      ..where(setEntries.deletado.equals(false) &
      setEntries.dataCompra.isBetweenValues(inicio, fimExclusivo));
    final rows = await query.get();
    return rows.fold<double>(
        0,
            (acc, r) =>
        acc + (r.read(setEntries.valorComprado) ?? 0) * (r.read(setEntries.quantidade) ?? 1));
  }

  /// Total de vendas dentro de um intervalo de datas.
  Future<double> totalVendasEntre(DateTime inicio, DateTime fimExclusivo) async {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorVenda])
      ..where(setEntries.vendido.equals(true) &
      setEntries.deletado.equals(false) &
      setEntries.dataVenda.isBetweenValues(inicio, fimExclusivo));
    final rows = await query.get();
    return rows.fold<double>(0, (acc, r) => acc + (r.read(setEntries.valorVenda) ?? 0));
  }

  /// Total do valor de tabela (RRP) de todos os sets — soma de
  /// valorSet * quantidade. Comparado com watchTotalCompras(), dá a
  /// poupança total face ao preço de tabela.
  Stream<double> watchTotalValorSet() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorSet, setEntries.quantidade])
      ..where(setEntries.deletado.equals(false));
    return query.watch().map((rows) => rows.fold<double>(
        0,
            (acc, r) =>
        acc + (r.read(setEntries.valorSet) ?? 0) * (r.read(setEntries.quantidade) ?? 1)));
  }

  /// Número de sets (soma de quantidade, não número de linhas) por tema
  /// — alimenta a tabela "sets por tema".
  Stream<List<TemaResumo>> watchContagemPorTema() {
    final query = select(setEntries).join([
      innerJoin(temas, temas.id.equalsExp(setEntries.temaId)),
    ])
      ..where(setEntries.deletado.equals(false));
    // Agregamos do lado do Dart pela mesma razão que watchComprasPorTema:
    // juntar select+join+groupBy tem limitações na API do Drift, e o
    // volume de dados desta coleção torna isto perfeitamente rápido.
    return query.watch().map((rows) {
      final Map<String, int> acumulado = {};
      for (final row in rows) {
        final tema = row.readTable(temas).nome;
        final s = row.readTable(setEntries);
        acumulado[tema] = (acumulado[tema] ?? 0) + s.quantidade;
      }
      return acumulado.entries
          .map((e) => TemaResumo(tema: e.key, quantidade: e.value))
          .toList()
        ..sort((a, b) => b.quantidade.compareTo(a.quantidade));
    });
  }

  /// Resumo de compras por ano: número de sets comprados (soma de
  /// quantidade) e valor total gasto — alimenta a tabela "compras por ano".
  Stream<List<AnoCompraResumo>> watchResumoComprasPorAno() {
    final ano = setEntries.dataCompra.year;
    final quantidade = setEntries.quantidade.sum();
    final total = (setEntries.valorComprado * setEntries.quantidade.cast<double>()).sum();

    final query = selectOnly(setEntries)
      ..addColumns([ano, quantidade, total])
      ..where(setEntries.deletado.equals(false))
      ..groupBy([ano])
      ..orderBy([OrderingTerm.desc(ano)]);

    return query.watch().map((rows) => rows
        .map((r) => AnoCompraResumo(
      ano: r.read(ano) ?? 0,
      quantidade: r.read(quantidade) ?? 0,
      total: r.read(total) ?? 0,
    ))
        .toList());
  }

  //Totais Perfil

  Stream<double> watchTotalPecas() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.pecas, setEntries.quantidade])
      ..where(setEntries.vendido.equals(false) & setEntries.deletado.equals(false));

    return query.watch().map((rows) => rows.fold<double>(
      0.0,
          (acc, r) {
        final pecas = r.read(setEntries.pecas) ?? 0;
        final qtd = r.read(setEntries.quantidade) ?? 1;
        return acc + (pecas * qtd);
      },
    ));
  }

  /// Total de unidades/sets na coleção (soma de quantidade).
  Stream<double> watchTotalSets() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.quantidade])
      ..where(setEntries.vendido.equals(false) & setEntries.deletado.equals(false));

    return query.watch().map((rows) => rows.fold<double>(
      0.0,
          (acc, r) {
        final qtd = r.read(setEntries.quantidade) ?? 1;
        return acc + qtd.toDouble();
      },
    ));
  }

  // ---------- Métodos de apoio à sincronização (ver SyncService) ----------

  /// Linhas com alterações locais ainda não confirmadas no Firestore:
  /// nunca sincronizadas (syncedAt nulo) ou modificadas depois da última
  /// sincronização (updatedAt > syncedAt). Inclui linhas ainda sem dono
  /// (ownerUid nulo — sets criados antes de existir login/sincronização)
  /// para poderes "reclamá-las" para o utilizador atual ao enviá-las.
  Future<List<SetEntry>> linhasPendentesEnvio(String uid) {
    final query = select(setEntries)
      ..where((t) =>
      (t.ownerUid.equals(uid) | t.ownerUid.isNull()) &
      (t.syncedAt.isNull() | t.updatedAt.isBiggerThan(t.syncedAt)));
    return query.get();
  }

  /// Contagem reativa de linhas por enviar — alimenta o indicador
  /// "alterações pendentes" nas Definições.
  Stream<int> watchContagemPendenteEnvio(String uid) {
    final query = select(setEntries)
      ..where((t) =>
      (t.ownerUid.equals(uid) | t.ownerUid.isNull()) &
      (t.syncedAt.isNull() | t.updatedAt.isBiggerThan(t.syncedAt)));
    return query.watch().map((rows) => rows.length);
  }

  /// Marca uma linha como confirmada no Firestore (chamado pelo
  /// SyncService depois de um `set`/`batch.commit()` bem-sucedido) e, de
  /// caminho, "reclama-a" para [ownerUid] se ainda não tivesse dono.
  Future<void> marcarComoSincronizado(int id, DateTime syncedAt, {required String ownerUid}) {
    return (update(setEntries)..where((t) => t.id.equals(id))).write(
      SetEntriesCompanion(
        syncedAt: Value(syncedAt),
        ownerUid: Value(ownerUid),
      ),
    );
  }

  /// Resolve (ou cria) o id de um tema pelo nome — usado tanto pelo
  /// DriftSetsRepository como pelo SyncService ao aplicar dados vindos
  /// do Firestore (que só guardam o nome do tema, não o id local).
  Future<int> temaIdPorNome(String nome) async {
    final existente = await (select(temas)..where((t) => t.nome.equals(nome))).getSingleOrNull();
    if (existente != null) return existente.id;
    return into(temas).insert(TemasCompanion.insert(nome: nome));
  }

  /// Aplica um documento vindo do Firestore ao SQLite local: insere-o se
  /// ainda não existir cá (por uuid), ou atualiza-o SE o remoto for mais
  /// recente (last-write-wins por updatedAt) — nunca pisa uma alteração
  /// local que ainda não tenha sido enviada. Devolve true se algo mudou
  /// localmente (usado só para contar quantos foram "recebidos").
  Future<bool> aplicarDadosRemotos({
    required String uid,
    required String uuidRemoto,
    required DateTime updatedAtRemoto,
    required String tema,
    required int numeroSet,
    required String descricao,
    int? ano,
    required double valorSet,
    required double valorComprado,
    DateTime? dataCompra,
    required int quantidade,
    required bool vendido,
    double? valorVenda,
    DateTime? dataVenda,
    String? notas,
    String? imagemUrl,
    int? pecas,
    required bool deletado,
  }) async {
    final existente =
    await (select(setEntries)..where((t) => t.uuid.equals(uuidRemoto))).getSingleOrNull();

    if (existente != null) {
      // Há alterações locais ainda por enviar? Não pisamos — a próxima
      // 'enviar' desta linha há de resolver o conflito com o Firestore.
      final localPendente =
          existente.syncedAt == null || existente.updatedAt!.isAfter(existente.syncedAt!);
      if (localPendente) return false;
      // Nada de novo no remoto face ao que já temos.
      if (!updatedAtRemoto.isAfter(existente.updatedAt ?? DateTime(0))) return false;
    }

    final temaId = await temaIdPorNome(tema.isEmpty ? 'Sem tema' : tema);

    final companion = SetEntriesCompanion(
      uuid: Value(uuidRemoto),
      ownerUid: Value(uid),
      temaId: Value(temaId),
      numeroSet: Value(numeroSet),
      descricao: Value(descricao),
      ano: Value(ano),
      valorSet: Value(valorSet),
      valorComprado: Value(valorComprado),
      dataCompra: Value(dataCompra),
      quantidade: Value(quantidade),
      vendido: Value(vendido),
      valorVenda: Value(valorVenda),
      dataVenda: Value(dataVenda),
      notas: Value(notas),
      imagemUrl: Value(imagemUrl),
      pecas: Value(pecas),
      deletado: Value(deletado),
      updatedAt: Value(updatedAtRemoto),
      syncedAt: Value(updatedAtRemoto),
    );

    if (existente != null) {
      await (update(setEntries)..where((t) => t.id.equals(existente.id))).write(companion);
    } else {
      await into(setEntries).insert(companion);
    }
    return true;
  }

  /// Remove definitivamente da BD local os sets apagados que já foram
  /// confirmados no Firestore — mantém a tabela limpa em vez de
  /// acumular "lápides" para sempre. Chamado no fim de cada sincronização.
  Future<void> purgarApagadosSincronizados() {
    return (delete(setEntries)
      ..where((t) =>
      t.deletado.equals(true) &
      t.syncedAt.isNotNull() &
      t.updatedAt.isSmallerOrEqual(t.syncedAt)))
        .go();
  }

  /// Apaga TODOS os dados locais (sets + temas). Usado quando o
  /// utilizador termina sessão — sem isto, os dados de uma conta ficavam
  /// visíveis se outra pessoa (ou outra conta) usasse o mesmo
  /// dispositivo a seguir. Chama-se DEPOIS de tentar sincronizar (ver
  /// ProfileScreen._confirmarLogout), para não perder alterações feitas
  /// offline que ainda não tinham chegado ao Firestore.
  Future<void> limparTudo() async {
    await transaction(() async {
      await delete(setEntries).go();
      await delete(temas).go();
    });
  }

}


/// Resultado auxiliar para gráficos "total por ano".
class TotalPorAno {
  final int ano;
  final double total;
  TotalPorAno({required this.ano, required this.total});
}

/// Resultado auxiliar para gráficos "total por tema".
class TotalPorTema {
  final String tema;
  final double total;
  TotalPorTema({required this.tema, required this.total});
}

/// Resultado auxiliar para a tabela "sets por tema" — número de sets
/// (não o valor gasto, ver TotalPorTema para isso).
class TemaResumo {
  final String tema;
  final int quantidade;
  TemaResumo({required this.tema, required this.quantidade});
}

/// Resultado auxiliar para a tabela "compras por ano" — número de sets
/// comprados e valor total gasto nesse ano.
class AnoCompraResumo {
  final int ano;
  final int quantidade;
  final double total;
  AnoCompraResumo({required this.ano, required this.quantidade, required this.total});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lego_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
