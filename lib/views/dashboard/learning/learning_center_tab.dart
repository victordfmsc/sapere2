import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/learning_provider.dart';
import 'package:get/get.dart';
import '../../../models/learning_models.dart';
import 'review_session_screen.dart';

class LearningCenterTab extends StatefulWidget {
  const LearningCenterTab({super.key});

  @override
  State<LearningCenterTab> createState() => _LearningCenterTabState();
}

class _LearningCenterTabState extends State<LearningCenterTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LearningProvider>(context, listen: false);
      if (provider.userId != null &&
          provider.notes.isEmpty &&
          !provider.isLoading) {
        provider.loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = provider.profile;
        if (profile == null) {
          if (provider.userId == null) {
            return Center(
              child: Text(
                "Inicia sesión para ver tu progreso",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSerifDisplay',
                ),
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No se pudo cargar tu progreso",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NotoSerifDisplay',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => provider.loadAll(),
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff0A0A0B), Color(0xff121214), Color(0xff0A0A0B)],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsHeader(profile),
                SizedBox(height: 32.h),
                _buildDailyReviewSection(context, provider),
                SizedBox(height: 32.h),
                _buildRecentNotesSection(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassContainer({required Widget child, double? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(padding ?? 20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.02),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatsHeader(LearningProfile profile) {
    return _buildGlassContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            "Nivel",
            profile.wisdomLevel.toString(),
            Icons.workspace_premium,
            AppColors.textColor,
          ),
          _buildStatItem(
            "Sabiduría",
            "${profile.wisdomXp} XP",
            Icons.auto_awesome,
            AppColors.kSamiOrange,
          ),
          _buildStatItem(
            "Racha",
            "${profile.dailyStreak} días",
            Icons.local_fire_department,
            Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
          child: Icon(icon, color: Colors.white, size: 30.sp),
        ),
        SizedBox(height: 10.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontFamily: 'NotoSerifDisplay',
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyReviewSection(
    BuildContext context,
    LearningProvider provider,
  ) {
    final dueCount = provider.dueCards.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Repaso Diario",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSerifDisplay',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (dueCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "$dueCount tarjetas",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildGlassContainer(
          padding: 24.w,
          child:
              dueCount > 0
                  ? Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.textColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: AppColors.textColor,
                          size: 40.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Conocimientos listos para ser reforzados",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15.sp,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      GestureDetector(
                        onTap: () => Get.to(() => const ReviewSessionScreen()),
                        child: Container(
                          width: double.infinity,
                          height: 54.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.textColor, Color(0xffD4AF37)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Empezar Repaso",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white24,
                        size: 40.sp,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        "¡Mente clara! Vuelve mañana para continuar expandiendo tu sabiduría.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildRecentNotesSection(
    BuildContext context,
    LearningProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            "Archivo de Sabiduría",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'NotoSerifDisplay',
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        if (provider.notes.isEmpty)
          _buildGlassContainer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  "Aún no tienes notas. ¡Crea una mientras escuchas un audio!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 14.sp),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.notes.length > 5 ? 5 : provider.notes.length,
            itemBuilder: (context, index) {
              final note = provider.notes[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                child: _buildGlassContainer(
                  padding: 16.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getNoteIcon(note.type),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.postTitle.toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDate(note.createdAt),
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.white24,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              _showDeleteConfirm(context, provider, note.id);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        note.content,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15.sp,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _getNoteIcon(NoteType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NoteType.insight:
        iconData = Icons.lightbulb_sharp;
        iconColor = Colors.amber;
        break;
      case NoteType.keyData:
        iconData = Icons.bookmark_sharp;
        iconColor = Colors.redAccent;
        break;
      case NoteType.question:
        iconData = Icons.help_sharp;
        iconColor = Colors.blueAccent;
        break;
      case NoteType.connection:
        iconData = Icons.hub_sharp;
        iconColor = Colors.greenAccent;
        break;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(iconData, color: iconColor, size: 20.sp),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return "${date.day} ${months[date.month - 1]}, ${date.year}";
  }

  void _showDeleteConfirm(
    BuildContext context,
    LearningProvider provider,
    String noteId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              backgroundColor: const Color(0xff1A1A1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              title: Text(
                "¿Eliminar fragmento?",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSerifDisplay',
                ),
              ),
              content: Text(
                "Este fragmento de sabiduría será borrado permanentemente de tu archivo.",
                style: TextStyle(color: Colors.white60, fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CONSERVAR",
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    provider.deleteNote(noteId);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "ELIMINAR",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
