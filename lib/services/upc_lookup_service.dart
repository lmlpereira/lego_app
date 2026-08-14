import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

/// Erro devolvido pelo lookup de código de barras (rede, limite diário
/// excedido, resposta inesperada...).
class UpcLookupException implements Exception {
  final String message;
  UpcLookupException(this.message);

  @override
  String toString() => message;
}

/// Resultado de um lookup: o texto do produto tal como devolvido pela
/// UPCitemdb, mais os números que PODEM ser o número do set LEGO
/// (extraídos do título por regex — ainda não confirmados no Brickset).
class UpcLookupResult {
  final String titulo;
  final String? marca;
  final List<String> candidatosNumeroSet;

  const UpcLookupResult({
    required this.titulo,
    this.marca,
    required this.candidatosNumeroSet,
  });
}

/// Traduz um código de barras (EAN/UPC lido na câmara) num nome de
/// produto, usando a UPCitemdb (https://www.upcitemdb.com/api/).
///
/// Nem a Brickset nem a Rebrickable permitem pesquisar sets por código
/// de barras diretamente — só a UPCitemdb (e serviços semelhantes)
/// mantêm uma base de dados genérica de códigos de barras -> produtos.
/// Por isso o fluxo tem sempre dois passos: primeiro este serviço
/// (código -> nome do produto, ex: "LEGO Star Wars Millennium Falcon
/// 75192"), depois o BricksetService.getBySetNumber para confirmar e
/// enriquecer com os dados oficiais (ver scanflow.dart).
///
/// Usa o plano "trial" da UPCitemdb: gratuito, sem precisar de conta
/// nem chave, limitado a 100 pedidos/dia por IP — mais do que suficiente
/// para um scan ocasional.
class UpcLookupService {
  static const _baseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';

  final http.Client _client;

  UpcLookupService({http.Client? client}) : _client = client ?? http.Client();

  /// Números de LEGO têm tipicamente 4 a 6 dígitos. Evita apanhar anos
  /// (ex: "2024"), mas isso é ambíguo por natureza — é por isto que
  /// tratamos os resultados como CANDIDATOS a confirmar no Brickset, não
  /// como certezas.
  static final _regexNumero = RegExp(r'\b\d{4,6}\b');

  /// Palavras que, se aparecerem logo a seguir a um número candidato,
  /// indicam que esse número é antes uma contagem de peças, idade
  /// recomendada, etc. — não o número do set.
  static final _sufixosARejeitar = RegExp(
    r'^\s*(pcs?|pieces?|piece|peças|peca|\+)',
    caseSensitive: false,
  );

  Future<UpcLookupResult?> procurar(String codigo) async {
    debugPrint('UPCitemdb: buscando $codigo');
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {'upc': codigo});

    final http.Response resposta;
    try {
      resposta = await _client.get(uri);
    } catch (e) {
      throw UpcLookupException('Sem ligação à internet ($e).');
    }

    if (resposta.statusCode == 429) {
      throw UpcLookupException(
          'Limite diário de pesquisas por código de barras excedido. Tenta amanhã, ou pesquisa manualmente.');
    }
    if (resposta.statusCode != 200) {
      throw UpcLookupException('Erro ao consultar o código de barras (HTTP ${resposta.statusCode}).');
    }

    final Map<String, dynamic> corpo;
    try {
      corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
    } catch (_) {
      throw UpcLookupException('Resposta inesperada do serviço de códigos de barras.');
    }

    final items = (corpo['items'] as List<dynamic>?) ?? const [];
    if (items.isEmpty) return null;

    final item = items.first as Map<String, dynamic>;
    final titulo = (item['title'] as String?) ?? '';
    if (titulo.isEmpty) return null;

    return UpcLookupResult(
      titulo: titulo,
      marca: item['brand'] as String?,
      candidatosNumeroSet: _extrairCandidatos(titulo),
    );
  }

  /// Extrai números candidatos a "número do set" do título do produto,
  /// pela ordem em que aparecem no texto (sem duplicados).
  List<String> _extrairCandidatos(String titulo) {
    final candidatos = <String>[];
    for (final match in _regexNumero.allMatches(titulo)) {
      final restoDoTexto = titulo.substring(match.end);
      if (_sufixosARejeitar.hasMatch(restoDoTexto)) continue;

      final numero = match.group(0)!;
      if (!candidatos.contains(numero)) candidatos.add(numero);
    }
    return candidatos;
  }

  void dispose() => _client.close();
}
