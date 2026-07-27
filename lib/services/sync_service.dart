import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/database.dart';

/// Resultado de uma sincronização — usado só para feedback na UI
/// ("3 enviados, 1 recebido").
class SyncResult {
  final int enviados;
  final int recebidos;
  final DateTime quando;

  const SyncResult({required this.enviados, required this.recebidos, required this.quando});
}

class SyncException implements Exception {
  final String message;
  SyncException(this.message);

  @override
  String toString() => message;
}

/// Sincroniza a coleção de sets entre o SQLite local (fonte de verdade
/// enquanto offline) e o Firestore (`users/{uid}/sets/{uuid}`, privado
/// por utilizador).
///
/// Como funciona, em resumo:
/// - Cada set tem um `uuid` estável (gerado no dispositivo que o criou)
///   e um `updatedAt` (última alteração local).
/// - **Enviar**: todas as linhas locais com `updatedAt` mais recente do
///   que a última confirmação (`syncedAt`) são escritas no Firestore
///   (`SetOptions(merge: true)`).
/// - **Receber**: lê-se toda a coleção do Firestore e aplica-se local-
///   mente cada documento cujo `updatedAt` remoto seja mais recente do
///   que o local — "last write wins". Nunca pisa uma alteração local
///   ainda por enviar (ver `AppDatabase.aplicarDadosRemotos`).
/// - **Apagar**: um "delete" local só marca `deletado = true` (soft
///   delete) — é enviado como um campo normal, e só é removido de vez
///   da BD local depois de confirmado no Firestore. Isto garante que a
///   eliminação se propaga a todos os dispositivos, em vez de ficar
///   presa num só.
///
/// Não usa `snapshots()` (tempo real) de propósito — a sincronização é
/// disparada por eventos (login, rede a voltar, botão manual), não fica
/// uma ligação aberta permanentemente. Para uma coleção pessoal de sets
/// Lego (algumas centenas de itens), isto é simples, previsível, e barato
/// em leituras do Firestore.
class SyncService {
  final AppDatabase db;
  final FirebaseFirestore _firestore;

  SyncService({required this.db, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _colecaoSets(String uid) =>
      _firestore.collection('users').doc(uid).collection('sets');

  Future<SyncResult> sincronizar(String uid) async {
    if (uid.isEmpty) {
      throw SyncException('Sem sessão ativa — não há com quem sincronizar.');
    }
    try {
      final enviados = await _enviar(uid);
      final recebidos = await _receber(uid);
      await db.purgarApagadosSincronizados();
      return SyncResult(enviados: enviados, recebidos: recebidos, quando: DateTime.now());
    } on FirebaseException catch (e) {
      throw SyncException('Erro do Firestore ao sincronizar (${e.code}).');
    } catch (e) {
      throw SyncException('Falha a sincronizar: $e');
    }
  }

  /// Envia para o Firestore todas as linhas locais com alterações por
  /// confirmar. Usa um batch (até 500 escritas por commit, mais do que
  /// suficiente aqui) para que a operação seja atómica no Firestore.
  Future<int> _enviar(String uid) async {
    final linhas = await db.linhasPendentesEnvio(uid);
    if (linhas.isEmpty) return 0;

    // Resolve todos os nomes de tema de uma vez (em vez de uma query por
    // linha) — o Firestore guarda o nome do tema diretamente (denormali-
    // zado), não o id local, que não faz sentido fora deste dispositivo.
    final temas = await db.select(db.temas).get();
    final nomeTemaPorId = {for (final t in temas) t.id: t.nome};

    final lote = _firestore.batch();
    for (final linha in linhas) {
      final ref = _colecaoSets(uid).doc(linha.uuid);
      lote.set(
        ref,
        _paraFirestore(linha, nomeTemaPorId[linha.temaId] ?? 'Sem tema'),
        SetOptions(merge: true),
      );
    }
    await lote.commit();

    // Só depois do commit confirmado é que marcamos como sincronizado —
    // se o commit falhar (ex: sem rede a meio), as linhas continuam
    // "pendentes" e a próxima sincronização tenta-as outra vez.
    for (final linha in linhas) {
      await db.marcarComoSincronizado(linha.id, linha.updatedAt!, ownerUid: uid);
    }
    return linhas.length;
  }

  /// Lê toda a coleção do utilizador no Firestore e aplica ao SQLite
  /// local os documentos mais recentes do que o que já lá está.
  Future<int> _receber(String uid) async {
    final snapshot = await _colecaoSets(uid).get();
    var recebidos = 0;

    for (final doc in snapshot.docs) {
      final dados = doc.data();
      final updatedAtRemoto = (dados['updatedAt'] as Timestamp?)?.toDate();
      if (updatedAtRemoto == null) continue; // documento mal formado, ignora

      final aplicado = await db.aplicarDadosRemotos(
        uid: uid,
        uuidRemoto: doc.id,
        updatedAtRemoto: updatedAtRemoto,
        tema: (dados['tema'] as String?) ?? 'Sem tema',
        numeroSet: dados['numeroSet'] as int? ?? 0,
        descricao: (dados['descricao'] as String?) ?? '',
        ano: dados['ano'] as int?,
        valorSet: (dados['valorSet'] as num?)?.toDouble() ?? 0,
        valorComprado: (dados['valorComprado'] as num?)?.toDouble() ?? 0,
        dataCompra: (dados['dataCompra'] as Timestamp?)?.toDate(),
        quantidade: dados['quantidade'] as int? ?? 1,
        vendido: dados['vendido'] as bool? ?? false,
        valorVenda: (dados['valorVenda'] as num?)?.toDouble(),
        dataVenda: (dados['dataVenda'] as Timestamp?)?.toDate(),
        notas: dados['notas'] as String?,
        imagemUrl: dados['imagemUrl'] as String?,
        pecas: dados['pecas'] as int?,
        deletado: dados['deletado'] as bool? ?? false,
      );
      if (aplicado) recebidos++;
    }

    return recebidos;
  }

  Map<String, dynamic> _paraFirestore(SetEntry linha, String nomeTema) {
    return {
      'numeroSet': linha.numeroSet,
      'tema': nomeTema,
      'descricao': linha.descricao,
      'ano': linha.ano,
      'valorSet': linha.valorSet,
      'valorComprado': linha.valorComprado,
      'dataCompra': linha.dataCompra != null ? Timestamp.fromDate(linha.dataCompra!) : null,
      'quantidade': linha.quantidade,
      'vendido': linha.vendido,
      'valorVenda': linha.valorVenda,
      'dataVenda': linha.dataVenda != null ? Timestamp.fromDate(linha.dataVenda!) : null,
      'notas': linha.notas,
      'imagemUrl': linha.imagemUrl,
      'pecas': linha.pecas,
      'deletado': linha.deletado,
      'updatedAt': Timestamp.fromDate(linha.updatedAt!),
    };
  }
}
