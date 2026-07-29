import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'brickset_api_key_dialog.dart';



class BricksetApiSettingsScreen extends ConsumerStatefulWidget {
  const BricksetApiSettingsScreen({super.key});

  @override
  ConsumerState<BricksetApiSettingsScreen> createState() => _BricksetApiSettingsState();
}

class _BricksetApiSettingsState extends ConsumerState<BricksetApiSettingsScreen> {


  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.apiBrickSetTitle)),
      body: ListView(
          children: [
          const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                t.apiBrickSetSTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title:  Text(t.apiBrickSetKeyLabel),
              subtitle:  Text(t.apiBrickSetKeySLabel),
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