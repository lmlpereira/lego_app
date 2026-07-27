import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:google_fonts/google_fonts.dart';



class LegoInsidersCard extends StatelessWidget {
  final String insidersId;
  final String userName; // Mantido por compatibilidade, mas não usado no visual da imagem

  const LegoInsidersCard({
    super.key,
    required this.insidersId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // Definição da cor roxa oficial baseada na imagem fornecida
    const Color insidersPurple = Color(0xFF502379);

    return Container(
      width: 320,
      // Decoração exterior do cartão (Roxo com cantos arredondados)
      decoration: BoxDecoration(
        color: insidersPurple, //
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. Cabeçalho (Logótipo e Texto insiders) ---
          /*Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                // Logótipo LEGO (Quadrado Vermelho)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: legoRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'LEGO',
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Texto "insiders"
                const Text(
                  'insiders',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),*/

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Espaçamento à volta da imagem
                decoration: BoxDecoration(
                  color: Colors.white, // Fundo branco
                  borderRadius: BorderRadius.circular(6), // Cantos ligeiramente arredondados (opcional)
                ),
                child: Image.asset(
                  'assets/insiders.png',
                  height: 50, // Reduzi a altura para encaixar bem no container (ajusta conforme necessário)
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'LEGO® insiders',
                      style: TextStyle(
                        color: Colors.black, // Texto em preto caso falhe a imagem sobre o fundo branco
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Linha divisória fina e subtil
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),

          const SizedBox(height: 20),

          // --- 2. Texto Central "Your LEGO® Insiders Card" ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your LEGO® Insiders Card',
              style: GoogleFonts.varelaRound(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- 3. Zona do Código de Barras (Caixa Branca) ---
          Container(
            // Margem exterior para criar o efeito de moldura roxa do cartão
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Gerador do Código de Barras
                BarcodeWidget(
                  barcode: Barcode.code128(), // Tipo comum para cartões de membro
                  data: insidersId, // O ID real do utilizador
                  height: 100, // Altura aproximada à imagem
                  drawText: false, // Não desenhar o texto automático do pacote
                  errorBuilder: (context, error) => const Text('Erro ao gerar código'),
                ),
                const SizedBox(height: 10),
                // Número do ID formatado por baixo
                Text(
                  _formatarIdComEspacos(insidersId),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'monospace', // Fonte mono para números alinhados
                    letterSpacing: 3.0, // Espaçamento largo entre os números conforme imagem
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5), // Espaço final inferior
        ],
      ),
    );
  }

  /// Função auxiliar para formatar o ID visualmente com espaços.
  /// Insere um espaço a cada 4 dígitos.
  String _formatarIdComEspacos(String id) {
    if (id.length <= 4) return id;
    return id.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ");
  }
}