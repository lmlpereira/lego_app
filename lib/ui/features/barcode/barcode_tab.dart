import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lista/edit_set_screen_new.dart';
import '../utils/lego_block_style.dart';
import 'scanflow.dart';

class BarcodeTab extends ConsumerWidget {
  const BarcodeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.barcode_reader, size: 80, color: LegoColors.blueDark),
            const SizedBox(height: 20),
            const Text(
              'Tens um novo set para adicionar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Clica no botão abaixo para ler o código de barras da caixa e identificar o set automaticamente.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => iniciarFluxoDeScan(
                context,
                ref,
                // Set ainda não está na coleção e o utilizador carregou em
                // "Adicionar à coleção" na SetFoundSheet: abre o formulário
                // de "Novo Set" já pré-preenchido com os dados do Brickset,
                // deixando o valor pago/data de compra por preencher.
                onSetNaoEncontrado: (set) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditSetScreenNew(initialBricksetSet: set),
                  ),
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('ABRIR SCANNER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LegoColors.blueDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}