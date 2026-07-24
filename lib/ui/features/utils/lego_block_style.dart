import 'package:flutter/material.dart';

class LegoColors {
  static const Color red = Color(0xFFD32F2F);
  static const Color blue = Color(0xFF1976D2);
  static const Color blueDark = Color(0xFF0D47A1);
  static const Color yellow = Color(0xFFFBC02D);
  static const Color green = Color(0xFF388E3C);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color mediumGrey = Color(0xFFE0E0E0);
}

class LegoBlockDecorator extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;

  const LegoBlockDecorator({
    super.key,
    required this.child,
    this.color = const Color(0xFFEEEEEE),
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        // Em vez de bordas de cores diferentes, usamos sombras bem definidas para o efeito 3D
        boxShadow: [
          // Sombra escura no fundo/direita (Efeito 3D da base do bloco)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(2, 4), // Deslocamento para baixo e para a direita
            blurRadius: 0, // 0 para manter o aspeto rígido de plástico LEGO
          ),
          // Brilho leve no topo/esquerda
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            offset: const Offset(-1, -1),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}