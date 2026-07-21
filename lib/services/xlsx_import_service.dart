import 'dart:io';

import 'package:excel/excel.dart';

import '../data/repositories/sets_repository.dart';

/// Lê o teu ficheiro "Lista Legos (STOCK).xlsx" e converte a folha
/// "Lista Sets" numa lista de LegoSet prontos a inserir via repository.
///
/// Colunas esperadas (ordem tal como no teu ficheiro):
/// Número | Tema | Descrição | Ano | Valor Set | Valor Comprado |
/// Desconto % | Ano Compra | Quantidade | Vendido | Valor Venda |
/// Margem Venda | Data Venda
///
/// Nota: "Desconto %" e "Margem Venda" NÃO são importados — são
/// recalculados pelo LegoSet a partir dos valores base (ver sets_repository.dart),
/// para nunca ficarem dessincronizados.
class XlsxImportService {
  /// [sheetName] por omissão é "Lista Sets", tal como no teu ficheiro atual.
  Future<List<LegoSet>> importFromFile(String path, {String sheetName = 'Lista Sets'}) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[sheetName];
    if (sheet == null) {
      throw ArgumentError('Folha "$sheetName" não encontrada no ficheiro.');
    }

    final resultado = <LegoSet>[];

    // Linha 0 é o cabeçalho — começamos em 1.
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);

      final numeroSet = _asInt(row, 0);
      if (numeroSet == null) continue; // linha vazia, ignora

      resultado.add(LegoSet(
        numeroSet: numeroSet,
        tema: _asString(row, 1) ?? 'Sem tema',
        descricao: _asString(row, 2) ?? '',
        ano: _asInt(row, 3),
        valorSet: _asDouble(row, 4) ?? 0,
        valorComprado: _asDouble(row, 5) ?? 0,
        // coluna 6 (Desconto %) é ignorada — recalculada
        dataCompra: _anoParaData(_asInt(row, 7)), // "Ano Compra"
        quantidade: _asInt(row, 8) ?? 1,
        vendido: _asBoolSimNao(row, 9),
        valorVenda: _asDouble(row, 10),
        // coluna 11 (Margem Venda) é ignorada — recalculada
        dataVenda: _asDate(row, 12),
      ));
    }

    return resultado;
  }

  // ---------------- Helpers de leitura de célula ----------------

  int? _asInt(List<Data?> row, int col) {
    final v = _rawValue(row, col);
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }

  double? _asDouble(List<Data?> row, int col) {
    final v = _rawValue(row, col);
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String? _asString(List<Data?> row, int col) {
    final v = _rawValue(row, col);
    return v?.toString().trim();
  }

  bool _asBoolSimNao(List<Data?> row, int col) {
    final v = _asString(row, col)?.toUpperCase();
    return v == 'SIM' || v == 'YES' || v == 'TRUE';
  }

  DateTime? _asDate(List<Data?> row, int col) {
    final v = _rawValue(row, col);
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is DateCellValue) return DateTime(v.year, v.month, v.day);
    return DateTime.tryParse(v.toString());
  }

  DateTime? _anoParaData(int? ano) {
    if (ano == null) return null;
    return DateTime(ano, 1, 1); // só temos o ano no ficheiro original
  }

  Object? _rawValue(List<Data?> row, int col) {
    if (col >= row.length) return null;
    return row[col]?.value;
  }
}
