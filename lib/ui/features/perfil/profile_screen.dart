import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../data/auth_providers.dart';
import '../../../data/providers.dart';
import '../login/login_screen.dart';
import '../utils/lego_block_style.dart';
import '../utils/lego_brick_loading.dart';
import '../utils/lego_insiders_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LegoColors.blue,
      body: Stack(
        children: [
          // 1. Fundo de pinos LEGO (opcional)
          /*const Positioned.fill(
            child: LegoFloorBackground(),
          ),*/

          // 2. Conteúdo Principal
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // 🔹 Barra Superior com Botão de Voltar + Título ao lado
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  floating: true,
                  centerTitle: false, // Garante que o título fica encostado à esquerda, junto à seta
                  leadingWidth: 56,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
                    child: LegoBlockDecorator(
                      color: Colors.yellow,
                      borderRadius: 10,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: LegoColors.blueDark,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  title: const LegoTitleBlock(text: 'PERFIL'),



                ),

                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Cabeçalho / Título
                        /*const LegoTitleBlock(text: 'PERFIL'),
                        const SizedBox(height: 24),*/

                        const SizedBox(height: 12),

                        // Card do Avatar e Identificação Dinâmico
                        _buildUserCard(context,ref),

                        const SizedBox(height: 16),

                        // Grelha de Estatísticas do Colecionador
                        _buildStatsGrid(ref),

                        const SizedBox(height: 16),

                        // Menu de Opções / Definições
                        _buildSettingsMenu(context),

                        const Spacer(),



                        // Botão de Terminar Sessão (Sair)
                        LegoBlockDecorator(
                          color: LegoColors.red,
                          borderRadius: 10,
                          child: InkWell(
                            onTap: () => _confirmarApagar(context, ref),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'APAGAR CONTA',
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
                                    'SAIR DA CONTA',
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
          ),
        ],
      ),
    );
  }

  /// Card Principal com Avatar e Dados do Utilizador (Dinamizado via Riverpod)
  Widget _buildUserCard(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(utilizadorAtualProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LegoColors.blueDark, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(3, 3), blurRadius: 3),
        ],
      ),
      child: userAsync.when(
        data: (user) {
          final username = user?.username ?? 'Sem username';
          final email = user?.email ?? 'Sem e-mail';
          // Obtém o ID Insiders (garante que no teu modelo de dados existe o campo insidersId)
          final insidersId = user?.idLegoInsiders;
          final temInsidersId = insidersId != null && insidersId.trim().isNotEmpty;

          return Row(
            children: [
              // Avatar da Minifigura com fundo de Bloco Amarelo
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: LegoColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Informações do Utilizador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: GoogleFonts.varelaRound(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: LegoColors.blueDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 🔹 Ícone do Cartão Insiders (só aparece se o ID estiver preenchido)
                        if (temInsidersId)
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(
                              Icons.badge_outlined,
                              color: LegoColors.blueDark,
                              size: 24,
                            ),
                            tooltip: 'Ver Cartão Insiders',
                            onPressed: () => showInsidersCardDialog(
                              context,
                              insidersId,
                              user!.nome.toString(),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      email,
                      style: GoogleFonts.varelaRound(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    /*const SizedBox(height: 6),
                    // Badge "Membro VIP / Insider"
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LegoColors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Mestre Construtor',
                            style: GoogleFonts.varelaRound(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                       /* if (temInsidersId) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => showInsidersCardDialog(
                              context,
                              insidersId,
                              username,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD500),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: LegoColors.blueDark, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.card_membership, size: 12, color: LegoColors.blueDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cartão',
                                    style: GoogleFonts.varelaRound(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: LegoColors.blueDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],*/
                      ],
                    ),*/
                  ],
                ),
              ),
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
            'Erro ao carregar perfil',
            style: GoogleFonts.varelaRound(color: LegoColors.red),
          ),
        ),
      ),
    );
  }


  /// Estatísticas da Coleção de LEGOs
  Widget _buildStatsGrid(WidgetRef ref) {
    final formatter = NumberFormat('#,##0', 'pt_PT');

    final totalSetsAsync = ref.watch(totalSetsProvider);
    final totalPecasAsync = ref.watch(totalPecasProvider);

    final totalSetsTexto = totalSetsAsync.when(
      data: (val) => formatter.format(val.toInt()),
      loading: () => '...',
      error: (_, __) => '0',
    );

    final totalPecasTexto = totalPecasAsync.when(
      data: (val) => formatter.format(val.toInt()),
      loading: () => '...',
      error: (_, __) => '0',
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatItem('SETS', totalSetsTexto, LegoColors.yellow, Icons.category),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem('PEÇAS', totalPecasTexto, LegoColors.green, Icons.extension),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String count, Color color, IconData icon) {
    return LegoBlockDecorator(
      color: Colors.white,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              count,
              style: GoogleFonts.coiny(
                fontSize: 18,
                color: LegoColors.blueDark,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.varelaRound(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de Definições / Opções do Perfil
  Widget _buildSettingsMenu(BuildContext context) {
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
                title: 'Editar Dados Pessoais',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Ajuda e Suporte',
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
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  //Dialog Insiders Card
  Future<void> showInsidersCardDialog(
      BuildContext context,
      String insidersId,
      String userName,
      ) async {
    double brightnessAnterior = 0.5; // Valor por defeito de reserva

    // 1. Guarda o brilho atual e define o brilho do ecrã no máximo (1.0)
    try {
      brightnessAnterior = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Erro ao alterar o brilho do ecrã: $e');
    }

    // 2. Exibe o Dialog (O 'await' espera até que o dialog seja fechado)
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
                // Botão para Fechar
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

    // 3. Restaura o brilho anterior assim que o dialog é fechado
    try {
      await ScreenBrightness().setScreenBrightness(brightnessAnterior);
    } catch (e) {
      debugPrint('Erro ao restaurar o brilho do ecrã: $e');
    }
  }

  /// Diálogo de Suporte
  void _dialogSuporte(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LegoColors.blueDark, width: 3),
        ),
        title: Text(
          'Ajuda e Suporte',
          style: GoogleFonts.coiny(color: LegoColors.red),
        ),
        content: Text(
          'Developed by Dev4You\n\nEmail: dev4you.solutions@gmail.com',
          style: GoogleFonts.varelaRound(),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LegoColors.red),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.varelaRound(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de Confirmação para Terminar Sessão
  void _confirmarApagar(BuildContext context, WidgetRef ref) {
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
                'APAGAR CONTA',
                style: GoogleFonts.coiny(color: LegoColors.red),
              ),
              content: estaASair
                  ? const LegoBrickLoading()
                  : Text(
                'Tens a certeza que pretende apagar a conta?',
                style: GoogleFonts.varelaRound(),
              ),
              actions: estaASair
                  ? null
                  : [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'CANCELAR',
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

                    try {
                      //await ref.read(authRepositoryProvider).terminarSessao();
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
                    'SAIR',
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

  /// Diálogo de Confirmação para Terminar Sessão
  void _confirmarLogout(BuildContext context, WidgetRef ref) {
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
                'SAIR DA CONTA',
                style: GoogleFonts.coiny(color: LegoColors.red),
              ),
              content: estaASair
                  ? const LegoBrickLoading()
                  : Text(
                'Tens a certeza que queres desligar a tua conta ?',
                style: GoogleFonts.varelaRound(),
              ),
              actions: estaASair
                  ? null
                  : [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'CANCELAR',
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
                    'SAIR',
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