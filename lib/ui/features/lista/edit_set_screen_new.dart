import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/brickset_settings.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/sets_repository.dart';
import '../../../services/brickset_service.dart';
import '../settings/brickset_api_key_dialog.dart';
import '../settings/brickset_search_sheet.dart';

/// Ecrã de formulário. Se [set] for null, cria um set novo; caso
/// contrário, edita o set passado (usa o mesmo ecrã para os dois casos).
class EditSetScreenNew extends ConsumerStatefulWidget {
  final LegoSet? set;
  const EditSetScreenNew({super.key, this.set});

  @override
  ConsumerState<EditSetScreenNew> createState() => _EditSetScreenStateNew();
}

class _EditSetScreenStateNew extends ConsumerState<EditSetScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late final TextEditingController _numeroSetCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _anoCtrl;
  late final TextEditingController _valorSetCtrl;
  late final TextEditingController _valorCompradoCtrl;
  late final TextEditingController _quantidadeCtrl;
  late final TextEditingController _valorVendaCtrl;
  late final TextEditingController _notasCtrl;
  late final TextEditingController _pecasCtrl;

  String? _temaSelecionado;
  DateTime? _dataCompra;
  DateTime? _dataVenda;
  bool _vendido = false;
  bool _aGuardar = false;
  String? _imagemUrl;
  bool _aPesquisarBrickset = false;

  bool get _aEditar => widget.set != null;

  @override
  void initState() {
    super.initState();
    final s = widget.set;
    _numeroSetCtrl = TextEditingController(text: s?.numeroSet.toString() ?? '');
    _descricaoCtrl = TextEditingController(text: s?.descricao ?? '');
    _anoCtrl = TextEditingController(text: s?.ano?.toString() ?? '');
    _valorSetCtrl = TextEditingController(text: s?.valorSet.toString() ?? '');
    _valorCompradoCtrl = TextEditingController(text: s?.valorComprado.toString() ?? '');
    _quantidadeCtrl = TextEditingController(text: (s?.quantidade ?? 1).toString());
    _valorVendaCtrl = TextEditingController(text: s?.valorVenda?.toString() ?? '');
    _notasCtrl = TextEditingController(text: s?.notas ?? '');
    _pecasCtrl = TextEditingController(text: s?.pecas?.toString() ?? '');
    _temaSelecionado = s?.tema;
    _dataCompra = s?.dataCompra;
    _dataVenda = s?.dataVenda;
    _vendido = s?.vendido ?? false;
    _imagemUrl = s?.imagemUrl;
  }

  @override
  void dispose() {
    _numeroSetCtrl.dispose();
    _descricaoCtrl.dispose();
    _anoCtrl.dispose();
    _valorSetCtrl.dispose();
    _valorCompradoCtrl.dispose();
    _quantidadeCtrl.dispose();
    _valorVendaCtrl.dispose();
    _notasCtrl.dispose();
    _pecasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temasAsync = ref.watch(temasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_aEditar ? 'Editar set' : 'Novo set'),
        actions: [
          IconButton(
            tooltip: 'API key do Brickset',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showBricksetApiKeyDialog(context, ref),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_imagemUrl != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imagemUrl!,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 160,
                      child: Center(child: Icon(Icons.image_not_supported, size: 48)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _numeroSetCtrl,
              decoration: InputDecoration(
                labelText: 'Número do set',
                helperText: 'Pesquisa no Brickset para preencher automaticamente',
                suffixIcon: _aPesquisarBrickset
                    ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Pesquisar no Brickset',
                  onPressed: _pesquisarBrickset,
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Número inválido' : null,
            ),
            const SizedBox(height: 12),

            temasAsync.when(
              data: (temas) => _temaField(temas),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erro a carregar temas: $e'),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anoCtrl,
                    decoration: const InputDecoration(labelText: 'Ano de lançamento (opcional)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pecasCtrl,
                    decoration: const InputDecoration(labelText: 'Número de peças (opcional)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorSetCtrl,
                    decoration: const InputDecoration(labelText: 'Valor de tabela (€)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _valorCompradoCtrl,
                    decoration: const InputDecoration(labelText: 'Valor pago (€)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                  ),
                ),
              ],
            ),

            // Exibir os dois cards apenas em modo de edição
            if (_aEditar) ...[
              const SizedBox(height: 12),
              _buildCardsDiferenca(),
            ],

            const SizedBox(height: 12),

            TextFormField(
              controller: _quantidadeCtrl,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Inválido' : null,
            ),
            const SizedBox(height: 12),

            _dataField(
              label: 'Data de compra',
              valor: _dataCompra,
              onEscolher: (d) => setState(() => _dataCompra = d),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Já vendido'),
              value: _vendido,
              onChanged: (v) => setState(() => _vendido = v),
            ),

            if (_vendido) ...[
              TextFormField(
                controller: _valorVendaCtrl,
                decoration: const InputDecoration(labelText: 'Valor de venda (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (!_vendido) return null;
                  return (v == null || double.tryParse(v) == null) ? 'Inválido' : null;
                },
              ),
              const SizedBox(height: 12),
              _dataField(
                label: 'Data de venda',
                valor: _dataVenda,
                onEscolher: (d) => setState(() => _dataVenda = d),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _notasCtrl,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _aGuardar ? null : _guardar,
              icon: _aGuardar
                  ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_aEditar ? 'Guardar alterações' : 'Adicionar set'),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói os dois cards com as diferenças calculadas
  Widget _buildCardsDiferenca() {
    final valorSet = double.tryParse(_valorSetCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final valorComprado = double.tryParse(_valorCompradoCtrl.text.replaceAll(',', '.')) ?? 0.0;

    // Cálculo da diferença em Euros (Valor Pago - Valor de Tabela )
    final diferencaEuros =  valorComprado - valorSet;

    // Cálculo da percentagem de diferença (com base no valor de tabela)
    final diferencaPerc = diferencaEuros != 0 ? ((valorComprado * 100) / valorSet) - 100 : 0.0;

    // Cores dinâmicas: verde se comprou abaixo do valor de tabela (poupou/lucrou), vermelho se pagou a mais
    final color = diferencaEuros <= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    'Diferença (€)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${diferencaEuros >= 0 ? '+' : ''}${diferencaEuros.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    'Diferença (%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${diferencaPerc >= 0 ? '' : ''}${diferencaPerc.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _temaField(List<String> temas) {
    // Permite escolher um tema existente OU escrever um novo — não
    // obriga a ir a outro ecrã só para criar um tema.
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _temaSelecionado ?? ''),
      optionsBuilder: (input) {
        if (input.text.isEmpty) return temas;
        return temas.where((t) => t.toLowerCase().contains(input.text.toLowerCase()));
      },
      onSelected: (t) => _temaSelecionado = t,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Tema',
            helperText: 'Escolhe um existente ou escreve um novo',
          ),
          onChanged: (v) => _temaSelecionado = v,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
        );
      },
    );
  }

  Widget _dataField({
    required String label,
    required DateTime? valor,
    required ValueChanged<DateTime?> onEscolher,
  }) {
    return InkWell(
      onTap: () async {
        final agora = DateTime.now();
        final escolhida = await showDatePicker(
          context: context,
          initialDate: valor ?? agora,
          firstDate: DateTime(2000),
          lastDate: DateTime(agora.year + 1),
        );
        if (escolhida != null) onEscolher(escolhida);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(valor == null ? 'Toca para escolher' : _dateFormat.format(valor)),
      ),
    );
  }

  Future<void> _pesquisarBrickset() async {
    final service = await obterBricksetServiceQuandoPronto(ref);
    if (service == null) {
      final configurar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API key do Brickset'),
          content: const Text(
              'Ainda não configuraste a tua API key do Brickset. Queres configurá-la agora?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Agora não')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Configurar')),
          ],
        ),
      );
      if (configurar == true && mounted) {
        await showBricksetApiKeyDialog(context, ref);
      }
      return;
    }

    final numero = _numeroSetCtrl.text.trim();

    // Se já houver um número de set válido escrito, tenta ir logo direto
    // a esse set (uma única chamada) em vez de abrir sempre a pesquisa.
    if (numero.isNotEmpty && int.tryParse(numero) != null) {
      setState(() => _aPesquisarBrickset = true);
      try {
        final resultado = await service.getBySetNumber(numero);
        if (!mounted) return;
        if (resultado != null) {
          _aplicarResultadoBrickset(resultado);
          return;
        }
        // Não encontrou exatamente esse número — cai para a pesquisa livre.
      } on BricksetException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      } finally {
        // Este service é criado ad-hoc (não vem de um provider gerido
        // pelo Riverpod), por isso temos de o fechar nós, senão a ligação
        // http fica aberta.
        service.dispose();
        if (mounted) setState(() => _aPesquisarBrickset = false);
      }
    } else {
      service.dispose();
    }

    if (!mounted) return;
    final escolhido = await showBricksetSearchSheet(context, ref, queryInicial: numero);
    if (escolhido != null) _aplicarResultadoBrickset(escolhido);
  }

  /// Preenche o formulário com os dados vindos do Brickset. Só toca em
  /// imagem, número de peças, ano de lançamento e nome (descrição) —
  /// NUNCA mexe em tema, valor de tabela, valor pago ou qualquer outro
  /// campo financeiro, que ficam sempre por conta do utilizador.
  void _aplicarResultadoBrickset(BricksetSet s) {
    setState(() {


      if(_aEditar){
        _numeroSetCtrl.text = s.number;
        _descricaoCtrl.text = s.descricaoSugerida;
        if (s.year != null) _anoCtrl.text = '${s.year}';
        if (s.pieces != null) _pecasCtrl.text = '${s.pieces}';
        _imagemUrl = s.imageUrl ?? s.thumbnailUrl;
        _temaSelecionado = s.theme;
      }else{
        _numeroSetCtrl.text = s.number;
        _descricaoCtrl.text = s.descricaoSugerida;
        if (s.year != null) _anoCtrl.text = '${s.year}';
        if (s.pieces != null) _pecasCtrl.text = '${s.pieces}';
        _imagemUrl = s.imageUrl ?? s.thumbnailUrl;
        _temaSelecionado = s.theme;
        if (s.precoSugeridoEUR != null) _valorSetCtrl.text = '${s.precoSugeridoEUR}';

      }


    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _aGuardar = true);

    final novoSet = LegoSet(
      id: widget.set?.id,
      numeroSet: int.parse(_numeroSetCtrl.text),
      tema: (_temaSelecionado ?? '').trim().isEmpty ? 'Sem tema' : _temaSelecionado!.trim(),
      descricao: _descricaoCtrl.text.trim(),
      ano: int.tryParse(_anoCtrl.text),
      valorSet: double.parse(_valorSetCtrl.text),
      valorComprado: double.parse(_valorCompradoCtrl.text),
      dataCompra: _dataCompra,
      quantidade: int.parse(_quantidadeCtrl.text),
      vendido: _vendido,
      valorVenda: _vendido ? double.tryParse(_valorVendaCtrl.text) : null,
      dataVenda: _vendido ? _dataVenda : null,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      imagemUrl: _imagemUrl,
      pecas: int.tryParse(_pecasCtrl.text),
    );

    final repo = ref.read(setsRepositoryProvider);
    if (_aEditar) {
      await repo.update(novoSet);
    } else {
      await repo.add(novoSet);
    }

    if (mounted) Navigator.of(context).pop();
  }
}