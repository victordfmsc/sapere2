import 'dart:async';
import 'dart:io';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/constant/voice_data.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/core/services/firebase_storage_service.dart';
import 'package:sapere/core/services/story_functions_service.dart';
import 'package:sapere/models/sapere_category_type_model.dart';
import 'package:sapere/models/sapere_type_model.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/models/public_post.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/views/dashboard/subscription/widgets/out_of_credits_dialog.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:sapere/widgets/dailogs/creation_success_dialog.dart';

enum CheckStatus { completed, error, loading }

enum GenerationStep {
  idle,
  designingScript,
  generatingCover,
  invokingNarrator,
  masteringAudio,
  finalizing,
  completed,
  error,
}

class BukBukProvider extends ChangeNotifier {
  BukBukProvider(BuildContext context) {
    init(context);
  }
  void init(BuildContext context) {
    print('init callled');
    fetchDiaryCategoryTypesAndFetchFirstType(context);
  }

  List<BukBukCategoryModel> _sapereCategoryTypes = [];
  late BukBukCategoryModel _bukBukCategoryModel;
  List<BukBukTypeModel> _sapereTypes = [];
  late BukBukTypeModel _bukBukTypeModel;
  bool _isLoading = true;
  // bool _isGenerating = false;
  bool _isTypesLoading = true;
  bool _isCommuinty = true;
  String _selectedCover = "";
  GenerationStep _generationStep = GenerationStep.idle;
  String? _currentGeneratingDocId;
  int? _generatingEpisodeNumber;
  String? _lastGeneratedCoverUrl;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _generationWatch;
  final Set<String> _retryingDocIds = <String>{};

  List<BukBukCategoryModel> get sapereCategoryTypes => _sapereCategoryTypes;
  BukBukCategoryModel get bukBukCategoryModel => _bukBukCategoryModel;
  List<BukBukTypeModel> get sapereTypes => _sapereTypes;
  BukBukTypeModel get bukBukTypeModel => _bukBukTypeModel;
  bool get isLoading => _isLoading;
  // bool get isGenerating => _isGenerating;
  bool get isTypesLoading => _isTypesLoading;
  bool get isCommuinty => _isCommuinty;
  String get selectedCover => _selectedCover;
  GenerationStep get generationStep => _generationStep;
  String? get currentGeneratingDocId => _currentGeneratingDocId;
  int? get generatingEpisodeNumber => _generatingEpisodeNumber;
  String? get lastGeneratedCoverUrl => _lastGeneratedCoverUrl;

  set lastGeneratedCoverUrl(String? value) {
    _lastGeneratedCoverUrl = value;
    notifyListeners();
  }

  set sapereCategoryTypes(List<BukBukCategoryModel> value) {
    _sapereCategoryTypes = value;
    notifyListeners();
  }

  set bukBukCategoryModel(BukBukCategoryModel value) {
    _bukBukCategoryModel = value;
    notifyListeners();
  }

  set sapereTypes(List<BukBukTypeModel> value) {
    _sapereTypes = value;
    notifyListeners();
  }

  set bukBukTypeModel(BukBukTypeModel value) {
    _bukBukTypeModel = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // set isGenerating(bool value) {
  //   _isGenerating = value;
  //   notifyListeners();
  // }

  set isTypesLoading(bool value) {
    _isTypesLoading = value;
    notifyListeners();
  }

  set isCommuinty(bool value) {
    _isCommuinty = value;
    notifyListeners();
  }

  void setSelectedCover(String value) {
    _selectedCover = value;
    notifyListeners();
  }

  void setGenerationStep(
    GenerationStep step, {
    String? docId,
    int? episodeNumber,
  }) {
    _generationStep = step;
    if (docId != null) _currentGeneratingDocId = docId;
    if (episodeNumber != null) _generatingEpisodeNumber = episodeNumber;
    notifyListeners();
  }

  String _categoryDocId = '';
  CheckStatus _rxRequestStatus = CheckStatus.completed;
  CheckStatus _communityRequestStatus = CheckStatus.completed;
  String _sapereTitle = '';

  static const String premiumDefaultCover =
      "assets/images/mysterious_default_cover.png"; // New Cinematic Mysterious Cover

  final List<String> _descriptions = [];
  bool _isUploading = false;
  String _loadingMessage = '';

  String get categoryDocId => _categoryDocId;
  CheckStatus get rxRequestStatus => _rxRequestStatus;
  CheckStatus get communityRequestStatus => _communityRequestStatus;
  String get sapereTitle => _sapereTitle;
  List<String>? get descriptions => _descriptions;
  bool get isUploading => _isUploading;
  String get loadingMessage => _loadingMessage;

  // --- Voice selection state ---
  String? _selectedVoiceId;
  String? _selectedVoiceName;

  String? get selectedVoiceId => _selectedVoiceId;
  String? get selectedVoiceName => _selectedVoiceName;

  void setSelectedVoice(String voiceId, String voiceName) {
    _selectedVoiceId = voiceId;
    _selectedVoiceName = voiceName;
    notifyListeners();
  }

  void clearSelectedVoice() {
    _selectedVoiceId = null;
    _selectedVoiceName = null;
    notifyListeners();
  }

  /// Returns the user-selected voiceId, or the default from voice_data catalog.
  String getActiveVoiceId(String languageCode) {
    return _selectedVoiceId ?? getDefaultVoiceId(languageCode);
  }

  set sapereTitle(String value) {
    _sapereTitle = value;
    notifyListeners();
  }

  void addDescription(String desc) {
    _descriptions.add(desc);
    notifyListeners();
  }

  void setIsUploading(bool value, {String message = ''}) {
    _isUploading = value;
    _loadingMessage = message;
    notifyListeners();
  }

  void setCategoryDocId(String value) {
    _categoryDocId = value;
    notifyListeners();
  }

  void setRxRequestStatus(CheckStatus value) {
    _rxRequestStatus = value;
    notifyListeners();
  }

  void setCommunityRequestStatus(CheckStatus value) {
    _communityRequestStatus = value;
    notifyListeners();
  }

  List<String> generationSteps = [];

  void addGenerationStep(String message) {
    generationSteps.add(message);
    notifyListeners();
  }

  void clearGenerationSteps() {
    generationSteps.clear();
    notifyListeners();
  }

  // --- NEW: Premium Cover Migration ---
  Future<void> updateExistingCovers() async {
    try {
      print('🔍 Checking for documentaries that need premium cover update...');
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('sapere').get();

      final List<String> oldDefaults = [
        "https://firebasestorage.googleapis.com/v0/b/sapere-6b92a.appspot.com/o/app_assets%2Fsapere_default.png?alt=media",
        "https://firebasestorage.googleapis.com/v0/b/sapere-6b92a.appspot.com/o/app_assets%2Fgamification_default.png?alt=media",
        "https://images.unsplash.com/photo-1516979187457-637abb4f9353?q=80\u0026w=1000\u0026auto=format\u0026fit=crop",
      ];

      int updateCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final currentCover = data['newCover'] ?? data['coverImage'];

        // If cover is missing or one of the generic old ones
        if (currentCover == null ||
            currentCover.isEmpty ||
            oldDefaults.contains(currentCover)) {
          await doc.reference.update({
            'newCover': premiumDefaultCover,
            'coverImage': premiumDefaultCover,
          });
          updateCount++;
        }
      }
      if (updateCount > 0) {
        print(
          '✅ Successfully updated $updateCount documentaries to premium cover.',
        );
      }
    } catch (e) {
      print('❌ Error during cover migration: $e');
    }
  }

  // Methods
  Future<void> fetchDiaryCategoryTypes() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection(sapereTypeCategoriesCollection)
              .get();

      sapereCategoryTypes =
          snapshot.docs
              .map((doc) => BukBukCategoryModel.fromFirestore(doc))
              .toList();
      isLoading = false;
      // Trigger cover migration for existing docs
      // updateExistingCovers();
    } catch (e) {
      print('Error fetching diary types: $e');
      isLoading = false;
    }
  }

  Future<void> fetchDiaryTypes(String categoryDocId) async {
    isTypesLoading = true;

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection(sapereTypeCategoriesCollection)
              .doc(categoryDocId)
              .collection(sapereTypeCollection)
              .where('userapp', isEqualTo: true)
              .orderBy('order')
              .get();

      sapereTypes =
          snapshot.docs
              .map((doc) => BukBukTypeModel.fromFirestore(doc))
              .toList();
      bukBukTypeModel = sapereTypes.first;

      isTypesLoading = false;
    } catch (e) {
      print('Error fetching sapere types: $e');
      isTypesLoading = false;
    } finally {
      isTypesLoading = false;
    }
  }

  Future<void> fetchDiaryCategoryTypesAndFetchFirstType(
    BuildContext context,
  ) async {
    try {
      isLoading = true;
      await fetchDiaryCategoryTypes();
      if (_sapereCategoryTypes.isNotEmpty) {
        bukBukCategoryModel = _sapereCategoryTypes.first;
        String firstCategoryId = _sapereCategoryTypes.first.docId;
        setCategoryDocId(firstCategoryId);
        await fetchDiaryTypes(firstCategoryId);
      }
    } catch (e) {
      print('Something went wrong: $e');
    } finally {
      isLoading = false;
    }
  }

  // ───────────────────────── Cloud Functions ─────────────────────────────────
  // El servidor cobra el crédito, crea el documento de la colección 'sapere' y
  // encola la generación de texto y portada. La voz la pone el lector bimodal
  // del dispositivo, así que aquí no se descuenta crédito, ni se escribe el
  // documento, ni se pide audio.

  late final StoryFunctionsService _storyFunctions = StoryFunctionsService();

  /// Llama a la callable `startStory` y deja la interfaz lista (diálogo de
  /// éxito, créditos frescos).
  /// Devuelve el docId creado por el servidor, o `null` si no se pudo arrancar
  /// (en ese caso ya se avisó al usuario con el diálogo que corresponda).
  Future<String?> _startStoryWithFunctions({
    required InAppPurchaseProvider subProvider,
    required String prompt,
    required String? systemPrompt,
    required String languageCode,
    required String languageName,
    required String title,
    String type = 'sapere',
    String? genre,
    String? bukbukId,
    String? bukbukCategoryId,
    Map<String, dynamic>? bukbukTypeNames,
    Map<String, dynamic>? bukbukCategoryNames,
    String? gamificationSubject,
    int? gamificationEpisode,
    bool showSuccessDialog = true,
  }) async {
    try {
      setIsUploading(true, message: "uploadingToDatabase".tr);
      setGenerationStep(
        GenerationStep.designingScript,
        episodeNumber: gamificationEpisode,
      );

      final StartStoryResult result = await _storyFunctions.startStory(
        prompt: prompt,
        systemPrompt: systemPrompt,
        languageCode: languageCode,
        language: languageName,
        genre: genre,
        type: type,
        coverUrl: selectedCover.isEmpty ? null : selectedCover,
        bukbukId: bukbukId,
        bukbukCategoryId: bukbukCategoryId,
        bukbukTypeNames: bukbukTypeNames,
        bukbukCategoryNames: bukbukCategoryNames,
        gamificationSubject: gamificationSubject,
        gamificationEpisode: gamificationEpisode,
        title: title,
      );

      debugPrint(
        '✅ startStory encolado: docId=${result.docId} status=${result.status} '
        'créditos=${result.credits.total}',
      );

      sapereTitle = title;
      setGenerationStep(
        GenerationStep.designingScript,
        docId: result.docId,
        episodeNumber: gamificationEpisode,
      );
      _watchGeneration(result.docId);
      setSelectedCover('');

      await subProvider.refreshCredits(invalidate: true);

      if (showSuccessDialog) {
        // El documento ya existe en el servidor: un fallo del diálogo no
        // convierte una creación correcta en un error.
        try {
          Get.dialog(
            CreationSuccessDialog(credits: subProvider.totalCredits.toString()),
          );
        } catch (e, st) {
          debugPrint('⚠️ Diálogo de éxito no mostrado: $e');
          debugPrint('$st');
        }
      }
      return result.docId;
    } on StartStoryException catch (e) {
      setGenerationStep(GenerationStep.error);
      debugPrint('❌ startStory rechazado: $e');
      _showStartStoryError(e.error, subProvider);
      return null;
    } catch (e, st) {
      setGenerationStep(GenerationStep.error);
      debugPrint('❌ startStory error inesperado: $e');
      debugPrint('$st');
      _showStartStoryError(StartStoryError.unknown, subProvider);
      return null;
    } finally {
      setIsUploading(false);
    }
  }

  /// Sigue el documento que creó `startStory` y lleva [generationStep] hasta
  /// `completed` o `error`. El portal de creación y el estado "materializando"
  /// dependen de ese valor, y en la ruta de Cloud Functions nadie más lo cerraba.
  void _watchGeneration(String docId) {
    _generationWatch?.cancel();
    _generationWatch = FirebaseFirestore.instance
        .collection('sapere')
        .doc(docId)
        .snapshots()
        .listen(
          (snap) {
            final String? status = snap.data()?['status'] as String?;
            switch (status) {
              case 'generating_title':
                setGenerationStep(GenerationStep.generatingCover, docId: docId);
                break;
              case 'generating_script':
                setGenerationStep(GenerationStep.invokingNarrator, docId: docId);
                break;
              case 'completed':
                _finishGeneration(GenerationStep.completed);
                break;
              case 'error':
                _finishGeneration(GenerationStep.error);
                break;
            }
          },
          onError: (Object e) {
            debugPrint('⚠️ No se pudo seguir la generación de $docId: $e');
            _finishGeneration(GenerationStep.idle);
          },
        );
  }

  void _finishGeneration(GenerationStep step) {
    _generationWatch?.cancel();
    _generationWatch = null;
    _generatingEpisodeNumber = null;
    setGenerationStep(step);
  }

  @override
  void dispose() {
    _generationWatch?.cancel();
    super.dispose();
  }

  void _showStartStoryError(
    StartStoryError error,
    InAppPurchaseProvider subProvider,
  ) {
    switch (error) {
      case StartStoryError.insufficientCredits:
        final BuildContext? ctx = Get.context;
        if (ctx == null) return;
        showDialog(
          context: ctx,
          builder:
              (_) =>
                  OutOfCreditsDialog(nextRefillDate: subProvider.nextRefillDate),
        );
        break;
      case StartStoryError.alreadyGenerating:
        Get.snackbar(
          'warningImage'.tr,
          generationErrorMessageKey(error).tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        break;
      case StartStoryError.rateLimited:
      case StartStoryError.aiUnavailable:
      case StartStoryError.unauthenticated:
      case StartStoryError.network:
      case StartStoryError.unknown:
        Get.snackbar(
          'warningImage'.tr,
          generationErrorMessageKey(error).tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        break;
    }
  }

  /// Devuelve el docId creado, o `null` si la creacion no arranco (el aviso al
  /// usuario ya se mostro y la pagina de creacion no debe cerrarse).
  Future<String?> generateFullStory({
    required String systemPrompt,
    required String baseUserPrompt,
    required String languageCode,
  }) async {
    try {
      clearGenerationSteps();
      _descriptions.clear();
      sapereTitle = "";

      return await _startStoryWithFunctions(
        subProvider: Provider.of<InAppPurchaseProvider>(
          Get.context!,
          listen: false,
        ),
        prompt: baseUserPrompt,
        systemPrompt: systemPrompt,
        languageCode: languageCode,
        languageName: getLanguageName(languageCode),
        title: titleFromPrompt(baseUserPrompt, fallback: 'Audiolibro Sapere'),
        genre: bukBukCategoryModel.names[languageCode],
        bukbukId: bukBukTypeModel.id,
        bukbukCategoryId: bukBukCategoryModel.docId,
        bukbukTypeNames: Map<String, dynamic>.from(bukBukTypeModel.names),
        bukbukCategoryNames: Map<String, dynamic>.from(
          bukBukCategoryModel.names,
        ),
      );
    } catch (e, st) {
      print('⚠️ Error in generateFullStory: $e');
      print(st);
      Get.snackbar(
        'warningImage'.tr,
        'wentWrong'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<void> generateCoverFromServer({
    required String prompt,
    required String docId,
    required String uId,
    required String language,
  }) async {
    // AI Cover generation disabled by user request (Premium Manual Selection only)
    print('🎨 AI cover generation skipped for docId: $docId');
    return;
  }

  Future<void> uploadFullPodcast({
    required String systemPrompt,
    required String baseUserPrompt,
    required String languageCode,
    required String title,
  }) async {
    try {
      addGenerationStep("☁️ Uploading post...");
      await createBukbukPost(
        name: title,
        languageCode: languageCode,
        systemPrompt: systemPrompt,
        prompt: baseUserPrompt,
      );

      print('🚀 Upload completed.');
      addGenerationStep("✅ All done!");
    } catch (e, st) {
      print('⚠️ Error while generating/uploading: $e');
      print(st);
      setRxRequestStatus(CheckStatus.error);
      Get.snackbar(
        'warningImage'.tr,
        'wentWrong'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  createBukbukPost({
    required String? name,
    required String languageCode,
    required String systemPrompt,
    required String prompt,
  }) async {
    try {
      final subProvider = Provider.of<InAppPurchaseProvider>(
        Get.context!,
        listen: false,
      );

      await _startStoryWithFunctions(
        subProvider: subProvider,
        prompt: prompt,
        systemPrompt: systemPrompt,
        languageCode: languageCode,
        languageName: getLanguageName(languageCode),
        title: name ?? "Audio Book",
        genre: bukBukCategoryModel.names[languageCode],
        bukbukId: bukBukTypeModel.id,
        bukbukCategoryId: bukBukCategoryModel.docId,
        bukbukTypeNames: Map<String, dynamic>.from(bukBukTypeModel.names),
        bukbukCategoryNames: Map<String, dynamic>.from(
          bukBukCategoryModel.names,
        ),
      );
    } catch (e) {
      print('❌ Failed to upload post: $e');
      Get.snackbar(
        'warningImage'.tr,
        'errorUploading'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      setIsUploading(false);
    }
  }

  Future<String?> generateCoverWithGemini(String prompt) async {
    // Local generation disabled in favor of backend generation
    return null;
  }

  Future<void> createGamificationEpisodePost({
    required String categoryName,
    required String subjectName,
    required int episodeNumber,
    required String episodeTitle,
    required String languageCode,
    required String systemPrompt,
    required String prompt,
    required BuildContext context,
  }) async {
    try {
      final subProvider = Provider.of<InAppPurchaseProvider>(
        context,
        listen: false,
      );

      lastGeneratedCoverUrl = null;
      final categoryInfo = await _ensureCategoryExists(categoryName);
      await _startStoryWithFunctions(
        subProvider: subProvider,
        prompt: prompt,
        systemPrompt: systemPrompt,
        languageCode: languageCode,
        languageName: getLanguageName(languageCode),
        title: "$subjectName - Ep $episodeNumber: $episodeTitle",
        type: 'gamification_episode',
        genre: categoryName,
        bukbukCategoryId: categoryInfo['id']?.toString(),
        bukbukCategoryNames: Map<String, dynamic>.from(
          categoryInfo['names'] as Map? ?? const {},
        ),
        gamificationSubject: subjectName,
        gamificationEpisode: episodeNumber,
      );
    } catch (e) {
      setGenerationStep(GenerationStep.error);
      print('❌ Failed to upload episode: $e');
      rethrow; // Rethrow to let UI handle it if needed
    } finally {
      setIsUploading(false);
    }
  }

  /// Ensures a category exists in the 'sapereCategories' collection.
  /// Returns a map with 'id' and 'names'.
  Future<Map<String, dynamic>> _ensureCategoryExists(
    String categoryName,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection(sapereTypeCategoriesCollection);

    // 1. Try to find existing category by name (case insensitive check is hard in firestore,
    // but here we expect the names from CSV to be consistent).
    // We check the Spanish name since the CSV is currently in Spanish.
    final query =
        await collection.where('names.es_ES', isEqualTo: categoryName).get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return {'id': doc.id, 'names': doc.data()['names']};
    }

    // 2. If not found, create it
    final docRef = collection.doc();
    final names = {
      'es_ES': categoryName,
      'en_US': categoryName, // Fallback to same name for English if not found
    };

    await docRef.set({'names': names, 'created_at': Timestamp.now()});

    return {'id': docRef.id, 'names': names};
  }

  /// Punto de entrada del botón "Reintentar": reintenta por Cloud Functions.
  ///
  /// Solo vuelve a llamar a `startStory` (y por tanto a cobrar) si el gasto
  /// anterior ya no está vivo: el documento no tiene `generation.spendId` o ese
  /// gasto ya fue reembolsado (lo hace `generateStory` al fallar, o
  /// `sweepStalled`). Si el gasto sigue sin devolver se pide esperar: el barrido
  /// lo devuelve en minutos y reintentar ahora cobraría dos veces. Cuando el
  /// nuevo documento existe, el fallido se borra para no dejar un duplicado.
  Future<bool> retryGeneration(BukBukPost post) async {
    final String? docId = post.postId;
    if (docId == null || docId.isEmpty) return false;
    if (!_retryingDocIds.add(docId)) return false;
    try {
      return await _retryGenerationOnce(post, docId);
    } finally {
      _retryingDocIds.remove(docId);
    }
  }

  Future<bool> _retryGenerationOnce(BukBukPost post, String docId) async {

    final subProvider = Provider.of<InAppPurchaseProvider>(
      Get.context!,
      listen: false,
    );
    final docRef = FirebaseFirestore.instance.collection('sapere').doc(docId);

    try {
      final snap = await docRef.get();
      final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
      final Map<String, dynamic> generation = Map<String, dynamic>.from(
        (data['generation'] as Map?) ?? const <String, dynamic>{},
      );
      final String? refundMessageKey = pendingRefundMessageKey(generation);

      if (refundMessageKey != null) {
        debugPrint(
          '↩️ $docId conserva un gasto sin devolver '
          '(spendId=${generation['spendId']}, '
          'refundState=${generation['refundState']}): no se reintenta.',
        );
        Get.snackbar(
          'info'.tr,
          refundMessageKey.tr,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
        return false;
      }

      final String languageCode =
          (data['languageCode'] as String?) ?? post.languageCode ?? 'en_US';
      final String language =
          (data['language'] as String?) ??
          post.language ??
          getLanguageName(languageCode);
      final String title = retryTitle(data, fallback: post.displayTitle);
      final String type =
          (data['type'] as String?) ?? post.type ?? 'sapere';

      String prompt = ((data['prompt'] as String?) ?? '').trim();
      if (prompt.isEmpty) prompt = title;

      final String bukbukId =
          (data['bukbukId'] as String?) ?? post.sapereId ?? '';
      final String bukbukCategoryId =
          (data['bukbukCategoryId'] as String?) ?? post.sapereCategoryId ?? '';
      final Map<String, dynamic> bukbukTypeNames = Map<String, dynamic>.from(
        data['bukbukTypeNames'] ?? post.sapereTypeNames ?? const {},
      );
      final Map<String, dynamic> bukbukCategoryNames =
          Map<String, dynamic>.from(
            data['bukbukCategoryNames'] ?? post.sapereCategoryNames ?? const {},
          );
      final String genre =
          (data['genre'] as String?) ??
          (bukbukCategoryNames[languageCode] as String?) ??
          'General';

      // El marco de un documental lo resuelve el servidor con bukbukCategoryId y
      // bukbukId. Solo la persona de gamificación viaja desde la app: se reutiliza
      // la que quedó fijada en el documento fallido (generation.systemPrompt).
      String? systemPrompt;
      if (type == 'gamification_episode') {
        final generation = data['generation'];
        if (generation is Map) {
          final saved = generation['systemPrompt'];
          if (saved is String && saved.trim().isNotEmpty) systemPrompt = saved;
        }
      }

      final String? newDocId = await _startStoryWithFunctions(
        subProvider: subProvider,
        prompt: prompt,
        systemPrompt: systemPrompt,
        languageCode: languageCode,
        languageName: language,
        title: title,
        type: type,
        genre: genre,
        bukbukId: bukbukId.isEmpty ? null : bukbukId,
        bukbukCategoryId: bukbukCategoryId.isEmpty ? null : bukbukCategoryId,
        bukbukTypeNames: bukbukTypeNames,
        bukbukCategoryNames: bukbukCategoryNames,
        gamificationSubject: data['gamificationSubject'] as String?,
        gamificationEpisode: (data['gamificationEpisode'] as num?)?.toInt(),
        showSuccessDialog: false,
      );

      if (newDocId == null) return false;

      // El nuevo documento sustituye al fallido: si no, quedaban dos tarjetas
      // (la roja con su botón Reintentar, que volvía a duplicar).
      try {
        await docRef.delete();
      } catch (e) {
        debugPrint('⚠️ No se pudo borrar el documento fallido $docId: $e');
      }

      Get.snackbar(
        'info'.tr,
        'retryQueued'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e, st) {
      debugPrint('❌ Error reintentando $docId por Cloud Functions: $e');
      debugPrint('$st');
      Get.snackbar(
        'warningImage'.tr,
        'wentWrong'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  ///Community works

  /// Texto de comunidad por la callable `generateCommunityText`: el marco lo
  /// resuelve el servidor con la categoria y el tipo seleccionados. Si falla
  /// relanza el [StartStoryException] para que la pagina elija el aviso.
  Future<void> getCommunityResponse({
    required String userPrompt,
    required String languageCode,
  }) async {
    // Se leen antes de pasar a loading: si la selección aún no ha cargado, el
    // fallo no deja la flecha bloqueada.
    final BukBukCategoryModel category = bukBukCategoryModel;
    final BukBukTypeModel type = bukBukTypeModel;
    setRxRequestStatus(CheckStatus.loading);
    setCommunityRequestStatus(CheckStatus.loading);

    await requestCommunityText(
      _storyFunctions,
      prompt: userPrompt,
      languageCode: languageCode,
      category: category,
      type: type,
      onText: (text) {
        addDescription(text);
        setCommunityRequestStatus(CheckStatus.completed);
      },
      onError: (e) {
        debugPrint('⚠️ generateCommunityText falló: $e');
        setCommunityRequestStatus(CheckStatus.error);
        setRxRequestStatus(CheckStatus.error);
      },
    );
  }

  bool _isBooksGenerating = true;
  bool get isBooksGenerating => _isBooksGenerating;

  set isBooksGenerating(bool value) {
    _isBooksGenerating = value;
    notifyListeners();
  }

  createCommunityPost({
    required File pdfFile,
    required String? name,
    required String languageCode,
    required BuildContext context,
  }) async {
    try {
      setIsUploading(true, message: "uploadingToDatabase".tr);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection(communityCollection).doc();

      final newPostId = docRef.id;

      final audioFileUrl = await FirebaseStorageService().uploadToStorage(
        file: pdfFile,
        folderName: 'pdfs',
        pdfId: newPostId,
      );

      if (audioFileUrl == null) {
        throw Exception('Audio upload failed');
      }

      PublicPost publicPost = PublicPost(
        newCover: selectedCover,
        pdfUrl: await FirebaseStorageService().uploadToStorage(
          file: pdfFile,
          folderName: 'pdfUrl',
          pdfId: newPostId,
        ),
        likeByMe: [],
        saveByMeByMe: [],
        language: getLanguageName(languageCode),
        description: descriptions?.first,
        publishTime: DateTime.now().toIso8601String(),
        dairyName: name,
        type: '',
        totalLikes: 0,
        totalComments: 0,
        comments: [],
        creator: UserPublicPost(
          name: userProvider.user?.userName.toString(),
          imageUrl: userProvider.user?.profileImage.toString(),
          uid: userProvider.currentAuthUid,
        ),
        postId: newPostId,
      );

      await docRef.set(publicPost.toMap());

      print('✅ Post uploaded with ID: $newPostId');
    } catch (e) {
      print('❌ Failed to upload post: $e');
    } finally {
      setIsUploading(false);
    }
  }

  Future<File?> generatePdfForDescriptions(
    List<String> descriptions,
    String title,
    String languageCode,
  ) async {
    print('Start');
    try {
      isBooksGenerating = true;

      final PdfDocument document = PdfDocument();
      document.pageSettings = PdfPageSettings(
        PdfPageSize.a4,
        PdfPageOrientation.portrait,
      );
      document.pageSettings.margins.all = 40;

      final PdfFont font = await getFontForLanguage(languageCode, document, 20);
      final PdfFont fontTitle = await getFontForLanguage(
        languageCode,
        document,
        34,
      );
      final PdfBrush brush = PdfBrushes.black;

      for (final description in descriptions) {
        PdfPage page = document.pages.add();
        PdfGraphics graphics = page.graphics;
        double yPos = 0;

        graphics.drawString(
          title,
          fontTitle,
          brush: brush,
          bounds: Rect.fromLTWH(0, yPos, page.getClientSize().width, 120),
          format: PdfStringFormat(
            alignment: PdfTextAlignment.center,
            lineAlignment: PdfVerticalAlignment.middle,
            wordWrap: PdfWordWrapType.word,
          ),
        );
        yPos += 130;

        String text = description;
        PdfTextElement textElement = PdfTextElement(
          text: text,
          font: font,
          format: PdfStringFormat(
            alignment: PdfTextAlignment.justify,
            lineSpacing: 6,
          ),
        );

        Rect textBounds = Rect.fromLTWH(
          0,
          yPos,
          page.getClientSize().width,
          page.getClientSize().height - yPos,
        );
        PdfLayoutResult? result = textElement.draw(
          page: page,
          bounds: textBounds,
        );

        while (result != null &&
            result.bounds.bottom >= page.getClientSize().height - 40) {
          String remainingText = text.substring(text.length - 500);

          page = document.pages.add();
          yPos = 40;

          textElement = PdfTextElement(
            text: remainingText,
            font: font,
            format: PdfStringFormat(
              alignment: PdfTextAlignment.justify,
              lineSpacing: 6,
            ),
          );

          textBounds = Rect.fromLTWH(
            0,
            yPos,
            page.getClientSize().width,
            page.getClientSize().height - yPos,
          );
          result = textElement.draw(page: page, bounds: textBounds);
        }
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final directory = await getApplicationDocumentsDirectory();
      final pdfOutputFile = File('${directory.path}/dairy$timestamp.pdf');
      await pdfOutputFile.writeAsBytes(await document.save());

      document.dispose();
      isBooksGenerating = false;

      return pdfOutputFile;
    } catch (e) {
      isBooksGenerating = false;
      print(e.toString());
      return null;
    }
  }

  Future<PdfFont> getFontForLanguage(
    String languageCode,
    PdfDocument document,
    double fontSize,
  ) async {
    String fontPath;

    switch (languageCode) {
      case 'en_US':
      case 'en_GB':
      case 'es_ES':
      case 'es_CO':
      case 'es_AR':
      case 'es_MX':
      case 'fr_FR':
      case 'de_DE':
      case 'it_IT':
      case 'pt_PT':
      case 'pt_BR':
      case 'id_ID':
      case 'nl_NL':
      case 'tl_PH':
      case 'tr_TR':
      case 'sv_SE':
      case 'no_NO':
      case 'da_DK':
        fontPath = 'assets/fonts/LibreBaskervilleRegular.ttf';
        break;
      case 'vi_VN':
        fontPath = 'assets/fonts/CharisSILBI.ttf';
        break;
      case 'ar_AR':
        fontPath = 'assets/fonts/pdf/arab.ttf';
        break;
      case 'zh_CN':
        fontPath = 'assets/fonts/pdf/chin.ttf';
        break;
      case 'zh_TW':
        fontPath = 'assets/fonts/pdf/t_china.ttf';
        break;
      case 'hi_IN':
        fontPath = 'assets/fonts/pdf/hindi.ttf';
        break;
      case 'ja_JP':
        fontPath = 'assets/fonts/pdf/japan.ttf';
        break;
      case 'pl_PL':
        fontPath = 'assets/fonts/pdf/polish.ttf';
        break;
      case 'ko_KR':
        fontPath = 'assets/fonts/pdf/korea.ttf';
        break;
      case 'ru_RU':
        fontPath = 'assets/fonts/pdf/rus.ttf';
        break;
      case 'ta_IN':
        fontPath = 'assets/fonts/pdf/tamil.ttf';
        break;
      case 'el_GR':
        fontPath = 'assets/fonts/pdf/greek.ttf';
        break;
      default:
        fontPath = 'assets/fonts/LibreBaskervilleRegular.ttf';
        break;
    }

    print(fontPath);

    final fontData = await rootBundle.load(fontPath);
    return PdfTrueTypeFont(fontData.buffer.asUint8List(), fontSize);
  }
}
