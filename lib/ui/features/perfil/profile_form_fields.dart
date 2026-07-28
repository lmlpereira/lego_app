import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Campos de perfil partilhados entre o registo por email e o ecrã de
/// completar perfil (usado depois de um primeiro login por Google, que
/// não dá username nenhum). Mantido à parte para não duplicar a mesma
/// validação e layout em dois sítios.
class ProfileFormFields extends StatelessWidget {
  final TextEditingController usernameCtrl;
  final TextEditingController nomeCtrl;
  final TextEditingController idLegoInsidersCtrl;
  final DateTime? dataNascimento;
  final ValueChanged<DateTime?> onDataNascimentoChanged;
  final String? sexo;
  final ValueChanged<String?> onSexoChanged;

  const ProfileFormFields({
    super.key,
    required this.usernameCtrl,
    required this.nomeCtrl,
    required this.idLegoInsidersCtrl,
    required this.dataNascimento,
    required this.onDataNascimentoChanged,
    required this.sexo,
    required this.onSexoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: usernameCtrl,
          decoration: InputDecoration(
            labelText: t.usernameLabel,
            prefixIcon: Icon(Icons.alternate_email),
            helperText: t.helperUsername,
          ),
          validator: (v) {
            final texto = v?.trim() ?? '';
            if (texto.length < 3) return t.usernameError1;
            if (texto.length > 20) return t.usernameError2;
            if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(texto)) {
              return t.usernameError3;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: nomeCtrl,
          decoration: InputDecoration(
            labelText: t.nomeLabel,
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? t.obrigatorioError : null,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final agora = DateTime.now();
            final escolhida = await showDatePicker(
              context: context,
              initialDate: dataNascimento ?? DateTime(agora.year - 20),
              firstDate: DateTime(1920),
              lastDate: agora,
            );
            if (escolhida != null) onDataNascimentoChanged(escolhida);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: t.dataNascimentoLabel,
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            child: Text(
              dataNascimento == null ? t.dataNascimentoHint : dateFormat.format(dataNascimento!),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: idLegoInsidersCtrl,
          decoration: InputDecoration(
            labelText: t.legoInsidersLabel,
            prefixIcon: Icon(Icons.card_membership_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: sexo,
          decoration: InputDecoration(
            labelText: t.sexoLabel,
            prefixIcon: Icon(Icons.wc_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'Outro', child: Text('Outro')),
            DropdownMenuItem(value: 'Prefiro não dizer', child: Text('Prefiro não dizer')),
          ],
          onChanged: onSexoChanged,
        ),
      ],
    );
  }
}