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
  int get schemaVersion => 3;

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
    },
  );

  // ---------- Queries usadas pelo dashboard ----------

  /// Total gasto em compras (soma de valorComprado * quantidade).
  Stream<double> watchTotalCompras() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorComprado, setEntries.quantidade]);
    return query.watch().map((rows) => rows.fold<double>(
        0,
            (acc, r) =>
        acc + (r.read(setEntries.valorComprado) ?? 0) * (r.read(setEntries.quantidade) ?? 1)));
  }

  /// Total de vendas (soma de valorVenda apenas para sets vendidos).
  Stream<double> watchTotalVendas() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorVenda])
      ..where(setEntries.vendido.equals(true));
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
      ..where(setEntries.vendido.equals(true))
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
    ]);
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
      ..where(setEntries.dataCompra.isBetweenValues(inicio, fimExclusivo));
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
      setEntries.dataVenda.isBetweenValues(inicio, fimExclusivo));
    final rows = await query.get();
    return rows.fold<double>(0, (acc, r) => acc + (r.read(setEntries.valorVenda) ?? 0));
  }

  /// Total do valor de tabela (RRP) de todos os sets — soma de
  /// valorSet * quantidade. Comparado com watchTotalCompras(), dá a
  /// poupança total face ao preço de tabela.
  Stream<double> watchTotalValorSet() {
    final query = selectOnly(setEntries)
      ..addColumns([setEntries.valorSet, setEntries.quantidade]);
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
    ]);
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