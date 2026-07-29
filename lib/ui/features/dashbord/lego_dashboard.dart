import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/intl.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../lista/SetsFilteredListScreen.dart';

final _moeda = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
final _percentagem = NumberFormat('0.0', 'pt_PT');

// Funções de cálculo passadas a _CartoesComparacao — a poupança usa o
// valor de tabela como base, o lucro usa o valor pago como base.
double _poupanca(double compras, double sets) => sets - compras;
double _poupancaPercent(double compras, double sets) =>
    sets > 0 ? (sets - compras) / sets * 100 : 0;
double _lucro(double vendas, double comprasVendidos) => vendas - comprasVendidos;
double _lucroPercent(double vendas, double comprasVendidos) =>
    comprasVendidos > 0 ? (vendas - comprasVendidos) / comprasVendidos * 100 : 0;

/// Abre o ecrã de lista com os sets que passam em [filtro].
void _abrirListaFiltrada(
    BuildContext context,
    bool Function(LegoSet) filtro,
    String titulo,
    ) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => SetsFilteredListScreen(titulo: titulo, filtro: filtro),
  ));
}

class LegoDashboardScreen extends ConsumerWidget {
  const LegoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dashboardTitle ?? 'Dashboard'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        // Os providers são streams ligadas à BD, mas o "pull to refresh"
        // dá ao utilizador uma confirmação visual de atualização.
        onRefresh: () async {
          ref.invalidate(totalComprasProvider);
          ref.invalidate(totalVendasProvider);
          ref.invalidate(totalValorSetProvider);
          ref.invalidate(comprasPorAnoProvider);
          ref.invalidate(contagemPorTemaProvider);
          ref.invalidate(resumoComprasPorAnoProvider);
          ref.invalidate(todosOsSetsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CartoesComparacao(
              tituloA: t.titleAAll,
              providerA: totalComprasProvider,
              iconeA: Icons.shopping_cart_outlined,
              corA: Colors.blue,
              tituloB: t.titleBAll,
              providerB: totalValorSetProvider,
              iconeB: Icons.local_offer_outlined,
              corB: Colors.deepPurple,
              labelDiferenca: t.labelDiferencaAllSets,
              diferenca: _poupanca,
              percentagem: _poupancaPercent,
              tituloLista: t.titleAllSets,
              filtro: (s) => true,
            ),
            const SizedBox(height: 12),
            _CartoesComparacao(
              tituloA: t.titleAVendidos,
              providerA: totalVendasProvider,
              iconeA: Icons.sell_outlined,
              corA: Colors.green,
              tituloB: t.titleBVendidos,
              providerB: totalComprasVendidosProvider,
              iconeB: Icons.shopping_cart_outlined,
              corB: Colors.blue,
              labelDiferenca: t.labelDiferencaVendidos,
              diferenca: _lucro,
              percentagem: _lucroPercent,
              tituloLista: t.titleVendidos,
              filtro: (s) => s.vendido,
            ),
            const SizedBox(height: 24),
            _SeccaoCartao(
              titulo: t.titleLast5Years,
              child: const SizedBox(height: 220, child: _GraficoUltimosAnos()),
            ),
            const SizedBox(height: 24),
            _SeccaoCartao(
              titulo: t.titleSetsTema,
              child: const _TabelaTemas(),
            ),
            const SizedBox(height: 24),
            _SeccaoCartao(
              titulo: t.titleComprasAno,
              child: const _TabelaAnos(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título + moldura consistente para cada secção do dashboard.
class _SeccaoCartao extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _SeccaoCartao({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Par de cartões (A e B) mais uma faixa por baixo com a diferença em
/// euros e percentagem. Ambos os cartões são clicáveis.
class _CartoesComparacao extends ConsumerWidget {
  final String tituloA;
  final ProviderListenable<AsyncValue<double>> providerA;
  final IconData iconeA;
  final Color corA;

  final String tituloB;
  final ProviderListenable<AsyncValue<double>> providerB;
  final IconData iconeB;
  final Color corB;

  final String labelDiferenca;
  final double Function(double a, double b) diferenca;
  final double Function(double a, double b) percentagem;

  final String tituloLista;
  final bool Function(LegoSet) filtro;

  const _CartoesComparacao({
    required this.tituloA,
    required this.providerA,
    required this.iconeA,
    required this.corA,
    required this.tituloB,
    required this.providerB,
    required this.iconeB,
    required this.corB,
    required this.labelDiferenca,
    required this.diferenca,
    required this.percentagem,
    required this.tituloLista,
    required this.filtro,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(providerA);
    final b = ref.watch(providerB);

    void abrirLista() => _abrirListaFiltrada(context, filtro, tituloLista);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CartaoValor(
                titulo: tituloA,
                valor: a,
                icone: iconeA,
                cor: corA,
                onTap: abrirLista,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CartaoValor(
                titulo: tituloB,
                valor: b,
                icone: iconeB,
                cor: corB,
                onTap: abrirLista,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FaixaDiferenca(
          label: labelDiferenca,
          a: a,
          b: b,
          diferenca: diferenca,
          percentagem: percentagem,
        ),
      ],
    );
  }
}

class _CartaoValor extends StatelessWidget {
  final AsyncValue<double> valor;
  final String titulo;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  const _CartaoValor({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icone, color: cor, size: 22),
                  Icon(Icons.chevron_right,
                      size: 18, color: Theme.of(context).colorScheme.outline),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
                error: (e, _) => Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaixaDiferenca extends StatelessWidget {
  final String label;
  final AsyncValue<double> a;
  final AsyncValue<double> b;
  final double Function(double a, double b) diferenca;
  final double Function(double a, double b) percentagem;

  const _FaixaDiferenca({
    required this.label,
    required this.a,
    required this.b,
    required this.diferenca,
    required this.percentagem,
  });

  @override
  Widget build(BuildContext context) {
    if (!a.hasValue || !b.hasValue) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final diff = diferenca(a.value!, b.value!);
    final perc = percentagem(a.value!, b.value!);
    final positivo = diff >= 0;
    final cor = positivo ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(positivo ? Icons.arrow_upward : Icons.arrow_downward,
              color: cor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_moeda.format(diff)} (${_percentagem.format(perc)}%)',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }
}

class _GraficoUltimosAnos extends ConsumerWidget {
  const _GraficoUltimosAnos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dadosAsync = ref.watch(comprasPorAnoProvider);
    final t = AppLocalizations.of(context)!;

    return dadosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErroSeccao(erro: e),
      data: (todosOsDados) {
        if (todosOsDados.isEmpty) return const _SemDados();

        final dados = todosOsDados.length > 5
            ? todosOsDados.sublist(todosOsDados.length - 5)
            : todosOsDados;

        final maxVal = dados.map((d) => d.total).fold(0.0, (a, b) => a > b ? a : b);
        final maxY = maxVal > 0 ? maxVal * 1.2 : 100.0;

        void aoTocarBarra(int index) {
          if (index < 0 || index >= dados.length) return;
          final ano = dados[index].ano;
          _abrirListaFiltrada(
            context,
                (s) => s.dataCompra?.year == ano,
            t.labelCompras(ano),
          );
        }

        return BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${dados[i].ano}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
            ],
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      _moeda.format(rod.toY),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
              ),
              touchCallback: (event, response) {
                if (event is! FlTapUpEvent) return;
                final index = response?.spot?.touchedBarGroupIndex;
                if (index != null) aoTocarBarra(index);
              },
            ),
          ),
        );
      },
    );
  }
}

class _TabelaTemas extends ConsumerWidget {
  const _TabelaTemas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dadosAsync = ref.watch(contagemPorTemaProvider);
    final t = AppLocalizations.of(context)!;

    return dadosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErroSeccao(erro: e),
      data: (dados) {
        if (dados.isEmpty) return const _SemDados();

        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columns: [
                  DataColumn(label: Text(t.labelTheme, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.labelSets, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: [
                  for (final linha in dados)
                    DataRow(
                      onSelectChanged: (_) => _abrirListaFiltrada(
                        context,
                            (s) => s.tema == linha.tema,
                        linha.tema,
                      ),
                      cells: [
                        DataCell(Text(linha.tema)),
                        DataCell(Text('${linha.quantidade}')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabelaAnos extends ConsumerWidget {
  const _TabelaAnos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dadosAsync = ref.watch(resumoComprasPorAnoProvider);
    final t = AppLocalizations.of(context)!;

    return dadosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErroSeccao(erro: e),
      data: (dados) {
        if (dados.isEmpty) return const _SemDados();

        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columns: [
                  DataColumn(label: Text(t.labelAno, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.labelSets, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text(t.labelValorTotal, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: [
                  for (final linha in dados)
                    DataRow(
                      onSelectChanged: (_) => _abrirListaFiltrada(
                        context,
                            (s) => s.dataCompra?.year == linha.ano,
                        t.labelCompras(linha.ano),
                      ),
                      cells: [
                        DataCell(Text('${linha.ano}')),
                        DataCell(Text('${linha.quantidade}')),
                        DataCell(Text(_moeda.format(linha.total))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SemDados extends StatelessWidget {
  const _SemDados();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          t.semDados,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}

class _ErroSeccao extends StatelessWidget {
  final Object erro;

  const _ErroSeccao({required this.erro});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          t.loadErrorDashboard(erro),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Formata valores grandes de forma compacta para o eixo Y (ex: 1.2k €).
String _moedaCompacta(double valor) {
  if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}k€';
  return valor.toStringAsFixed(0);
}