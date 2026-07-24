import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erro devolvido pela API do Brickset (ex: API key inválida, parâmetros
/// inválidos, limite diário excedido, etc).
class BricksetException implements Exception {
  final String message;
  BricksetException(this.message);

  @override
  String toString() => 'BricksetException: $message';
}

/// Um set tal como devolvido pela API do Brickset (v3), só com os campos
/// que interessam a esta app. Ver a documentação completa em:
/// https://brickset.com/article/52664/api-version-3-documentation
class BricksetSet {
  final int setID;
  final String number; // ex: "75894"
  final int numberVariant; // ex: 1 (número completo = "75894-1")
  final String name;
  final int? year;
  final String theme;
  final String subtheme;
  final int? pieces;
  final int? minifigs;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? retailPriceUS;
  final double? retailPriceUK;
  final double? retailPriceDE; // em euros — o mais útil para utilizadores PT

  const BricksetSet({
    required this.setID,
    required this.number,
    required this.numberVariant,
    required this.name,
    required this.theme,
    required this.subtheme,
    this.year,
    this.pieces,
    this.minifigs,
    this.imageUrl,
    this.thumbnailUrl,
    this.retailPriceUS,
    this.retailPriceUK,
    this.retailPriceDE,
  });

  /// Número completo no formato usado pelo Brickset, ex: "75894-1".
  String get numeroCompleto => '$number-$numberVariant';

  /// Descrição sugerida para preencher o campo "Descrição" da app:
  /// "<Tema> - <Nome>" (ou só o nome, se não houver tema).
  //String get descricaoSugerida => theme.isEmpty ? name : '$theme - $name';
  String get descricaoSugerida => theme.isEmpty ? name : '$name';

  /// Melhor preço disponível para pré-preencher "Valor de tabela (€)".
  /// Prioriza o preço DE (já em euros); só usa UK/US como aproximação se
  /// não houver DE, e nesse caso o valor não é rigoroso (moeda diferente).
  double? get precoSugeridoEUR => retailPriceDE ?? retailPriceUK ?? retailPriceUS;

  /// True se o preço sugerido vem de UK/US (moeda diferente do €) — usado
  /// para a UI poder avisar que o valor é aproximado.
  bool get precoSugeridoEAproximado => retailPriceDE == null && precoSugeridoEUR != null;

  factory BricksetSet.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final legoCom = json['LEGOCom'] as Map<String, dynamic>?;
    final us = legoCom?['US'] as Map<String, dynamic>?;
    final uk = legoCom?['UK'] as Map<String, dynamic>?;
    final de = legoCom?['DE'] as Map<String, dynamic>?;

    return BricksetSet(
      setID: json['setID'] as int? ?? 0,
      number: (json['number'] as String?) ?? '',
      numberVariant: json['numberVariant'] as int? ?? 1,
      name: (json['name'] as String?) ?? '',
      year: json['year'] as int?,
      theme: (json['theme'] as String?) ?? '',
      subtheme: (json['subtheme'] as String?) ?? '',
      pieces: json['pieces'] as int?,
      minifigs: json['minifigs'] as int?,
      imageUrl: image?['imageURL'] as String?,
      thumbnailUrl: image?['thumbnailURL'] as String?,
      retailPriceUS: (us?['retailPrice'] as num?)?.toDouble(),
      retailPriceUK: (uk?['retailPrice'] as num?)?.toDouble(),
      retailPriceDE: (de?['retailPrice'] as num?)?.toDouble(),
    );
  }
}

/// Resultado de uma pesquisa: os sets desta página + o total de
/// correspondências na base de dados do Brickset (para saber se há mais
/// páginas a ir buscar — compara com quantos já tens acumulados).
class BricksetSearchResult {
  final List<BricksetSet> sets;
  final int matches;

  const BricksetSearchResult({required this.sets, required this.matches});
}

/// Cliente simples para a API v3 do Brickset (https://brickset.com/api/v3.asmx).
///
/// Precisa de uma API key pessoal, pedida aqui:
/// https://brickset.com/tools/webservices/requestkey
///
/// Nota: o plano gratuito só permite 100 chamadas por dia ao método
/// getSets — chega perfeitamente para autocomplete manual (não é para
/// chamar em cada tecla premida).
class BricksetService {
  static const _baseUrl = 'https://brickset.com/api/v3.asmx';

  final String apiKey;
  final http.Client _client;

  BricksetService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  /// Pesquisa sets por texto livre (número, nome, tema ou subtema).
  /// [pageNumber] começa em 1. Devolve no máximo [pageSize] resultados
  /// dessa página, mais o total de correspondências (`matches`).
  Future<BricksetSearchResult> search(String query, {int pageNumber = 1, int pageSize = 20}) {
    // pageSize/pageNumber têm de ir como número no JSON (não como string),
    // senão o backend do Brickset rebenta com um 500 ao desserializar o JSON.
    return _getSets({'query': query, 'pageNumber': pageNumber, 'pageSize': pageSize});
  }

  /// Vai buscar um set por número exato, ex: "75894" ou "75894-1".
  /// Se não indicares a variante ("-1"), assume-se "-1" (o caso mais comum).
  Future<BricksetSet?> getBySetNumber(String setNumber) async {
    final numero = setNumber.contains('-') ? setNumber : '$setNumber-1';
    final resultado = await _getSets({'setNumber': numero});
    if (resultado.sets.isEmpty) return null;
    return resultado.sets.first;
  }

  Future<BricksetSearchResult> _getSets(Map<String, dynamic> params) async {
    if (apiKey.trim().isEmpty) {
      throw BricksetException(
          'Falta configurar a API key do Brickset (Definições > Brickset).');
    }

    // POST em vez de GET: o parâmetro 'params' é um JSON com chavetas,
    // aspas e dois pontos — a documentação do Brickset avisa que alguns
    // pedidos têm de ir por POST por causa disto. Evita depender do
    // encoding do URL (e de limites de comprimento).
    final uri = Uri.parse('$_baseUrl/getSets');
    final corpoPedido = {
      'apiKey': apiKey,
      // O endpoint .asmx é um web service ASP.NET "old style": mesmo
      // sendo opcional na documentação, se 'userHash' vier omisso por
      // completo o servidor rebenta com um erro 500 em vez de devolver
      // o JSON de erro habitual. Por isso enviamos sempre, mesmo vazio.
      'userHash': '',
      'params': jsonEncode(params),
    };

    final http.Response resposta;
    try {
      resposta = await _client.post(uri, body: corpoPedido);
    } catch (e) {
      throw BricksetException('Sem ligação à internet ou ao Brickset ($e).');
    }

    if (resposta.statusCode != 200) {
      String detalhe = 'HTTP ${resposta.statusCode}';
      try {
        final corpoErro = jsonDecode(resposta.body) as Map<String, dynamic>;
        if (corpoErro['message'] != null) detalhe = corpoErro['message'] as String;
      } catch (_) {
        // corpo não é JSON (ex: página de erro do IIS) — mantém só o código.
      }
      throw BricksetException('O Brickset respondeu com erro ($detalhe).');
    }

    final Map<String, dynamic> corpo;
    try {
      corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
    } catch (_) {
      throw BricksetException('Resposta inesperada do Brickset.');
    }

    if (corpo['status'] != 'success') {
      throw BricksetException(
          (corpo['message'] as String?) ?? 'Erro desconhecido do Brickset.');
    }

    final sets = (corpo['sets'] as List<dynamic>?) ?? const [];
    return BricksetSearchResult(
      sets: sets.map((s) => BricksetSet.fromJson(s as Map<String, dynamic>)).toList(),
      matches: corpo['matches'] as int? ?? sets.length,
    );
  }

  /// Confirma se a API key é válida (usado no ecrã de definições, para dar
  /// feedback imediato em vez de o utilizador só descobrir no primeiro uso).
  Future<bool> checkKey() async {
    if (apiKey.trim().isEmpty) return false;
    final uri = Uri.parse('$_baseUrl/checkKey')
        .replace(queryParameters: {'apiKey': apiKey});
    try {
      final resposta = await _client.get(uri);
      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      return corpo['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}