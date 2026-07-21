import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../services/xlsx_import_service.dart';

/// Estados possíveis do ecrã, para a UI saber o que mostrar.
sealed class _ImportState {
  const _ImportState();
}

class _Idle extends _ImportState {
  const _Idle();
}

class _Importando extends _ImportState {
  const _Importando();
}

class _Sucesso extends _ImportState {
  final int quantidade;
  const _Sucesso(this.quantidade);
}

class _Erro extends _ImportState {
  final String mensagem;
  const _Erro(this.mensagem);
}

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _ImportState _estado = const _Idle();
  String? _ficheiroEscolhido;

  Future<void> _escolherEImportar() async {
    final xTypeGroup = XTypeGroup(
      label: 'xlsx',
      extensions: ['xlsx'],
      // No Android, o picker filtra por MIME type, não por extensão —
      // sem isto, o ficheiro .xlsx aparece a cinzento e não é selecionável.
      // Incluímos também 'application/octet-stream' porque muitos
      // gestores de ficheiros Android reportam .xlsx sob esse MIME
      // genérico em vez do MIME correto do Office.
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/octet-stream',
      ],
    );
    final ficheiro = await openFile(acceptedTypeGroups: [xTypeGroup]);

    // Utilizador cancelou o picker.
    if (ficheiro == null) return;

    final path = ficheiro.path;
    setState(() {
      _ficheiroEscolhido = ficheiro.name;
      _estado = const _Importando();
    });

    try {
      final sets = await XlsxImportService().importFromFile(path);

      if (sets.isEmpty) {
        setState(() => _estado = const _Erro(
            'Não encontrei nenhuma linha válida na folha "Lista Sets". '
                'Confirma que o ficheiro tem essa folha e que a primeira coluna (Número) está preenchida.'));
        return;
      }

      final inseridos = await ref.read(setsRepositoryProvider).addAll(sets);
      setState(() => _estado = _Sucesso(inseridos as int));
    } catch (e) {
      setState(() => _estado = _Erro(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar xlsx')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Escolhe o teu ficheiro "Lista Legos (STOCK).xlsx".\n'
                    'Vou ler a folha "Lista Sets" e adicionar os dados à base de dados local.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _conteudoPorEstado(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conteudoPorEstado() {
    switch (_estado) {
      case _Idle():
        return FilledButton.icon(
          onPressed: _escolherEImportar,
          icon: const Icon(Icons.folder_open),
          label: const Text('Escolher ficheiro'),
        );

      case _Importando():
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('A importar ${_ficheiroEscolhido ?? ''}...'),
          ],
        );

      case _Sucesso(quantidade: final n):
        return Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 12),
            Text('$n sets importados com sucesso!'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _estado = const _Idle()),
              icon: const Icon(Icons.refresh),
              label: const Text('Importar outro ficheiro'),
            ),
          ],
        );

      case _Erro(mensagem: final msg):
        return Column(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _estado = const _Idle()),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        );
    }
  }
}