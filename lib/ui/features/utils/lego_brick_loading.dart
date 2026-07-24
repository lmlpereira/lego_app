import 'package:flutter/material.dart';

class LegoBrickLoading extends StatefulWidget {
  final double width;
  final double height;

  const LegoBrickLoading({
    super.key,
    this.width = 120,
    this.height = 120,
  });

  @override
  State<LegoBrickLoading> createState() => _LegoBrickLoadingState();
}

class _LegoBrickLoadingState extends State<LegoBrickLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Cores clássicas dos blocos LEGO
  final List<Color> _brickColors = const [
    Color(0xFFE3000B), // Vermelho
    Color(0xFFFFD500), // Amarelo
    Color(0xFF0055BF), // Azul
    Color(0xFF00843D), // Verde
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final totalBricks = _brickColors.length;
          final progress = _controller.value;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: List.generate(totalBricks, (index) {
              // Cada bloco tem o seu intervalo de tempo para cair
              final startTime = index / totalBricks;
              final endTime = (index + 1) / totalBricks;

              double brickOffsetY = 0.0;
              double opacity = 1.0;

              if (progress < startTime) {
                // Bloco ainda não começou a cair (invisível no topo)
                brickOffsetY = -100;
                opacity = 0.0;
              } else if (progress >= startTime && progress <= endTime) {
                // Bloco a cair com efeito de mola/impacto (CurvedAnimation)
                final localProgress =
                    (progress - startTime) / (endTime - startTime);
                final curveValue = Curves.bounceOut.transform(localProgress);

                // Vai da posição inicial superior até a posição de empilhamento
                brickOffsetY = -100 * (1 - curveValue);
                opacity = 1.0;
              } else {
                // Bloco já assentou na pilha
                brickOffsetY = 0.0;
                opacity = 1.0;
              }

              // Posição final empilhada na base
              final bottomMargin = index * 22.0;

              return Positioned(
                bottom: bottomMargin,
                child: Transform.translate(
                  offset: Offset(0, brickOffsetY),
                  child: Opacity(
                    opacity: opacity,
                    child: _buildLegoBrick(_brickColors[index]),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Desenha um único bloco LEGO (com pinos no topo)
  Widget _buildLegoBrick(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pinos (Studs) no topo do bloco
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
                (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 4,
              decoration: BoxDecoration(
                color: HSLColor.fromColor(color).withLightness(0.4).toColor(),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          ),
        ),
        // Corpo do bloco
        Container(
          width: 54,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}