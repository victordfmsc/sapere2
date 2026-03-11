import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/constant/voice_data.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/core/services/firebase_storage_service.dart';
import 'package:sapere/models/sapere_category_type_model.dart';
import 'package:sapere/models/sapere_type_model.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/models/public_post.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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

  Future<bool> checkStoryStatus(String uid) async {
    print('Checking status for $uid');
    final url = Uri.parse(
      'https://sapereapi-production.up.railway.app/v1/api/sapere/upload-audio-status/$uid',
    );

    try {
      final headers = {'Content-Type': 'application/json'};
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));

      print('Status code is ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking status: $e');
      return false;
    }
  }
  // Future<void> checkStoryStatus(String uid) async {
  //   print('Checking status');
  //   final url = Uri.parse(
  //     'https://sapereapi-production.up.railway.app/v1/api/sapere/upload-audio-status/$uid',
  //   );
  //
  //   try {
  //     final headers = {'Content-Type': 'application/json'};
  //     final response = await http.get(url, headers: headers);
  //
  //     print('Status code is ${response.statusCode}');
  //
  //     if (response.statusCode == 200) {
  //     } else {
  //       print('Fail to check');
  //     }
  //   } catch (e) {
  //     print('Error checking status: $e');
  //   }
  // }

  Future<void> generateStoryFromServer({
    required String systemPrompt,
    required String baseUserPrompt,
    required String languageCode,
  }) async {
    List<String> prompts = [
      "${'generateChapterOne'.tr} $baseUserPrompt",
      "generateChapterLast".tr,
    ];
    final url = Uri.parse(
      'https://sapereapi-production.up.railway.app/v1/api/sapere/prompt',
    );
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      "systemPrompt": systemPrompt,
      "prompt": baseUserPrompt,
      "voiceId": getActiveVoiceId(languageCode),
      "bukbukCategoryNames": bukBukCategoryModel.names,
      "bukbukTypeNames": bukBukTypeModel.names,
      "coverImage": selectedCover,
      "language": getLanguageName(languageCode),
      "uId": FirebaseAuth.instance.currentUser?.uid,
      "bukbukCategoryId": bukBukCategoryModel.docId,
      "bukbukId": bukBukTypeModel.id,
      "listOfPrompts": prompts,
      "genre": bukBukCategoryModel.names[languageCode],
    });
    print(
      'Body of API voice id is ${getActiveVoiceId(languageCode)} image is $selectedCover uid is ${FirebaseAuth.instance.currentUser?.uid} category is ${bukBukCategoryModel.docId}  bukbuk id is ${bukBukTypeModel.id} prompts is $prompts genre is ${bukBukCategoryModel.names[languageCode]} ',
    );

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
      } else {
        print('Failed to generate story: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> generateFullStory({
    required String systemPrompt,
    required String baseUserPrompt,
    required String languageCode,
  }) async {
    try {
      clearGenerationSteps();
      _descriptions.clear();
      sapereTitle = "";

      // ── PHASE 1 (instant): Create Firestore doc immediately ──────────────
      // We create the post with a placeholder title so the user gets a doc id
      // right away and we can navigate home without waiting for the AI.
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('sapere').doc();
      final newPostId = docRef.id;
      final time = Timestamp.fromMicrosecondsSinceEpoch(
        DateTime.now().microsecondsSinceEpoch,
      );
      final defaultCover = premiumDefaultCover;
      final String languageName = getLanguageName(languageCode);

      // Deduct credit before anything else
      final subProvider = Provider.of<InAppPurchaseProvider>(
        Get.context!,
        listen: false,
      );
      final creditOk = await subProvider.deductCredit();
      if (!creditOk) {
        debugPrint('❌ Credit deduction failed. Aborting.');
        showDialog(
          context: Get.context!,
          builder:
              (context) => OutOfCreditsDialog(
                nextRefillDate: subProvider.nextRefillDate,
              ),
        );
        return;
      }

      final newPost = BukBukPost(
        postId: newPostId,
        sapereCategoryId: bukBukCategoryModel.docId,
        sapereId: bukBukTypeModel.id,
        sapereCategoryNames: bukBukCategoryModel.names,
        sapereTypeNames: bukBukTypeModel.names,
        sapereName: "...", // placeholder — updated by background task
        newCover: selectedCover.isEmpty ? defaultCover : selectedCover,
        sapereUrl: null,
        publishTime: time,
        language: languageName,
        languageCode: languageCode,
        description: null,
        uId: FirebaseAuth.instance.currentUser?.uid,
        type: 'sapere',
      );

      await docRef.set(newPost.toMap());
      print('✅ Post doc created instantly: $newPostId');

      // Show success dialog and navigate home immediately
      setSelectedCover('');
      Get.dialog(
        CreationSuccessDialog(
          credits:
              (Provider.of<UserProvider>(
                        Get.context!,
                        listen: false,
                      ).user?.credits ??
                      0)
                  .toString(),
        ),
      );

      // ── PHASE 2 (background): Generate title + audio ─────────────────────
      // Fire-and-forget — UI is already unblocked.
      unawaited(
        _generateTitleAndAudioInBackground(
          docId: newPostId,
          docRef: docRef,
          systemPrompt: systemPrompt,
          baseUserPrompt: baseUserPrompt,
          languageCode: languageCode,
          languageName: languageName,
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
    }
  }

  /// Background task: generate AI title, update Firestore, then call Railway.
  Future<void> _generateTitleAndAudioInBackground({
    required String docId,
    required DocumentReference docRef,
    required String systemPrompt,
    required String baseUserPrompt,
    required String languageCode,
    required String languageName,
  }) async {
    try {
      final generatedTitle = await generateTitle(
        genre: bukBukCategoryModel.names[languageCode].toString(),
        userPrompt: baseUserPrompt,
        languageCode: languageCode,
      );

      // Fallback logic if AI title fails
      String finalTitle;
      if (generatedTitle != null &&
          generatedTitle.isNotEmpty &&
          generatedTitle != "...") {
        finalTitle = generatedTitle;
      } else {
        // Fallback: Use the first 30 chars of the prompt or a localized default
        String sanitizedPrompt =
            baseUserPrompt.replaceAll(RegExp(r'[#*]'), '').trim();
        if (sanitizedPrompt.length > 40) {
          finalTitle = "${sanitizedPrompt.substring(0, 37)}...";
        } else if (sanitizedPrompt.isNotEmpty) {
          finalTitle = sanitizedPrompt;
        } else {
          finalTitle = "Audio Book";
        }
      }

      sapereTitle = finalTitle;
      print('🎯 Background title (final): $finalTitle');

      // 2) Patch the Firestore doc with the real title
      await docRef.update({'sapereName': finalTitle});

      // 3) Fire audio generation (fully async, Railway handles it)
      generateAudioFromServer(
        languageCode: languageCode,
        uId: FirebaseAuth.instance.currentUser!.uid,
        docId: docId,
        systemPrompt: systemPrompt,
        prompt: baseUserPrompt,
        language: languageName,
        title: finalTitle,
      );

      print('🚀 Background task complete for doc: $docId');
    } catch (e) {
      print('⚠️ Background generation error (non-blocking): $e');
    }
  }

  Future<void> generateAudioFromServer({
    required String uId,
    required String systemPrompt,
    required String prompt,
    required String docId,
    required String languageCode,
    required String language,
    required String title,
    String? voiceId,
  }) async {
    try {
      setGenerationStep(GenerationStep.invokingNarrator, docId: docId);
      setIsUploading(true, message: 'generatingAudio'.tr);

      final url = Uri.parse(
        'https://sapereapi-production.up.railway.app/v1/api/sapere/upload-audio',
      );

      final body = jsonEncode({
        "uId": uId,
        "systemPrompt": systemPrompt,
        "prompt": prompt,
        "language": language,
        "voiceId": voiceId ?? getActiveVoiceId(languageCode),
        "docId": docId,
        "title": title,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setGenerationStep(GenerationStep.completed);
        print('✅ Audio generation process initiated successfully');
      } else {
        setGenerationStep(GenerationStep.error);
        throw Exception('Failed to generate audio: ${response.statusCode}');
      }
    } catch (e) {
      setGenerationStep(GenerationStep.error);
      print('❌ Error generating audio: $e');
      Get.snackbar(
        'warningImage'.tr,
        'wentWrong'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setIsUploading(false);
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

  /// NEW: Client-side DALL-E cover generation
  Future<void> generateCoverWithDalle({
    required String prompt,
    required String docId,
  }) async {
    try {
      print('🎨 Generating DALL-E cover for docId: $docId');

      // 1. Fetch API Key from Firestore
      final keySnapshot =
          await FirebaseFirestore.instance
              .collection('keys')
              .doc('openai')
              .get();
      final apiKey = keySnapshot.data()?['api_key'];

      if (apiKey == null || apiKey.isEmpty) {
        print('❌ OpenAI API Key not found in Firestore (keys/openai).');
        return;
      }

      // 2. Prepare OpenAI Request
      final url = Uri.parse('https://api.openai.com/v1/images/generations');
      final optimizedPrompt =
          "Cinematic, artistic, and ultra-detailed cover for an audio documentary titled: '$prompt'. Premium style, rich texture, deep colors, dramatic lighting, no text.";

      final body = jsonEncode({
        "model": "dall-e-3",
        "prompt": optimizedPrompt,
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json",
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String base64Image = data['data'][0]['b64_json'];
        final Uint8List bytes = base64Decode(base64Image);

        // 3. Upload to Firebase Storage
        final coverUrl = await FirebaseStorageService()
            .uploadCoverBytesToStorage(
              bytes: bytes,
              folderName: 'gamification_covers',
            );

        if (coverUrl != null && coverUrl.isNotEmpty) {
          // 4. Update Firestore Document
          await FirebaseFirestore.instance
              .collection('sapere')
              .doc(docId)
              .update({'newCover': coverUrl, 'coverImage': coverUrl});

          lastGeneratedCoverUrl = coverUrl;
          print('✅ DALL-E Cover generated and updated successfully for $docId');
        }
      } else {
        print('❌ OpenAI DALL-E API failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error during client-side DALL-E generation: $e');
    }
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
  //
  // Future<void> getUserResponse({
  //   required String systemPrompt,
  //   required String userPrompt,
  //   required String languageCode,
  //   required String id,
  // }) async {
  //   print('🌐 Generate API called');
  //
  //   final String url = 'https://web-production-033f3.up.railway.app/generate';
  //
  //   final String langName = (getLanguageName(languageCode)).trim();
  //   final String safeLang = langName.isEmpty ? 'English' : langName;
  //
  //   print('Language name is $safeLang');
  //
  //   final body = {
  //     "messages": [
  //       {"role": "system", "content": systemPrompt},
  //       {"role": "user", "content": userPrompt},
  //     ],
  //     "max_tokens": 8192,
  //     "temperature": 1.4,
  //     "frequency_penalty": 1.5,
  //     "presence_penalty": 0.3,
  //     "conversation_id": id,
  //     "stream": false,
  //     "language": safeLang,
  //   };
  //
  //   var headers = {
  //     'Content-Type': 'application/json',
  //     'Authorization': 'Bearer YOUR_HF_TOKEN',
  //   };
  //
  //   print('🌐 API Url: $url');
  //   print('📝 API Language: $safeLang');
  //   print('📦 API Body: $body');
  //
  //   try {
  //     final apiStart = DateTime.now();
  //
  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: headers,
  //       body: json.encode(body),
  //     );
  //
  //     final apiEnd = DateTime.now();
  //     final apiDuration = apiEnd.difference(apiStart);
  //     print(
  //       "⏱️ API Response Time: ${apiDuration.inSeconds}.${apiDuration.inMilliseconds % 1000}s",
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final decodedBody = utf8.decode(response.bodyBytes);
  //       final Map<String, dynamic> responseData = json.decode(decodedBody);
  //
  //       final dynamic raw = responseData['script'];
  //       final String content = (raw is String) ? raw : (raw ?? '').toString();
  //
  //       final String cleanedContent =
  //           content
  //               .replaceAll(RegExp(r'[#*]'), '')
  //               .replaceAll('â', '—')
  //               .trim();
  //
  //       if (cleanedContent.isEmpty) {
  //         throw Exception('Model returned empty content.');
  //       }
  //
  //       print('🧩 Cleaned content length: ${cleanedContent.length}');
  //       addDescription(cleanedContent);
  //     } else {
  //       print('❌ Failed: code=${response.statusCode}, body=${response.body}');
  //       throw Exception('API failed with status: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print("⚠️ Error in getUserResponse: $e");
  //     rethrow;
  //   }
  // }

  Future<String?> generateTitle({
    required String genre,
    required String userPrompt,
    required String languageCode,
  }) async {
    addGenerationStep("📝 Generating title...");

    final String url =
        'https://sapereapi-production.up.railway.app/generate/title';
    final String lang = (getLanguageName(languageCode)).trim();
    final String safeLang = lang.isEmpty ? 'English' : lang;

    final body = {
      "input": 'Generate the title in $safeLang language $userPrompt',
      "genre": genre,
    };
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(decodedBody);
        String title = (responseData['title'] ?? '').toString().trim();
        title = title.replaceAll(RegExp(r'[#*]'), '').trim();

        if (title.isEmpty || title == "...") {
          print('⚠️ API returned empty or placeholder title.');
          return null;
        }

        print('🎯 Cleaned Title: $title');
        return title;
      } else {
        print(
          '❌ Failed to generate title: code=${response.statusCode} body=${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('⚠️ Error generating title: $e');
      return null;
    }
  }

  createBukbukPost({
    required String? name,
    required String languageCode,
    required String systemPrompt,
    required String prompt,
  }) async {
    try {
      // --- NEW: Automated Credit Deduction ---
      final subProvider = Provider.of<InAppPurchaseProvider>(
        Get.context!,
        listen: false,
      );
      final success = await subProvider.deductCredit();

      if (!success) {
        debugPrint('❌ Credit deduction failed. Aborting generation.');
        showDialog(
          context: Get.context!,
          builder:
              (context) => OutOfCreditsDialog(
                nextRefillDate: subProvider.nextRefillDate,
              ),
        );
        return;
      }

      setIsUploading(true, message: "uploadingToDatabase".tr);

      final firestore = FirebaseFirestore.instance;
      // final docRef = firestore.collection(sapereCollection).doc();
      final docRef = firestore.collection('sapere').doc();
      String languageName = getLanguageName(languageCode);

      final newPostId = docRef.id;
      final time = Timestamp.fromMicrosecondsSinceEpoch(
        DateTime.now().microsecondsSinceEpoch,
      );

      final defaultCover = premiumDefaultCover;

      final newPost = BukBukPost(
        postId: newPostId,
        sapereCategoryId: bukBukCategoryModel.docId,
        sapereId: bukBukTypeModel.id,
        sapereCategoryNames: bukBukCategoryModel.names,
        sapereTypeNames: bukBukTypeModel.names,
        sapereName: name ?? "Audio Book",
        newCover: selectedCover.isEmpty ? defaultCover : selectedCover,
        sapereUrl: null,
        publishTime: time,
        language: languageName,
        languageCode: languageCode,
        description: null,
        uId: FirebaseAuth.instance.currentUser?.uid,
        type: 'sapere',
      );

      // We AWAIT this to ensure the document exists before the UI navigates away
      await docRef.set(newPost.toMap());
      print('✅ Post document created: $newPostId');

      // 3) Call Audio and Cover Generation on Backend
      // 3) Call Audio API (Background)
      generateAudioFromServer(
        languageCode: languageCode,
        uId: FirebaseAuth.instance.currentUser!.uid.toString(),
        docId: docRef.id,
        systemPrompt: systemPrompt,
        prompt: prompt,
        language: languageName,
        title: name ?? "Audio Book",
      );

      /*
      // 4) Call Cover API (Background)
      generateCoverFromServer(
        prompt: sapereTitle,
        docId: docRef.id,
        uId: FirebaseAuth.instance.currentUser!.uid.toString(),
        language: languageName,
      );
      */

      // Show Success Dialog
      Get.dialog(
        CreationSuccessDialog(
          credits:
              (Provider.of<UserProvider>(
                        Get.context!,
                        listen: false,
                      ).user?.credits ??
                      0)
                  .toString(),
        ),
      );
      setSelectedCover('');
      print('✅ Post uploaded, audio and cover triggered for ID: $newPostId');
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
      // --- NEW: Automated Credit Deduction ---
      final subProvider = Provider.of<InAppPurchaseProvider>(
        context,
        listen: false,
      );
      final success = await subProvider.deductCredit();

      if (!success) {
        debugPrint('❌ Credit deduction failed. Aborting generation.');
        showDialog(
          context: context,
          builder:
              (context) => OutOfCreditsDialog(
                nextRefillDate: subProvider.nextRefillDate,
              ),
        );
        return;
      }

      lastGeneratedCoverUrl = null;
      setGenerationStep(
        GenerationStep.designingScript,
        episodeNumber: episodeNumber,
      );
      setIsUploading(true, message: "uploadingToDatabase".tr);

      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('sapere').doc();
      String languageName = getLanguageName(languageCode);

      // --- 0. CATEGORY LINKING ---
      final categoryInfo = await _ensureCategoryExists(categoryName);

      final newPostId = docRef.id;
      final time = Timestamp.fromMicrosecondsSinceEpoch(
        DateTime.now().microsecondsSinceEpoch,
      );

      // --- 1. SAVE TO DATABASE IMMEDIATELY (Instant Feedback) ---
      final defaultCover = premiumDefaultCover;

      final newPost = BukBukPost(
        postId: newPostId,
        sapereCategoryId: categoryInfo['id'],
        sapereCategoryNames: Map<String, String>.from(categoryInfo['names']),
        sapereName: "$subjectName - Ep $episodeNumber: $episodeTitle",
        newCover: defaultCover,
        publishTime: time,
        language: languageName,
        languageCode: languageCode,
        uId: FirebaseAuth.instance.currentUser?.uid,
        type: 'gamification_episode',
        gamificationSubject: subjectName,
        gamificationEpisode: episodeNumber,
      );

      // Save to database instantly so it appears in the list
      await docRef.set(newPost.toMap());
      print('✅ Initial Firestore document created: $newPostId');

      // --- 2. LAUNCH COVER GENERATION (Background) ---
      // We don't await this for the main flow to proceed to audio
      setGenerationStep(
        GenerationStep.generatingCover,
        episodeNumber: episodeNumber,
      );

      // Handle cover in background via Backend
      // The Railway backend will now handle cover generation.
      // Keeping a small check if we want to force a fallback here, but preferably
      // let the server do its magic.

      // --- 3. TRIGGER AUDIO & COVER GENERATION (Background) ---
      generateAudioFromServer(
        languageCode: languageCode,
        uId: FirebaseAuth.instance.currentUser!.uid.toString(),
        docId: docRef.id,
        systemPrompt: systemPrompt,
        prompt: prompt,
        language: languageName,
        title: "$subjectName - Ep $episodeNumber: $episodeTitle",
      );

      /*
      generateCoverFromServer(
        prompt: "$subjectName - Ep $episodeNumber: $episodeTitle",
        docId: docRef.id,
        uId: FirebaseAuth.instance.currentUser!.uid.toString(),
        language: languageName,
      );
      */

      // Show Success Dialog
      Get.dialog(
        CreationSuccessDialog(
          credits:
              (Provider.of<UserProvider>(
                        context,
                        listen: false,
                      ).user?.credits ??
                      0)
                  .toString(),
        ),
      );
      setSelectedCover('');
      print(
        '✅ Gamification Episode creation process initiated (background audio & cover)',
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

  ///Community works

  Future<void> getCommunityResponse({
    required String systemPrompt,
    required String userPrompt,
    required String languageCode,
    required String id,
  }) async {
    setRxRequestStatus(CheckStatus.loading);
    setCommunityRequestStatus(CheckStatus.loading);

    String url = 'https://sapereapi-production.up.railway.app/generate';

    var body = {
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userPrompt},
      ],
      "max_tokens": 8192,
      "temperature": 1.4,
      "frequency_penalty": 1.5,
      "presence_penalty": 0.3,
      "conversation_id": id,
      "stream": false,
      "language": getLanguageName(languageCode),
    };
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_HF_TOKEN',
    };

    print('The Api Url is $url');
    print('The Api Header is $headers');
    print('The Api language is ${getLanguageName(languageCode)}');
    print('The Api Body is $body');

    try {
      final apiStart = DateTime.now();

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      final apiEnd = DateTime.now();
      final apiDuration = apiEnd.difference(apiStart);
      print(
        "⏱️API Response Time: ${apiDuration.inSeconds}.${apiDuration.inMilliseconds % 1000} seconds",
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(decodedBody);
        final String content = responseData['script'] ?? '';

        final String cleanedContent =
            content
                .replaceAll(RegExp(r'[#*]'), '')
                .replaceAll('â', '—')
                .trim();

        print('Description from the content after cleaning $cleanedContent');
        addDescription(cleanedContent);

        setCommunityRequestStatus(CheckStatus.completed);
      } else {
        print('❌ Failed to get response: ${response.body}');
        print('❌ Failed to get response code: ${response.statusCode}');
        setCommunityRequestStatus(CheckStatus.error);
        setRxRequestStatus(CheckStatus.error);
        throw Exception('API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print("⚠️ Error: ${e.toString()}");
      setCommunityRequestStatus(CheckStatus.error);
      setRxRequestStatus(CheckStatus.error);
      throw Exception('API failed');
    }
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
