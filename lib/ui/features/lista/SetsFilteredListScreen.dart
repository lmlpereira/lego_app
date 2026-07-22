import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/sets_repository.dart';


final _moeda = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
final _data = DateFormat('dd/MM/yyyy');

/// Ecrã simples de "só leitura" que mostra uma lista de sets já
/// filtrada previamente pelo chamador (ex: sets de um ano, de um tema,
/// ou todos os sets vendidos). Usado a partir do dashboard, ao clicar
/// em cartões, barras do gráfico, ou linhas de uma tabela.
class SetsFilteredListScreen extends StatelessWidget {
  final String titulo;
  final List<LegoSet> sets;

  const SetsFilteredListScreen({
    super.key,
    required this.titulo,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        // Mostra sempre quantos sets estão listados — útil para
        // confirmar rapidamente que o filtro aplicado faz sentido.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${sets.length} ${sets.length == 1 ? 'set' : 'sets'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ),
        ),
      ),
      body: sets.isEmpty
          ? const Center(child: Text('Nenhum set encontrado.'))
          : ListView.separated(
        itemCount: sets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => _LinhaSet(set: sets[i]),
      ),
    );
  }
}

class _LinhaSet extends StatelessWidget {
  final LegoSet set;

  const _LinhaSet({required this.set});

  @override
  Widget build(BuildContext context) {
    final detalhes = <String>[
      set.tema,
      if (set.dataCompra != null) 'comprado em ${_data.format(set.dataCompra!)}',
      if (set.quantidade > 1) 'x${set.quantidade}',
    ].join(' · ');

    return ListTile(
      title: Text('${set.numeroSet} — ${set.descricao}'),
      subtitle: Text(detalhes),
      isThreeLine: false,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_moeda.format(set.valorComprado)),
          if (set.vendido)
            Text(
              set.valorVenda != null
                  ? 'Vendido: ${_moeda.format(set.valorVenda!)}'
                  : 'Vendido',
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
        ],
      ),
    );
  }
}