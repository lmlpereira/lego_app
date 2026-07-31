import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../data/auth_providers.dart';
import '../../../data/locale_providers.dart';
import '../../../data/providers.dart';
import '../../../data/sync_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../utils/lego_block_style.dart';
import '../utils/lego_brick_loading.dart';
import '../utils/lego_insiders_card.dart';
import 'delete_account.dart';
import 'edit_profile_screen.dart';

/// Ecrã principal do Perfil do Utilizador com Estatísticas,
/// Gamificação (XP e Conquistas) e Gestão da Conta.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body:  CustomScrollView(
          slivers: [
            // 🔹 Barra Superior
            SliverAppBar(
              backgroundColor: LegoColors.red,
              elevation: 0,
              scrolledUnderElevation: 0,
              floating: true,
              centerTitle: false,
              title: Text(
                t.profileTitle,
                style: GoogleFonts.varelaRound(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              actions: [
                /*IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: LegoColors.blueDark),
                  onPressed: () {},
                ),*/
              ],
            ),

            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card do Avatar e Identificação
                    _buildUserCard(context, ref),

                    const SizedBox(height: 16),

                    // Grelha de 3 Estatísticas (Sets, Peças e Tema Favorito)
                    _buildStatsGrid(ref, context),

                    const SizedBox(height: 16),

                    // Card de Gamificação: Nível & XP
                    /*_buildGamificationCard(context, ref),

                    const SizedBox(height: 16),

                    // Secção de Conquistas & Badges
                    _buildBadgesSection(context, ref),

                    const SizedBox(height: 16),*/

                    // Menu de Opções / Definições
                    _buildSettingsMenu(context, ref),

                    const SizedBox(height: 20),

                    // Botão de Apagar Conta
                    LegoBlockDecorator(
                      color: LegoColors.red,
                      borderRadius: 10,
                      child: InkWell(
                        onTap: () => showDeleteAccountDialog(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                t.apagarConta,
                                style: GoogleFonts.varelaRound(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botão de Terminar Sessão (Sair)
                    LegoBlockDecorator(
                      color: LegoColors.red,
                      borderRadius: 10,
                      child: InkWell(
                        onTap: () => _confirmarLogout(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                t.sairConta,
                                style: GoogleFonts.varelaRound(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),

    );
  }

  /// Card Principal com Avatar, Nome e Tag de Nível
  Widget _buildUserCard(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final userAsync = ref.watch(utilizadorAtualProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: userAsync.when(
        data: (user) {
          final username = user?.nome ?? user?.username ?? 'Luis Pereira';
          final insidersId = user?.idLegoInsiders;
          final temInsidersId = insidersId != null && insidersId.trim().isNotEmpty;

          return Row(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  LegoBlockDecorator(
                    color: LegoColors.yellow,
                    borderRadius: 12,
                    child: Container(
                      width: 70,
                      height: 70,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/lego_minifig.png',
                        height: 55,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 45,
                          color: LegoColors.blueDark,
                        ),
                      ),
                    ),
                  ),
                  // Botão de Editar Foto
                  /*Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: LegoColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),*/
                ],
              ),
              const SizedBox(width: 16),

              // Informações do Utilizador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.varelaRound(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LegoColors.blueDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: LegoColors.yellow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user?.username  ?? ""  ,
                        style: GoogleFonts.varelaRound(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LegoColors.blueDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (temInsidersId)
                IconButton(
                  icon: const Icon(Icons.badge_outlined, color: LegoColors.blueDark),
                  tooltip: t.cartaoInsiders,
                  onPressed: () => showInsidersCardDialog(
                    context,
                    insidersId,
                    username,
                  ),
                ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            t.loadProfileError,
            style: GoogleFonts.varelaRound(color: LegoColors.red),
          ),
        ),
      ),
    );
  }

  /// Estatísticas da Coleção (3 Cartões: Sets, Peças e Tema Favorito)
  Widget _buildStatsGrid(WidgetRef ref, BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final formatter = NumberFormat('#,##0', 'pt_PT');

    final totalSetsAsync = ref.watch(totalSetsProvider);
    final totalPecasAsync = ref.watch(totalPecasProvider);
    final temaFavoritoAsync = ref.watch(temaFavoritoProvider);

    final totalSetsTexto = totalSetsAsync.when(
      data: (val) => formatter.format(val.toInt()),
      loading: () => '...',
      error: (_, __) => '47',
    );

    final totalPecasTexto = totalPecasAsync.when(
      data: (val) => formatter.format(val.toInt()),
      loading: () => '...',
      error: (_, __) => '34.820',
    );

    final temaFavoritoTexto = temaFavoritoAsync.when(
      data: (tema) => tema?.tema ?? t.noThemeYet,
      loading: () => '...',
      error: (_, __) => '-',
    );



    /*return Row(
      children: [
        Expanded(
          child: _buildStatCard(t.setsLabel, totalSetsTexto, LegoColors.yellow, Icons.view_in_ar_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(t.pecasLabel, totalPecasTexto, Colors.blue, Icons.extension),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(t.favoriteThemeLabel, temaFavoritoTexto, Colors.purple, Icons.palette_outlined),
        ),
      ],
    );*/

    return Column(
      children: [
        // Primeiramente: 2 cards na primeira linha
        Row(
          children: [
            Expanded(
              child: _buildStatCard(t.setsLabel, totalSetsTexto, LegoColors.yellow, Icons.view_in_ar_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(t.pecasLabel, totalPecasTexto, Colors.blue, Icons.extension),
            ),
          ],
        ),
        const SizedBox(height: 10), // Espaçamento vertical entre as linhas
        // Em seguida: 1 card na segunda linha
        Row(
          children: [
            Expanded(
              child: _buildStatCard(t.favoriteThemeLabel, temaFavoritoTexto, Colors.purple, Icons.palette_outlined),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.varelaRound(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: GoogleFonts.varelaRound(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: LegoColors.blueDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Cartão de Nível e Progresso de XP
  Widget _buildGamificationCard(BuildContext context, WidgetRef ref) {
    final totalPecasAsync = ref.watch(totalPecasProvider);
    final pecas = totalPecasAsync.value ?? 34820;

    final nivel = (pecas / 10000).floor() + 1;
    final xpAtual = pecas % 10000;
    final xpProximoNivel = 10000;
    final progresso = (xpAtual / xpProximoNivel).clamp(0.0, 1.0);

    final formatter = NumberFormat('#,##0', 'pt_PT');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nível $nivel: ${formatter.format(xpAtual)} / ${formatter.format(xpProximoNivel)} XP',
                style: GoogleFonts.varelaRound(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LegoColors.blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  /// Painel de Conquistas & Badges
  Widget _buildBadgesSection(BuildContext context, WidgetRef ref) {
    final totalPecas = ref.watch(totalPecasProvider).value ?? 34820;

    final conquistas = [
      _BadgeInfo(
        titulo: '[10k Club]',
        descricao: 'Ultrapassaste 10.000 peças',
        icone: Icons.emoji_events_outlined,
        corIcone: LegoColors.yellow,
        desbloqueado: totalPecas >= 10000,
      ),
      _BadgeInfo(
        titulo: '[Caçador]',
        descricao: 'Compraste um set com 30% desconto',
        icone: Icons.ads_click_outlined,
        corIcone: Colors.green,
        desbloqueado: true,
      ),
      _BadgeInfo(
        titulo: '[Negociador]',
        descricao: 'Vendeste o teu primeiro set com lucro',
        icone: Icons.work_outline,
        corIcone: Colors.brown,
        desbloqueado: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONQUISTAS & GAMIFICAÇÃO',
            style: GoogleFonts.varelaRound(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: conquistas.map((badge) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badge.corIcone.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        badge.icone,
                        color: badge.corIcone,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.varelaRound(
                            fontSize: 13,
                            color: LegoColors.blueDark,
                          ),
                          children: [
                            TextSpan(
                              text: '${badge.titulo} - ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: badge.descricao,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Lista de Definições / Opções do Perfil
  Widget _buildSettingsMenu(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final idiomaAtual = ref.watch(localeControllerProvider)?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LegoColors.blueDark, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline,
                title: t.editarPerfilLabel,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.language,
                title: t.profileLanguage,
                subtitle: t.profileLanguageSubtitle(idiomaAtual),
                onTap: () => _dialogIdioma(context, ref),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: t.ajudaesuporte,
                onTap: () => _dialogSuporte(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: LegoColors.blueDark),
      title: Text(
        title,
        style: GoogleFonts.varelaRound(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: LegoColors.blueDark,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
        subtitle,
        style: GoogleFonts.varelaRound(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// Diálogo de Escolha de Idioma
  void _dialogIdioma(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final idiomaAtual = ref.read(localeControllerProvider)?.languageCode ??
        Localizations.localeOf(context).languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LegoColors.blueDark, width: 3),
        ),
        title: Text(
          t.languageDialogTitle,
          style: GoogleFonts.coiny(color: LegoColors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'pt',
              groupValue: idiomaAtual,
              title: Text(t.languagePortuguese, style: GoogleFonts.varelaRound()),
              onChanged: (valor) {
                if (valor == null) return;
                ref.read(localeControllerProvider.notifier).definirIdioma(valor);
                Navigator.of(ctx).pop();
              },
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: idiomaAtual,
              title: Text(t.languageEnglish, style: GoogleFonts.varelaRound()),
              onChanged: (valor) {
                if (valor == null) return;
                ref.read(localeControllerProvider.notifier).definirIdioma(valor);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.commonCancel,
              style: GoogleFonts.varelaRound(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo com Cartão Insiders
  Future<void> showInsidersCardDialog(
      BuildContext context,
      String insidersId,
      String userName,
      ) async {
    double brightnessAnterior = 0.5;

    try {
      brightnessAnterior = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Erro ao alterar o brilho do ecrã: $e');
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LegoInsidersCard(
                  insidersId: insidersId,
                  userName: userName,
                ),
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ],
            ),
          );
        },
      );
    }

    try {
      await ScreenBrightness().setScreenBrightness(brightnessAnterior);
    } catch (e) {
      debugPrint('Erro ao restaurar o brilho do ecrã: $e');
    }
  }

  /// Diálogo de Suporte
  void _dialogSuporte(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LegoColors.blueDark, width: 3),
        ),
        title: Text(
          t.ajudaesuporte,
          style: GoogleFonts.coiny(color: LegoColors.red),
        ),
        content: Text(
          t.ajudaesuporteContent,
          style: GoogleFonts.varelaRound(),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LegoColors.red),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.commonOk,
              style: GoogleFonts.varelaRound(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de Confirmação para Terminar Sessão
  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    final pendentes = ref.read(pendenteSyncProvider).value ?? 0;
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool estaASair = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: LegoColors.blueDark, width: 3),
              ),
              title: Text(
                t.sairConta,
                style: GoogleFonts.coiny(color: LegoColors.red),
              ),
              content: estaASair
                  ? const LegoBrickLoading()
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.sairContent,
                    style: GoogleFonts.varelaRound(),
                    textAlign: TextAlign.center,
                  ),
                  if (pendentes > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      t.alertDialogPendentes(pendentes),
                      style: GoogleFonts.varelaRound(fontSize: 12, color: Colors.orange[800]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: estaASair
                  ? null
                  : [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    t.commonCancel,
                    style: GoogleFonts.varelaRound(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LegoColors.red,
                  ),
                  onPressed: () async {
                    setState(() {
                      estaASair = true;
                    });

                    final uid = ref.read(utilizadorAtualProvider).value?.uid;
                    if (uid != null && uid.isNotEmpty) {
                      try {
                        await ref.read(syncServiceProvider).sincronizar(uid);
                      } catch (_) {}
                    }

                    try {
                      await ref.read(databaseProvider).limparTudo();
                    } catch (_) {}

                    try {
                      await ref.read(authRepositoryProvider).terminarSessao();
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setState(() {
                          estaASair = false;
                        });
                      }
                    } finally {
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    }
                  },
                  child: Text(
                    t.commonSair,
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Modelo simples interno para representação das conquistas
class _BadgeInfo {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color corIcone;
  final bool desbloqueado;

  _BadgeInfo({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.corIcone,
    required this.desbloqueado,
  });
}