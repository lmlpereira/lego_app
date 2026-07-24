import 'package:flutter/cupertino.dart';

/// Clipper responsável por cortar a forma de bloco LEGO com os 3 pinos superiores
class LegoBrickClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double studHeight = 5.0;
    const double studRadius = 1.5;
    const double cornerRadius = 16.0;

    final double availableWidth = size.width;
    final double studWidth = availableWidth / 5.5;
    final double spacing = (availableWidth - (3 * studWidth)) / 4;

    path.moveTo(0, studHeight);

    // Pino 1
    double x = spacing;
    path.lineTo(x, studHeight);
    path.lineTo(x, studRadius);
    path.quadraticBezierTo(x, 0, x + studRadius, 0);
    path.lineTo(x + studWidth - studRadius, 0);
    path.quadraticBezierTo(x + studWidth, 0, x + studWidth, studRadius);
    path.lineTo(x + studWidth, studHeight);

    // Pino 2
    x += studWidth + spacing;
    path.lineTo(x, studHeight);
    path.lineTo(x, studRadius);
    path.quadraticBezierTo(x, 0, x + studRadius, 0);
    path.lineTo(x + studWidth - studRadius, 0);
    path.quadraticBezierTo(x + studWidth, 0, x + studWidth, studRadius);
    path.lineTo(x + studWidth, studHeight);

    // Pino 3
    x += studWidth + spacing;
    path.lineTo(x, studHeight);
    path.lineTo(x, studRadius);
    path.quadraticBezierTo(x, 0, x + studRadius, 0);
    path.lineTo(x + studWidth - studRadius, 0);
    path.quadraticBezierTo(x + studWidth, 0, x + studWidth, studRadius);
    path.lineTo(x + studWidth, studHeight);

    path.lineTo(size.width, studHeight);

    // Lado direito e canto inferior direito
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width, size.height,
      size.width - cornerRadius, size.height,
    );

    // Linha inferior
    path.lineTo(cornerRadius, size.height);

    // Canto inferior esquerdo
    path.quadraticBezierTo(
      0, size.height,
      0, size.height - cornerRadius,
    );

    path.lineTo(0, studHeight);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}