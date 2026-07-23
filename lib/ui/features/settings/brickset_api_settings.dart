import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import 'brickset_api_key_dialog.dart';



class BricksetApiSettingsScreen extends ConsumerStatefulWidget {
  const BricksetApiSettingsScreen({super.key});

  @override
  ConsumerState<BricksetApiSettingsScreen> createState() => _BricksetApiSettingsState();
}

class _BricksetApiSettingsState extends ConsumerState<BricksetApiSettingsScreen> {


  @override
  Widget build(BuildContext context) {

    final temasAsync = ref.watch(temasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('API BrickSet')),
      body: ListView(
          children: [
          const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Gestão da API',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Chave da API'),
              subtitle: const Text('Devinir a chave da API'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showBricksetApiKeyDialog(context, ref);
              },
            ),

            const Divider(),
      ]
    )
    );
  }



}