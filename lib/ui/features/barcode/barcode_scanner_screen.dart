import 'package:flutter/material.dart';
import 'package:lego_app/ui/features/utils/lego_brick_loading.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Ecrã simples que abre a câmara, deteta o primeiro código de barras
/// válido e devolve-o via Navigator.pop(context, code).
///
/// Uso:
/// final code = await Navigator.push<String>(
///   context,
///   MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
/// );
/// if (code != null) { ... }
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA],
    // Por omissão o mobile_scanner analisa TODOS os frames da câmara
    // (DetectionSpeed.unrestricted). Em alguns dispositivos (sobretudo
    // Xiaomi/MIUI) isto acumula mais frames do que o CameraX consegue
    // libertar a tempo, e a sessão de câmara acaba por rebentar com
    // "Device error code 3" / "Already acquired max frames". Restringir
    // a velocidade resolve isso.
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
    // Sem isto, o plugin pede à câmara streams a 1600x1200 / 1920x1440.
    // Neste hardware (MediaTek + camada Xiaomi) o buffer de imagens só
    // aguenta 5 frames em voo, e a esses tamanhos esgota-se quase de
    // imediato — a câmara rebenta logo no arranque, antes de conseguires
    // apontar a nada, e o preview fica todo preto. Pedir uma resolução
    // mais baixa (suficiente para ler códigos de barras) resolve.
    cameraResolution: const Size(1280, 720),
  );

  bool _jaDetetado = false; // evita disparar o pop múltiplas vezes
  bool _aProcessar = false; // controla o overlay de loading pós-deteção

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_jaDetetado) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _jaDetetado = true;

        // Mostra o overlay de loading imediatamente
        setState(() => _aProcessar = true);

        // Primeiro navegamos de volta com o código.
        // O pop deve acontecer antes do stop para ser instantâneo.
        if (!mounted) return;
        Navigator.pop(context, code);

        // O stop() e dispose() serão tratados pelo ciclo de vida
        // do widget, mas podemos chamar o stop aqui sem o 'await'
        // para libertar o hardware o quanto antes sem bloquear a UI.
        _controller.stop();
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler código de barras'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Aponta a câmara para o código de barras da caixa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
          if (_aProcessar)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1976D2), // Azul sólido (LegoColors.blue)
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LegoBrickLoading(),
                      SizedBox(height: 16),
                      Text(
                        'A identificar o set...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}