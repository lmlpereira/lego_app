import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lego_app/ui/features/login/login_screen.dart';
import 'package:lego_app/ui/features/settings/temas_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/auth_providers.dart';
import '../../../data/sync_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context)!;

    // 1. Obtém o estado assíncrono do utilizador com acesso seguro
    final userAsync = ref.watch(utilizadorAtualProvider);
    final user = userAsync.value;

    // 2. Determina o texto do subtítulo de forma 100% segura sem usar '!'
    final String subtitlePerfil = userAsync.when(
      data: (u) {
        if (u == null || u.uid.isEmpty) return t.profileNoSession;
        return u.username ?? u.nome ?? u.email ?? '';
      },
      loading: () => t.profileLoading,
      error: (_, __) => t.settingsNoSession,
    );



    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsAppBarTitle),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          // --- SECÇÃO: CONTA ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.settingsSectionAccount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title:  Text(t.settingsProfile),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.settingsSectionData,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(t.settingsImportExport),
            subtitle: Text(t.settingsImportExportSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImportScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.category_outlined),
            title:  Text(t.settingsManageThemes),
            subtitle: Text(t.settingsManageThemesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TemasScreen(),
                ),
              );
            },
          ),

          _secaoSincronizacao(context),

          const Divider(),



          // --- SECÇÃO: API ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.settingsSectionApi,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.api_outlined),
            title: Text(t.settingsApiBrickset),
            subtitle: Text(t.settingsApiManage),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.settingsSectionAbout,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title:  Text(t.settingsAppVersion),
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
                Text(
                  t.settingsDevelopedBy,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.companyDeveloped,
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

  Widget _secaoSincronizacao(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(utilizadorAtualProvider).value?.uid;
    final semSessao = uid == null || uid.isEmpty;

    final t = AppLocalizations.of(context)!;

    if (semSessao) {
      return ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text(t.settingsSyncCloudTitle),
        subtitle: Text(t.settingsSyncNoSessionSubtitle),
      );
    }

    final syncState = ref.watch(syncControllerProvider);
    final pendentesAsync = ref.watch(pendenteSyncProvider);
    final pendentes = pendentesAsync.value ?? 0;
    final aSincronizar = syncState.status == SyncStatus.aSincronizar;

    String subtitulo = "";
    IconData icone = Icons.cloud_outlined;
    Color? corIcone;

    switch (syncState.status) {
      case SyncStatus.aSincronizar:
        subtitulo = t.settingsSyncing;
        icone = Icons.sync;
        corIcone = theme.colorScheme.primary;
        break;
      case SyncStatus.erro:
        subtitulo =  syncState.erro ?? t.settingsSyncErrorFallback;
        icone = Icons.sync_problem;
        corIcone = theme.colorScheme.error;
        break;
      case SyncStatus.sucesso:
      case SyncStatus.parado:
        if (syncState.ultimaSincronizacao != null) {
          subtitulo =  t.settingsSyncLastSyncAt(
              DateFormat('HH:mm, dd/MM').format(syncState.ultimaSincronizacao!)) +
              (pendentes > 0 ? t.settingsSyncPendingSuffix(pendentes) : '');
        } else {
          subtitulo = pendentes > 0
              ? t.settingsSyncPendingOnly(pendentes)
              : t.settingsSyncNeverSynced;
        }
        icone = pendentes > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined;
        corIcone = pendentes > 0 ? theme.colorScheme.tertiary : Colors.green;
        break;
    }

    return ListTile(
      leading: Icon(icone, color: corIcone),
      title: Text(t.settingsSyncCloudTitle),
      subtitle: Text(subtitulo),
      trailing: aSincronizar
          ? const SizedBox(
          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
        icon: const Icon(Icons.sync),
        tooltip: t.settingsSyncNowTooltip,
        onPressed: () => ref.read(syncControllerProvider.notifier).sincronizarAgora(),
      ),
    );
  }
}