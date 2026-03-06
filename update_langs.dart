import 'dart:io';

void main() async {
  final file = File(
    r'c:\Users\PC\OneDrive\Escritorio\APPS MUHAMMAD\SAPERE - copia\sapere-main\lib\langauges\langauges.dart',
  );

  if (!await file.exists()) {
    print('File not found');
    return;
  }

  List<String> lines = await file.readAsLines();

  final Map<String, Map<String, String>> translations = {
    'en': {
      'enjoyingSapere': 'Do you like the app?',
      'rateUsDescription':
          'Your support helps us grow. Please rate us 5 stars!',
      'rateNow': 'RATE NOW',
      'maybeLater': 'Maybe Later',
    },
    'es': {
      'enjoyingSapere': '¿Te gusta la app?',
      'rateUsDescription':
          'Tu apoyo nos ayuda a crecer. ¡Califícanos con 5 estrellas!',
      'rateNow': 'CALIFICAR AHORA',
      'maybeLater': 'Más tarde',
    },
    'fr': {
      'enjoyingSapere': 'Aimez-vous l\'application ?',
      'rateUsDescription':
          'Votre soutien nous aide à grandir. Gagnez 5 étoiles !',
      'rateNow': 'ÉVALUER',
      'maybeLater': 'Plus tard',
    },
    'de': {
      'enjoyingSapere': 'Gefällt dir die App?',
      'rateUsDescription':
          'Deine Unterstützung hilft uns. Bitte mit 5 Sternen bewerten!',
      'rateNow': 'JETZT BEWERTEN',
      'maybeLater': 'Vielleicht später',
    },
    'pt': {
      'enjoyingSapere': 'Gosta do aplicativo?',
      'rateUsDescription':
          'Seu apoio nos ajuda a crescer. Avalie com 5 estrelas!',
      'rateNow': 'AVALIAR AGORA',
      'maybeLater': 'Mais tarde',
    },
    'it': {
      'enjoyingSapere': 'Ti piace l\'app?',
      'rateUsDescription':
          'Il tuo supporto ci aiuta a crescere. Valutaci 5 stelle!',
      'rateNow': 'VALUTA ORA',
      'maybeLater': 'Forse più tardi',
    },
    'ru': {
      'enjoyingSapere': 'Нравится приложение?',
      'rateUsDescription':
          'Ваша поддержка помогает нам расти. Оцените нас на 5 звезд!',
      'rateNow': 'ОЦЕНИТЬ',
      'maybeLater': 'Позже',
    },
    'zh': {
      'enjoyingSapere': '你喜欢这个应用吗？',
      'rateUsDescription': '你的支持能帮助我们成长。请给我们5星好评！',
      'rateNow': '立即评价',
      'maybeLater': '以后再说',
    },
    'ja': {
      'enjoyingSapere': 'アプリを気に入りましたか？',
      'rateUsDescription': 'あなたのサポートが私たちの励みになります。5つ星で評価してください！',
      'rateNow': '今すぐ評価',
      'maybeLater': '後で',
    },
    'ko': {
      'enjoyingSapere': '앱이 마음에 드시나요?',
      'rateUsDescription': '여러분의 지원이 우리를 성장하게 합니다. 5별로 평가해주세요!',
      'rateNow': '지금 평가하기',
      'maybeLater': '나중에',
    },
    'hi': {
      'enjoyingSapere': 'क्या आपको ऐप पसंद है?',
      'rateUsDescription':
          'आपका समर्थन हमें बढ़ने में मदद करता है। कृपया हमें 5 स्टार दें!',
      'rateNow': 'अभी रेट करें',
      'maybeLater': 'शायद बाद में',
    },
    'ar': {
      'enjoyingSapere': 'هل يعجبك التطبيق؟',
      'rateUsDescription': 'دعمك يساعدنا على النمو. يرجى تقييمنا بـ 5 نجوم!',
      'rateNow': 'قيم الآن',
      'maybeLater': 'ربما لاحقا',
    },
    'tr': {
      'enjoyingSapere': 'Uygulamayı beğendiniz mi?',
      'rateUsDescription':
          'Desteğiniz büyümemize yardımcı oluyor. Lütfen bize 5 yıldız verin!',
      'rateNow': 'ŞİMDİ DEĞERLENDİR',
      'maybeLater': 'Belki sonra',
    },
    'id': {
      'enjoyingSapere': 'Apakah Anda menyukai aplikasinya?',
      'rateUsDescription':
          'Dukungan Anda membantu kami berkembang. Beri kami 5 bintang!',
      'rateNow': 'NILAI SEKARANG',
      'maybeLater': 'Mungkin nanti',
    },
    'vi': {
      'enjoyingSapere': 'Bạn có thích ứng dụng không?',
      'rateUsDescription':
          'Sự ủng hộ của bạn giúp chúng tôi phát triển. Đánh giá 5 sao nhé!',
      'rateNow': 'ĐÁNH GIÁ NGAY',
      'maybeLater': 'Để sau',
    },
    'ur': {
      'enjoyingSapere': 'کیا آپ کو ایپ پسند آ رہی ہے؟',
      'rateUsDescription':
          'آپ کی حمایت ہمیں آگے بڑھنے میں مدد دیتی ہے۔ براہ کرم 5 اسٹار دیں۔',
      'rateNow': 'ابھی ریٹ کریں',
      'maybeLater': 'شاید بعد میں',
    },
    'th': {
      'enjoyingSapere': 'คุณชอบแอปนี้ไหม?',
      'rateUsDescription':
          'การสนับสนุนของคุณช่วยให้เราเติบโต โปรดให้คะแนนเรา 5 ดาว!',
      'rateNow': 'ให้คะแนนเลย',
      'maybeLater': 'ไว้ทีหลัง',
    },
    'nl': {
      'enjoyingSapere': 'Vind je de app leuk?',
      'rateUsDescription':
          'Jouw steun helpt ons groeien. Beoordeel ons met 5 sterren!',
      'rateNow': 'BEOORDEEL NU',
      'maybeLater': 'Misschien later',
    },
    'pl': {
      'enjoyingSapere': 'Podoba Ci się aplikacja?',
      'rateUsDescription':
          'Twoje wsparcie pomaga nam się rozwijać. Oceń nas na 5 gwiazdek!',
      'rateNow': 'OCEŃ TERAZ',
      'maybeLater': 'Może później',
    },
  };

  String currentLang = 'en';
  List<String> newLines = [];
  bool skipNextIfLongDesc = false;

  final langRegex = RegExp(r"^\s*'([a-z]{2})_[A-Z]{2}': \{");

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];

    if (skipNextIfLongDesc) {
      if (!line.trim().startsWith("'")) {
        // Still part of the long string
        continue;
      } else {
        skipNextIfLongDesc = false;
      }
    }

    final match = langRegex.firstMatch(line);
    if (match != null) {
      currentLang = match.group(1)!;
      newLines.add(line);
      continue;
    }

    if (line.contains("'enjoyingSapere':")) {
      final trans = translations[currentLang] ?? translations['en']!;
      newLines.add("      'enjoyingSapere': \"${trans['enjoyingSapere']}\",");
      continue;
    }

    if (line.contains("'rateUsDescription':")) {
      final trans = translations[currentLang] ?? translations['en']!;
      newLines.add(
        "      'rateUsDescription': \"${trans['rateUsDescription']}\",",
      );

      // Lookahead to see if next line is a continuation (doesn't start with quote)
      if (i + 1 < lines.length &&
          !lines[i + 1].trim().startsWith("'") &&
          !lines[i + 1].trim().startsWith("}")) {
        skipNextIfLongDesc = true;
      }
      continue;
    }

    if (line.contains("'rateNow':")) {
      final trans = translations[currentLang] ?? translations['en']!;
      newLines.add("      'rateNow': \"${trans['rateNow']}\",");
      continue;
    }

    if (line.contains("'maybeLater':")) {
      final trans = translations[currentLang] ?? translations['en']!;
      newLines.add("      'maybeLater': \"${trans['maybeLater']}\",");
      continue;
    }

    newLines.add(line);
  }

  await file.copy(file.path + '.bak.2');
  await file.writeAsString(newLines.join('\n'));
  print('Updated \$newLines.length lines.');
}
