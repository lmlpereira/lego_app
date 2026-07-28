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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        // Os providers são streams ligadas à BD, mas o "pull to refresh"
        // dá ao utilizador uma confirmação visual de que os dados estão
        // atualizados, mesmo não sendo estritamente necessário.
        onRefresh: () async {
          ref.invalidate(totalComprasProvider);
          ref.invalidate(totalVendasProvider);
          ref.invalidate(totalValorSetProvider);
          ref.invalidate(comprasPorAnoProvider);
          ref.invalidate(contagemPorTemaProvider);
          ref.invalidate(resumoComprasPorAnoProvider);
          ref.invalidate(todosOsSetsProvider);
        },
        // NOTA: esta lista NÃO é `const` de propósito — os providers do
        // Riverpod (totalComprasProvider, etc.) são `final`, não `const`,
        // por isso não podem ser passados como argumentos dentro de uma
        // lista de widgets `const`.
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
              child: SizedBox(height: 220, child: _GraficoUltimosAnos()),
            ),
            const SizedBox(height: 24),
            _SeccaoCartao(
              titulo: t.titleSetsTema,
              child: _TabelaTemas(),
            ),
            const SizedBox(height: 24),
            _SeccaoCartao(
              titulo: t.titleComprasAno,
              child: _TabelaAnos(),
            ),
          ],
        ),
      ),
    );
  }
}

// Funções de cálculo passadas a _CartoesComparacao — a poupança usa o
// valor de tabela como base, o lucro usa o valor pago como base; não há
// uma fórmula genérica única para os dois casos.
double _poupanca(double compras, double sets) => sets - compras;
double _poupancaPercent(double compras, double sets) =>
    sets > 0 ? (sets - compras) / sets * 100 : 0;
double _lucro(double vendas, double comprasVendidos) => vendas - comprasVendidos;
double _lucroPercent(double vendas, double comprasVendidos) =>
    comprasVendidos > 0 ? (vendas - comprasVendidos) / comprasVendidos * 100 : 0;

/// Abre o ecrã de lista com os sets que passam em [filtro]. O ecrã
/// observa a BD diretamente, por isso não precisamos de lhe passar uma
/// lista já calculada aqui.
void _abrirListaFiltrada(
    BuildContext context,
    bool Function(LegoSet) filtro,
    String titulo,
    ) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => SetsFilteredListScreen(titulo: titulo, filtro: filtro),
  ));
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
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ---------------- Cartões comparativos (compras/sets, vendas/compras) ----------------

/// Par de cartões (A e B) mais uma faixa por baixo com a diferença em
/// euros e percentagem. Ambos os cartões são clicáveis e abrem a mesma
/// lista de sets (definida por [filtro]), porque representam o mesmo
/// conjunto de registos visto de duas métricas diferentes.
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
      clipBehavior: Clip.antiAlias,
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
                  Icon(icone, color: cor),
                  Icon(Icons.chevron_right,
                      size: 18, color: Theme.of(context).colorScheme.outline),
                ],
              ),
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
      ),
    );
  }
}

/// Faixa fina por baixo do par de cartões, com a diferença em euros e
/// percentagem. Só aparece quando os dois valores já chegaram.
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
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(positivo ? Icons.arrow_upward : Icons.arrow_downward,
              color: cor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
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

// ---------------- Gráfico: compras dos últimos 5 anos ----------------

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

        // comprasPorAnoProvider já vem ordenado ascendentemente por ano;
        // basta pegar nos últimos 5.
        final dados = todosOsDados.length > 5
            ? todosOsDados.sublist(todosOsDados.length - 5)
            : todosOsDados;

        final maxY = dados.map((d) => d.total).reduce((a, b) => a > b ? a : b);

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
                      width: 28,
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
              // Toque numa barra -> abre a lista de sets comprados
              // naquele ano. Usamos FlTapUpEvent (em vez do callback de
              // "touch" genérico) para não disparar em cada hover/drag.
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

// ---------------- Tabela: sets por tema ----------------

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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            // Sem coluna de checkbox — as linhas continuam clicáveis
            // através de onSelectChanged, só sem o quadradinho visual.
            showCheckboxColumn: false,
            columns: [
              DataColumn(label: Text(t.labelTheme)),
              DataColumn(label: Text(t.labelSets), numeric: true),
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
        );
      },
    );
  }
}

// ---------------- Tabela: compras por ano ----------------

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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: [
              DataColumn(label: Text(t.labelAno)),
              DataColumn(label: Text(t.labelSets), numeric: true),
              DataColumn(label: Text(t.labelValorTotal), numeric: true),
            ],
            rows: [
              for (final linha in dados)
                DataRow(
                  // Consistente com a tabela de temas e o gráfico: tocar
                  // num ano mostra os sets comprados nesse ano.
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