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
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Obtém o estado assíncrono do utilizador com acesso seguro
    final userAsync = ref.watch(utilizadorAtualProvider);
    final user = userAsync.value;

    // 2. Determina o texto do subtítulo de forma 100% segura sem usar '!'
    final String subtitlePerfil = userAsync.when(
      data: (u) {
        if (u == null || u.uid.isEmpty) return 'Sem sessão (Visitante)';
        return u.username ?? u.nome ?? u.email ?? 'Perfil Construtor';
      },
      loading: () => 'A carregar perfil...',
      error: (_, __) => 'Sem sessão',
    );

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
            subtitle: Text(subtitlePerfil), // ✅ Subtítulo seguro
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // ✅ Verificação segura: só vai para o Perfil se houver utilizador ativo e com UID
              final bool temSessaoAtiva = user != null && user.uid.isNotEmpty;

              final Widget targetScreen = temSessaoAtiva
                  ? const ProfileScreen()
                  : const LegoLoginScreen();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => targetScreen,
                ),
              );
            },
          ),

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
            title: const Text('Importar Excel'),
            subtitle: const Text('Carregar dados'),
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
            trailing: const Icon(Icons.chevron_right),
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
            subtitle: Text(
              'v$_appVersion${_buildNumber.isNotEmpty ? " (Build $_buildNumber)" : ""}',
            ),
          ),

          const SizedBox(height: 32),

          // --- RODAPÉ / CRÉDITOS ---
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
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