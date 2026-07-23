import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lego_app/ui/features/login/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/auth_providers.dart';
import '../import/import_screen.dart';
import '../perfil/profile_screen.dart';
import 'brickset_api_settings.dart';



class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
            subtitle: Text(
              ref.watch(utilizadorAtualProvider).value?.username ??
                  ref.watch(utilizadorAtualProvider).value?.email ??
                  'Sem sessão',
            ),
            onTap: () {
              // 1. Obtém o estado atual do utilizador
              final user = ref.read(utilizadorAtualProvider).value;

              // 2. Decide para qual ecrã navegar
              final Widget targetScreen = (user?.uid != '')
                  ? const ProfileScreen() // Subtitui pelo nome do teu ecrã de perfil
                  : const LegoLoginScreen();

              // 3. Abre o ecrã correspondente
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => targetScreen,
                ),
              );
            },
          ),

          /*ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Terminar sessão', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmarTerminarSessao(context, ref),
          ),*/

          const Divider(),

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

          // --- SECÇÃO: API ---
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