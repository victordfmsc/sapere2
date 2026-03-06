import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/core/services/database_helper.dart';
import 'package:sapere/models/gamification_models.dart';
import 'package:sapere/models/post.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sapere/providers/gamification_provider.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/views/dashboard/gamification/gamified_lesson_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final GamifiedSubject subject;

  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  bool _isLoadingPosts = true;
  List<BukBukPost> _subjectPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    final languageCode = storedLang ?? 'es_ES';

    final posts = await DataBaseHelper().getGamificationPostsForSubject(
      widget.subject.name,
      languageCode: languageCode,
    );
    if (mounted) {
      setState(() {
        _subjectPosts = posts;
        _isLoadingPosts = false;
      });
    }
  }

  String _getDetailedSystemPrompt(String category, String level) {
    String persona;
    switch (category.toLowerCase()) {
      case 'historia':
        persona =
            "un historiador cinematográfico apasionado, capaz de revivir el pasado con una narrativa épica y llena de detalles vívidos";
        break;
      case 'ciencia':
        persona =
            "un divulgador científico entusiasta, al estilo de Carl Sagan, que explica conceptos complejos con asombro, claridad y ejemplos fascinantes";
        break;
      case 'filosofía':
      case 'filosofia':
        persona =
            "un pensador profundo y ensayista lírico, que invita a la reflexión filosófica conectando las ideas con la experiencia humana";
        break;
      case 'tecnología':
      case 'tecnologia':
        persona =
            "un visionario tecnológico y futurista, que explica el funcionamiento de la innovación y su impacto transformador en la sociedad";
        break;
      default:
        persona =
            "un narrador de documentales premium, con una voz sofisticada, educativa y envolvente";
    }

    return "Eres $persona. Tu misión es crear el guion para un audiodocumental educativo de nivel '$level' sobre la materia '${widget.subject.name}'. Tu tono debe ser inspirador, erudito pero accesible, y altamente inmersivo.";
  }

  String _getDetailedUserPrompt(
    String title,
    String description,
    String languageCode,
  ) {
    String languageName = getLanguageName(languageCode);
    return """
Genera un guion para un audiodocumental titulado: '$title'.
Tema central: $description

El guion DEBE seguir esta estructura:
1. INICIO CINEMATOGRÁFICO: Comienza con una escena potente, una pregunta intrigante o un dato sorprendente para capturar la atención.
2. CONTEXTO Y DESPLIEGUE: Explica los fundamentos del tema con profundidad y claridad.
3. EL DATO INÉDITO: Incluye al menos un hecho poco conocido o una perspectiva única que sorprenda al oyente.
4. CIERRE INSPIRADOR: Termina con una reflexión que invite al oyente a seguir explorando este fragmento de sabiduría.

Requisitos técnicos:
- Idioma: $languageName.
- Longitud: Aproximadamente 800-1000 palabras.
- Estilo: Narrativo, no una simple lista de hechos. Usa metáforas y descripciones sensoriales.
""";
  }

  void _showCreationPortal(GamifiedEpisode episode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<BukBukProvider>(
          builder: (context, provider, child) {
            final step = provider.generationStep;

            // Auto-close on completion (optional, maybe wait for user to click)
            if (step == GenerationStep.completed) {
              Future.delayed(const Duration(seconds: 2), () {
                if (Navigator.canPop(context)) Navigator.pop(context);
                _fetchEpisodes(); // Refresh list
              });
            }

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: const Color(0xff1A1A1C).withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                contentPadding: EdgeInsets.zero,
                content: Container(
                  width: 320.w,
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProgressCircle(step),
                      SizedBox(height: 24.h),

                      // --- NEW: EARLY COVER REVEAL ---
                      if (provider.lastGeneratedCoverUrl != null) ...[
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Container(
                                  width: 140.w,
                                  height: 140.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.textColor.withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        provider.lastGeneratedCoverUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
                      ],

                      Text(
                        _getStepTitle(step),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontFamily: 'NotoSerifDisplay',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _getStepSubtitle(step),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildFunFactCarousel(),

                      // --- NEW: MINIMIZE BUTTON ---
                      if (step != GenerationStep.completed &&
                          step != GenerationStep.error) ...[
                        SizedBox(height: 16.h),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.open_in_full,
                            size: 16.sp,
                            color: Colors.white38,
                          ),
                          label: Text(
                            "continueNavigating".tr,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                      if (step == GenerationStep.error) ...[
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text("close".tr),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressCircle(GenerationStep step) {
    double progress = 0;
    switch (step) {
      case GenerationStep.designingScript:
        progress = 0.20;
        break;
      case GenerationStep.generatingCover:
        progress = 0.40;
        break;
      case GenerationStep.invokingNarrator:
        progress = 0.60;
        break;
      case GenerationStep.masteringAudio:
        progress = 0.80;
        break;
      case GenerationStep.finalizing:
        progress = 0.95;
        break;
      case GenerationStep.completed:
        progress = 1.0;
        break;
      default:
        progress = 0;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: CircularProgressIndicator(
            value: step == GenerationStep.error ? 1.0 : progress,
            strokeWidth: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              step == GenerationStep.error
                  ? Colors.redAccent
                  : AppColors.textColor,
            ),
          ),
        ),
        Icon(_getStepIcon(step), color: Colors.white, size: 32.sp),
      ],
    );
  }

  IconData _getStepIcon(GenerationStep step) {
    switch (step) {
      case GenerationStep.designingScript:
        return Icons.edit_note;
      case GenerationStep.generatingCover:
        return Icons.brush_outlined;
      case GenerationStep.invokingNarrator:
        return Icons.mic;
      case GenerationStep.masteringAudio:
        return Icons.graphic_eq;
      case GenerationStep.finalizing:
        return Icons.auto_awesome;
      case GenerationStep.completed:
        return Icons.check_circle;
      case GenerationStep.error:
        return Icons.error_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStepTitle(GenerationStep step) {
    switch (step) {
      case GenerationStep.designingScript:
        return "designingScript".tr;
      case GenerationStep.generatingCover:
        return "generatingVisuals".tr;
      case GenerationStep.invokingNarrator:
        return "invokingNarrator".tr;
      case GenerationStep.masteringAudio:
        return "masteringAudio".tr;
      case GenerationStep.finalizing:
        return "finalizingDetails".tr;
      case GenerationStep.completed:
        return "materialized".tr;
      case GenerationStep.error:
        return "visionaryError".tr;
      default:
        return "startingRite".tr;
    }
  }

  String _getStepSubtitle(GenerationStep step) {
    switch (step) {
      case GenerationStep.designingScript:
        return "scriptStepSub".tr;
      case GenerationStep.generatingCover:
        return "visualsStepSub".tr;
      case GenerationStep.invokingNarrator:
        return "narratorStepSub".tr;
      case GenerationStep.masteringAudio:
        return "masteringStepSub".tr;
      case GenerationStep.finalizing:
        return "finalizingStepSub".tr;
      case GenerationStep.completed:
        return "completedStepSub".tr;
      case GenerationStep.error:
        return "errorStepSub".tr;
      default:
        return "startingStepSub".tr;
    }
  }

  Widget _buildFunFactCarousel() {
    final facts = _getFunFactsByCategory(widget.subject.category);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.textColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "didYouKnow".tr,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 60.h,
            child: PageView.builder(
              itemCount: facts.length,
              itemBuilder: (context, index) {
                return Text(
                  facts[index],
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getFunFactsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'ciencia':
        return [
          "El 95% del universo está compuesto por materia y energía oscura.",
          "Una cucharadita de una estrella de neutrones pesaría 6 mil millones de toneladas.",
          "La luz tarda 8 minutos y 20 segundos en viajar del Sol a la Tierra.",
        ];
      case 'historia':
        return [
          "Las pirámides de Giza se construyeron más cerca de nuestra época que de la invención del lenguaje.",
          "Cleopatra vivió cronológicamente más cerca del iPhone que de las grandes pirámides.",
          "Roma fue fundada en el 753 a.C., según la leyenda por Rómulo y Remo.",
        ];
      default:
        return ["sapereFact1".tr, "sapereFact2".tr, "sapereFact3".tr];
    }
  }

  void _createNewEpisode(GamifiedEpisode episode) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: const Color(0xff1A1A1C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            title: Text(
              'startJourney'.tr,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSerifDisplay',
                fontSize: 22.sp,
              ),
            ),
            content: Text(
              'materializeDesc'.tr,
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'cancel'.tr.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final sapereProvider = Provider.of<BukBukProvider>(
                    context,
                    listen: false,
                  );

                  final storedLang = await LocalStorage().getData(
                    key: AppLocalKeys.localeKey,
                  );
                  final languageCode = storedLang ?? 'es_ES';

                  final systemPrompt = _getDetailedSystemPrompt(
                    widget.subject.category,
                    episode.level,
                  );
                  final prompt = _getDetailedUserPrompt(
                    episode.title,
                    episode.description,
                    languageCode,
                  );

                  await sapereProvider.createGamificationEpisodePost(
                    categoryName: widget.subject.category,
                    subjectName: widget.subject.name,
                    episodeNumber: episode.episodeNumber,
                    episodeTitle: episode.title,
                    languageCode: languageCode,
                    systemPrompt: systemPrompt,
                    prompt: prompt,
                    context: context,
                  );

                  _fetchEpisodes();
                  if (sapereProvider.generationStep != GenerationStep.idle &&
                      sapereProvider.generationStep != GenerationStep.error) {
                    _showCreationPortal(episode);
                  }
                },
                child: Text('materializeBtn'.tr),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0B),
      appBar: AppBar(
        title: Text(
          widget.subject.name,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSerifDisplay',
            fontWeight: FontWeight.w800,
            fontSize: 22.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff0A0A0B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_sharp, color: AppColors.textColor),
            onPressed: () {
              setState(() => _isLoadingPosts = true);
              _fetchEpisodes();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xff0A0A0B), const Color(0xff121214)],
          ),
        ),
        child:
            _isLoadingPosts
                ? Center(
                  child: CircularProgressIndicator(color: AppColors.textColor),
                )
                : Consumer<GamificationProvider>(
                  builder: (context, provider, child) {
                    final profile = provider.profile;
                    if (profile == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.subject.episodes.length,
                      itemBuilder: (context, index) {
                        final episode = widget.subject.episodes[index];
                        final isCompleted = profile.completedEpisodes.contains(
                          '${widget.subject.name}_${episode.episodeNumber}',
                        );

                        bool isUnlocked = false;
                        if (episode.episodeNumber == 1) {
                          isUnlocked = true;
                        } else {
                          isUnlocked = profile.completedEpisodes.contains(
                            '${widget.subject.name}_${episode.episodeNumber - 1}',
                          );
                        }

                        final BukBukPost?
                        createdPost = _subjectPosts.firstWhereOrNull(
                          (p) => p.gamificationEpisode == episode.episodeNumber,
                        );

                        return _buildEpisodeCard(
                          context,
                          episode,
                          isCompleted,
                          isUnlocked,
                          createdPost,
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildEpisodeCard(
    BuildContext context,
    GamifiedEpisode episode,
    bool isCompleted,
    bool isUnlocked,
    BukBukPost? createdPost,
  ) {
    return Consumer<BukBukProvider>(
      builder: (context, provider, child) {
        final isMaterializing =
            provider.generationStep != GenerationStep.idle &&
            provider.generationStep != GenerationStep.completed &&
            provider.generationStep != GenerationStep.error &&
            // Note: We'll assume only one is generated at a time for this subject
            // A more robust way would be to check the episode number if stored in provider
            _isThisEpisodeGenerating(provider, episode);

        return Container(
          margin: EdgeInsets.only(bottom: 20.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isUnlocked
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color:
                        isCompleted
                            ? AppColors.textColor.withOpacity(0.6)
                            : isMaterializing
                            ? Colors.amber.withOpacity(0.5)
                            : isUnlocked
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white.withOpacity(0.03),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    onTap:
                        isUnlocked
                            ? () {
                              if (createdPost != null) {
                                Get.to(
                                  () => GamifiedLessonScreen(
                                    subject: widget.subject,
                                    episode: episode,
                                    post: createdPost,
                                  ),
                                );
                              } else if (isMaterializing) {
                                _showCreationPortal(episode);
                              } else {
                                _createNewEpisode(episode);
                              }
                            }
                            : () {
                              Get.snackbar(
                                'lockedPath'.tr,
                                'lockedPathDesc'.tr,
                                backgroundColor: Colors.black87,
                                colorText: Colors.white70,
                              );
                            },
                    contentPadding: EdgeInsets.all(20.w),
                    leading: Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? AppColors.textColor.withOpacity(0.15)
                                : isUnlocked
                                ? Colors.white.withOpacity(0.05)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isCompleted
                                  ? AppColors.textColor
                                  : isMaterializing
                                  ? Colors.amber
                                  : isUnlocked
                                  ? Colors.white30
                                  : Colors.white12,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child:
                            isMaterializing
                                ? SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.amber,
                                    ),
                                  ),
                                )
                                : isUnlocked
                                ? (isCompleted
                                    ? Icon(
                                      Icons.auto_awesome,
                                      color: AppColors.textColor,
                                      size: 24.sp,
                                    )
                                    : Text(
                                      "${episode.episodeNumber}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'NotoSerifDisplay',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp,
                                      ),
                                    ))
                                : Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white12,
                                  size: 20.sp,
                                ),
                      ),
                    ),
                    title: Text(
                      episode.title.toUpperCase(),
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white24,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.sp,
                        letterSpacing: 1.2,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        Text(
                          isMaterializing
                              ? "revealingWisdom".tr
                              : episode.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isMaterializing
                                    ? Colors.amber.withOpacity(0.8)
                                    : isUnlocked
                                    ? Colors.white60
                                    : Colors.white12,
                            fontSize: 13.sp,
                            fontWeight:
                                isMaterializing
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            _buildBadge(
                              "+${episode.xpBase} XP",
                              Icons.bolt_sharp,
                              Colors.amber,
                            ),
                            if (episode.badgeOnCompletion != null) ...[
                              SizedBox(width: 12.w),
                              _buildBadge(
                                episode.badgeOnCompletion!,
                                Icons.workspace_premium_sharp,
                                AppColors.textColor,
                              ),
                            ],
                            const Spacer(),
                            if (isMaterializing)
                              Icon(
                                Icons.hourglass_top_rounded,
                                color: Colors.amber.withOpacity(0.8),
                                size: 18.sp,
                              )
                            else if (isUnlocked && createdPost == null)
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.amber.withOpacity(0.6),
                                size: 18.sp,
                              ),
                            if (isCompleted)
                              Icon(
                                Icons.check_circle_sharp,
                                color: Colors.greenAccent.withOpacity(0.6),
                                size: 18.sp,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isThisEpisodeGenerating(
    BukBukProvider provider,
    GamifiedEpisode episode,
  ) {
    return provider.generatingEpisodeNumber == episode.episodeNumber;
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
