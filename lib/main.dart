import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'features/import/import_screen.dart';
import 'features/lista/sets_list_screen.dart';

void main() {
  // ProviderScope tem de envolver a app para os providers do Riverpod
  // (setsRepositoryProvider, totalComprasProvider, etc.) funcionarem.
  runApp(const ProviderScope(child: LegoApp()));
}

class LegoApp extends StatelessWidget {
  const LegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lego App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Ecrã inicial temporário — só para confirmar que a BD e os providers
/// estão a funcionar. Vai ser substituído pelo dashboard.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCompras = ref.watch(totalComprasProvider);
    final totalVendas = ref.watch(totalVendasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lego App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total compras: ${totalCompras.value?.toStringAsFixed(2) ?? '...'} €'),
            const SizedBox(height: 8),
            Text('Total vendas: ${totalVendas.value?.toStringAsFixed(2) ?? '...'} €'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar xlsx'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SetsListScreen()),
              ),
              icon: const Icon(Icons.list),
              label: const Text('Ver os meus sets'),
            ),
          ],
        ),
      ),
    );
  }
}
