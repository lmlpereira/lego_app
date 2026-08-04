import 'package:flutter/material.dart';
import 'barcode_scanner_screen.dart';
import '../utils/lego_block_style.dart';

class BarcodeTab extends StatelessWidget {
  const BarcodeTab({super.key});

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'Clica no botão abaixo para ler o código de barras da caixa e identificar o set automaticamente.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                // Abre o scanner como um ecrã novo (Full Screen)
                final code = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                );

                if (code != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Código lido: $code')),
                    );
                  }
                  // Aqui podes disparar a lógica para procurar o set
                  print("Código lido: $code");
                }
              },
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