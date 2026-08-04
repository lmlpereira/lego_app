import 'package:flutter/material.dart';

import '../../../services/brickset_service.dart';


/// Folha modal mostrada depois do lookup por código de barras ter sucesso.
/// `jaNaColecao` diz-te se o set já existe na tua coleção (comparado por
/// numeroSet). `onAdicionar` só é chamado se o utilizador ainda não o
/// tiver e carregar no botão.
class SetFoundSheet extends StatelessWidget {
  final BricksetSet set;
  final bool jaNaColecao;
  final VoidCallback? onAdicionar;

  const SetFoundSheet({
    super.key,
    required this.set,
    required this.jaNaColecao,
    this.onAdicionar,
  });

  static Future<void> show(
      BuildContext context, {
        required BricksetSet set,
        required bool jaNaColecao,
        VoidCallback? onAdicionar,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SetFoundSheet(
        set: set,
        jaNaColecao: jaNaColecao,
        onAdicionar: onAdicionar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagem = set.imageUrl ?? set.thumbnailUrl;
    final preco = set.precoSugeridoEUR;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imagem != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imagem,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(Icons.widgets_outlined, size: 32),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${set.numeroCompleto}'
                            '${set.year != null ? ' · ${set.year}' : ''}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (set.theme.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          set.subtheme.isNotEmpty
                              ? '${set.theme} · ${set.subtheme}'
                              : set.theme,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (set.pieces != null)
                            _Chip(icon: Icons.extension, label: '${set.pieces} peças'),
                          if (set.minifigs != null && set.minifigs! > 0)
                            _Chip(
                              icon: Icons.emoji_people,
                              label: '${set.minifigs} minifigs',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (preco != null) ...[
              const SizedBox(height: 12),
              Text(
                set.precoSugeridoEAproximado
                    ? 'Preço de tabela aproximado: €${preco.toStringAsFixed(2)}'
                    : 'Preço de tabela: €${preco.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            if (jaNaColecao)
              const _Estado(
                icone: Icons.check_circle,
                cor: Colors.green,
                texto: 'Já tens este set na coleção',
              )
            else ...[
              const _Estado(
                icone: Icons.info_outline,
                cor: Colors.orange,
                texto: 'Ainda não tens este set na coleção',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar à coleção'),
                  onPressed: onAdicionar == null
                      ? null
                      : () {
                    onAdicionar!.call();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String texto;

  const _Estado({required this.icone, required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: cor),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: TextStyle(color: cor))),
      ],
    );
  }
}