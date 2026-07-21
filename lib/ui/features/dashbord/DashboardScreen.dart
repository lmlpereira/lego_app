import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/providers.dart';
import '../../../data/database.dart';

final _moeda = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        // Os providers são streams ligadas à BD, mas o "pull to refresh"
        // dá ao utilizador uma confirmação visual de que os dados estão
        // atualizados, mesmo não sendo estritamente necessário.
        onRefresh: () async {
          ref.invalidate(totalComprasProvider);
          ref.invalidate(totalVendasProvider);
          ref.invalidate(comprasPorAnoProvider);
          ref.invalidate(comprasPorTemaProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _CartoesTotais(),
            SizedBox(height: 24),
            _SeccaoGrafico(
              titulo: 'Compras por ano',
              child: _GraficoComprasPorAno(),
            ),
            SizedBox(height: 24),
            _SeccaoGrafico(
              titulo: 'Compras por tema',
              child: _GraficoComprasPorTema(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título + moldura consistente para cada secção de gráfico.
class _SeccaoGrafico extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _SeccaoGrafico({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
            child: SizedBox(height: 240, child: child),
          ),
        ),
      ],
    );
  }
}

// ---------------- Cartões de totais ----------------

class _CartoesTotais extends ConsumerWidget {
  const _CartoesTotais();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compras = ref.watch(totalComprasProvider);
    final vendas = ref.watch(totalVendasProvider);

    return Row(
      children: [
        Expanded(
          child: _CartaoTotal(
            titulo: 'Total comprado',
            valor: compras,
            icone: Icons.shopping_cart_outlined,
            cor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CartaoTotal(
            titulo: 'Total vendido',
            valor: vendas,
            icone: Icons.sell_outlined,
            cor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CartaoMargem(compras: compras, vendas: vendas),
        ),
      ],
    );
  }
}

class _CartaoTotal extends StatelessWidget {
  final AsyncValue<double> valor;
  final String titulo;
  final IconData icone;
  final Color cor;

  const _CartaoTotal({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor),
            const SizedBox(height: 8),
            Text(titulo,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            valor.when(
              data: (v) => Text(
                _moeda.format(v),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão especial: margem = vendas - compras. Só faz sentido quando
/// ambos os totais já chegaram, por isso combina os dois AsyncValues.
class _CartaoMargem extends StatelessWidget {
  final AsyncValue<double> compras;
  final AsyncValue<double> vendas;

  const _CartaoMargem({required this.compras, required this.vendas});

  @override
  Widget build(BuildContext context) {
    final ambosProntos = compras.hasValue && vendas.hasValue;
    final margem =
    ambosProntos ? vendas.value! - compras.value! : null;
    final positivo = (margem ?? 0) >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              positivo ? Icons.trending_up : Icons.trending_down,
              color: positivo ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            Text('Margem',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (margem == null)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                _moeda.format(margem),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: positivo ? Colors.green : Colors.red,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Gráfico: compras por ano ----------------

class _GraficoComprasPorAno extends ConsumerWidget {
  const _GraficoComprasPorAno();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dadosAsync = ref.watch(comprasPorAnoProvider);

    return dadosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErroGrafico(erro: e),
      data: (dados) {
        if (dados.isEmpty) return const _SemDados();

        final maxY = dados.map((d) => d.total).reduce((a, b) => a > b ? a : b);

        return BarChart(
          BarChartData(
            maxY: maxY * 1.2,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) => Text(
                    _moedaCompacta(value),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= dados.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${dados[i].ano}',
                          style: Theme.of(context).textTheme.bodySmall),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < dados.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: dados[i].total,
                      color: Theme.of(context).colorScheme.primary,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      _moeda.format(rod.toY),
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- Gráfico: compras por tema ----------------

class _GraficoComprasPorTema extends ConsumerWidget {
  const _GraficoComprasPorTema();

  static const _cores = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dadosAsync = ref.watch(comprasPorTemaProvider);

    return dadosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErroGrafico(erro: e),
      data: (dados) {
        if (dados.isEmpty) return const _SemDados();

        final total = dados.fold<double>(0, (acc, d) => acc + d.total);

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: [
                    for (var i = 0; i < dados.length; i++)
                      PieChartSectionData(
                        value: dados[i].total,
                        color: _cores[i % _cores.length],
                        title: total > 0
                            ? '${(dados[i].total / total * 100).toStringAsFixed(0)}%'
                            : '',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Legenda: gráficos circulares por si só não identificam
            // qual fatia é qual tema, por isso a legenda é essencial.
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: dados.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _cores[i % _cores.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dados[i].tema,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- Estados partilhados (vazio / erro) ----------------

class _SemDados extends StatelessWidget {
  const _SemDados();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Ainda sem dados para mostrar.',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _ErroGrafico extends StatelessWidget {
  final Object erro;

  const _ErroGrafico({required this.erro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Erro a carregar dados: $erro',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Formata valores grandes de forma compacta para o eixo Y (ex: 1.2k €).
String _moedaCompacta(double valor) {
  if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}k€';
  return valor.toStringAsFixed(0);
}