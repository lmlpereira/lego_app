import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lego_app/ui/features/utils/lego_block_style.dart';

import '../../../data/repositories/sets_repository.dart';

/// Card individual formatado fielmente com base no design de cartão arredondado
class LegoSetCard extends StatelessWidget {
  final LegoSet legoSet;
  final VoidCallback? onTap;

  static const tagRed = LegoColors.red;
  static const cardBg = Colors.white;
  static const imageBg = Color(0xFFF5F5F7);
  static const avatarBg = Colors.white;
  static const textPrimary = Color(0xFF1D1D1F);
  static const textSecondary = Color(0xFF6E6E73);

  const LegoSetCard({
    super.key,
    required this.legoSet,
    this.onTap,
  });

  /// Formatação do subtítulo (ex: "6.167 peças • O Senhor dos Anéis")
  String get _subtitleText {
    final parts = <String>[];

    if (legoSet.pecas != null && legoSet.pecas! > 0) {
      final formattedPieces = legoSet.pecas.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
      );
      parts.add('$formattedPieces peças');
    }

    if (legoSet.tema.isNotEmpty) {
      parts.add(legoSet.tema);
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Quadrado da Imagem / Avatar à esquerda
                _buildAvatar(),
                const SizedBox(width: 14),
                // Informações: Set #... em vermelho, Descrição e Peças • Tema
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Número do Set destacado em vermelho (ex: Set #10316)
                      Text(
                        'Set #${legoSet.numeroSet}',
                        style: const TextStyle(
                          color: tagRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Descrição / Nome do Set
                      Text(
                        legoSet.descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtítulo: Peças • Tema
                      Text(
                        _subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tag vermelha de "Vendido" à direita
                if (legoSet.vendido) ...[
                  const SizedBox(width: 8),
                  _buildSoldTag(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o quadrado arredondado cinza da esquerda (Imagem ou Avatar)
  Widget _buildAvatar() {
    const double size = 68;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: legoSet.imagemUrl != null && legoSet.imagemUrl!.isNotEmpty
          ? Padding(
        padding: const EdgeInsets.all(4),
        child: Image.network(
          legoSet.imagemUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(),
        ),
      )
          : _buildFallbackIcon(),
    );
  }

  /// Ícone vermelho estilizado de blocos LEGO caso não haja imagem
  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        Icons.widgets_rounded,
        color: tagRed.withValues(alpha: 0.85),
        size: 32,
      ),
    );
  }

  /// Avatar de fallback com círculo e inicial do Tema
  Widget _buildLetterAvatar() {
    final initialLetter = legoSet.tema.isNotEmpty
        ? legoSet.tema[0].toUpperCase()
        : 'L';

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: avatarBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initialLetter,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Ícone de etiqueta/tag vermelha que representa o estado "Vendido"
  Widget _buildSoldTag() {
    return Transform.rotate(
      angle: -0.2,
      child: const Icon(
        Icons.local_offer,
        color: tagRed,
        size: 22,
      ),
    );
  }
}