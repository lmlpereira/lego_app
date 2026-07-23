import 'package:flutter/material.dart';
import 'package:lego_app/ui/features/login/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../import/import_screen.dart';
import 'brickset_api_settings.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'A carregar...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _carregarInformacaoNativa();
  }

  Future<void> _carregarInformacaoNativa() async {
    // Obtém as informações do APK/AppBundle/IPA nativo
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;     // Ex: "1.0.0"
        _buildNumber = info.buildNumber; // Ex: "1" ou "100"
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);



    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações Gerais'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          // --- SECÇÃO: DADOS ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Gestão de Dados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Importar / Exportar Excel'),
            subtitle: const Text('Fazer cópia de segurança ou carregar dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImportScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // --- SECÇÃO: CONTA ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Configurações da API',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.api_outlined),
            title: const Text('API BrickSet'),
            subtitle: const Text('Gerir API'),

            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BricksetApiSettingsScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // --- SECÇÃO: CONTA ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Conta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            subtitle: const Text('Gerir preferências do utilizador'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Text(
                'Em desenvolvimento',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LegoLoginScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // --- SECÇÃO: SOBRE A APP ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Sobre',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versão da App'),
            // Exibe a versão lida diretamente do sistema nativo
            subtitle: Text('v$_appVersion${_buildNumber.isNotEmpty ? " (Build $_buildNumber)" : ""}'),
          ),

          const SizedBox(height: 32),

          // --- RODAPÉ / CRÉDITOS ---
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.code,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DEVELOPED BY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dev4You - Luis Pereira',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}