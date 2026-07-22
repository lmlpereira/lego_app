import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Gera um ficheiro .xlsx modelo, com a estrutura exata que o
/// XlsxImportService espera (mesma folha "Lista Sets", mesmas colunas,
/// pela mesma ordem) — para o utilizador preencher e depois importar.
///
/// Mantido isolado do XlsxImportService de propósito: se um dia
/// mudares a estrutura de import, atualizas as duas listas de colunas
/// aqui e lá, uma ao lado da outra, sem misturar a lógica de leitura
/// com a de geração.
class XlsxTemplateService {
  static const String sheetName = 'Lista Sets';

  static const _cabecalho = [
    'Número',
    'Tema',
    'Descrição',
    'Ano',
    'Valor Set',
    'Valor Comprado',
    'Desconto %',
    'Ano Compra',
    'Quantidade',
    'Vendido',
    'Valor Venda',
    'Margem Venda',
    'Data Venda',
  ];

  /// Cria o ficheiro modelo (cabeçalho + uma linha de exemplo) num
  /// ficheiro temporário e abre o diálogo de partilha do sistema, para
  /// o utilizador guardar onde quiser (Ficheiros, email, Drive, etc.).
  Future<void> gerarEPartilhar() async {
    final path = await _gerarFicheiro();

    await Share.shareXFiles(
      [
        XFile(
          path,
          mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'Modelo de importação — Lego App',
      text: 'Preenche este ficheiro (folha "Lista Sets") e depois importa-o na app.',
    );
  }

  /// Gera o ficheiro modelo e devolve o caminho local — separado de
  /// [gerarEPartilhar] para poder ser testado sem depender do diálogo
  /// de partilha do sistema.
  Future<String> _gerarFicheiro() async {
    final excel = Excel.createExcel();

    // Excel.createExcel() cria sempre uma folha por omissão (ex:
    // "Sheet1"); renomeamo-la em vez de criar uma nova, para não
    // sobrar uma folha vazia extra no ficheiro.
    final folhaOriginal = excel.getDefaultSheet()!;
    excel.rename(folhaOriginal, sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow(
      _cabecalho.map((c) => TextCellValue(c)).toList(),
    );
    for (var col = 0; col < _cabecalho.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = CellStyle(bold: true);
    }

    // Linha de exemplo — mostra o formato esperado de cada coluna
    // (nomeadamente "SIM"/"NÃO" para Vendido) sem teres de adivinhar.
    // "Desconto %" e "Margem Venda" ficam em branco de propósito: são
    // calculados pela app e ignorados no import (ver XlsxImportService).
    sheet.appendRow(<CellValue?>[
      IntCellValue(75894),
      TextCellValue('Icons'),
      TextCellValue('Bonsai Tree'),
      IntCellValue(2022),
      DoubleCellValue(59.99),
      DoubleCellValue(49.99),
      null, // Desconto % - calculado pela app
      IntCellValue(2023),
      IntCellValue(1),
      TextCellValue('NÃO'),
      null, // Valor Venda
      null, // Margem Venda - calculado pela app
      null, // Data Venda
    ]);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Não foi possível gerar o ficheiro modelo.');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/modelo_importacao_lego.xlsx';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}