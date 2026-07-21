import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../repositories/sets_repository.dart';

/// Ecrã de formulário. Se [set] for null, cria um set novo; caso
/// contrário, edita o set passado (usa o mesmo ecrã para os dois casos).
class EditSetScreen extends ConsumerStatefulWidget {
  final LegoSet? set;
  const EditSetScreen({super.key, this.set});

  @override
  ConsumerState<EditSetScreen> createState() => _EditSetScreenState();
}

class _EditSetScreenState extends ConsumerState<EditSetScreen> {
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

  String? _temaSelecionado;
  DateTime? _dataCompra;
  DateTime? _dataVenda;
  bool _vendido = false;
  bool _aGuardar = false;

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
    _temaSelecionado = s?.tema;
    _dataCompra = s?.dataCompra;
    _dataVenda = s?.dataVenda;
    _vendido = s?.vendido ?? false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temasAsync = ref.watch(temasProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_aEditar ? 'Editar set' : 'Novo set')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _numeroSetCtrl,
              decoration: const InputDecoration(labelText: 'Número do set'),
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

            TextFormField(
              controller: _anoCtrl,
              decoration: const InputDecoration(labelText: 'Ano de lançamento (opcional)'),
              keyboardType: TextInputType.number,
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
