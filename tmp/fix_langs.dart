import 'dart:io';
import 'dart:convert';

void main() {
  final file = File(
    r'c:\Users\PC\OneDrive\Escritorio\APPS MUHAMMAD\SAPERE - copia\sapere-main\lib\langauges\langauges.dart',
  );
  if (!file.existsSync()) {
    print('File not found');
    return;
  }

  final lines = file.readAsLinesSync(encoding: utf8);
  final out = <String>[];

  final enKeys = {
    'paywallHeroTitle': "Effortless Wisdom in 10 Minutes",
    'paywallHeroSubtitle': "Master any topic. Listen and grow while you move.",
    'monthlyPlanTitle': "Monthly Growth",
    'monthlyStarBadge': "MOST POPULAR",
    'benefitEasyLearning': "Master subjects while walking",
    'benefitAIPower': "Personal AI Research Team",
    'wiselyText': "Learn Wisely, Live Better",
  };

  final esKeys = {
    'paywallHeroTitle': "Sabiduría sin esfuerzo en 10 min",
    'paywallHeroSubtitle':
        "Domina cualquier tema. Escucha y crece mientras te mueves.",
    'monthlyPlanTitle': "Crecimiento Mensual",
    'monthlyStarBadge': "LO MÁS POPULAR",
    'benefitEasyLearning': "Domina temas mientras caminas",
    'benefitAIPower': "Equipo Personal de Investigación IA",
    'wiselyText': "Aprende con Sabiduría, Vive Mejor",
  };

  final frKeys = {
    'paywallHeroTitle': "Sagesse sans effort en 10 min",
    'paywallHeroSubtitle': "Apprenez tout. Écoutez et grandissez en bougeant.",
    'monthlyPlanTitle': "Croissance Mensuelle",
    'monthlyStarBadge': "PLUS POPULAIRE",
    'benefitEasyLearning': "Apprendre en marchant",
    'benefitAIPower': "Équipe de recherche IA",
    'wiselyText': "Apprenez avec sagesse",
  };

  final deKeys = {
    'paywallHeroTitle': "Mühelose Weisheit in 10 Min",
    'paywallHeroSubtitle': "Meistern Sie jedes Thema. Hören und wachsen.",
    'monthlyPlanTitle': "Monatliches Wachstum",
    'monthlyStarBadge': "BELIEBTESTE",
    'benefitEasyLearning': "Lernen beim Gehen",
    'benefitAIPower': "KI-Forschungsteam",
    'wiselyText': "Lerne weise, lebe besser",
  };

  final ptKeys = {
    'paywallHeroTitle': "Sabedoria sem esforço em 10 min",
    'paywallHeroSubtitle':
        "Domine qualquer tema. Ouça e cresça enquanto se move.",
    'monthlyPlanTitle': "Crescimento Mensal",
    'monthlyStarBadge': "MAIS POPULAR",
    'benefitEasyLearning': "Domine temas enquanto caminha",
    'benefitAIPower': "Equipe de Pesquisa IA",
    'wiselyText': "Aprenda com Sabedoria",
  };

  final itKeys = {
    'paywallHeroTitle': "Saggezza senza sforzo in 10 min",
    'paywallHeroSubtitle': "Domina qualsiasi argomento. Ascolta e cresci.",
    'monthlyPlanTitle': "Crescita Mensile",
    'monthlyStarBadge': "PIÙ POPOLARE",
    'benefitEasyLearning': "Impara mentre cammini",
    'benefitAIPower': "Team di ricerca IA",
    'wiselyText': "Impara con saggezza",
  };

  String currentLang = "";

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];

    if (line.contains("': {")) {
      try {
        currentLang = line.split("'")[1];
      } catch (e) {
        // ignore
      }
    }

    // Check if we are at the end of a language block
    bool isEndOfBlock = false;
    if (line.trim() == "}," &&
        i + 1 < lines.length &&
        lines[i + 1].contains("': {")) {
      isEndOfBlock = true;
    } else if (line.trim() == "}," && i + 1 == lines.length - 1) {
      isEndOfBlock = true;
    }

    if (isEndOfBlock && currentLang.isNotEmpty) {
      // Check if keys already exist (to avoid double adding if I partially ran it)
      bool alreadyExists = false;
      for (var j = i - 1; j > i - 15 && j >= 0; j--) {
        if (lines[j].contains("paywallHeroTitle")) {
          alreadyExists = true;
          break;
        }
      }

      if (!alreadyExists) {
        Map<String, String> keys = enKeys;
        if (currentLang.startsWith("es_"))
          keys = esKeys;
        else if (currentLang.startsWith("fr_"))
          keys = frKeys;
        else if (currentLang.startsWith("de_DE"))
          keys = deKeys;
        else if (currentLang.startsWith("pt_"))
          keys = ptKeys;
        else if (currentLang.startsWith("it_IT"))
          keys = itKeys;

        for (var key in keys.keys) {
          out.add("      '$key': \"${keys[key]}\",");
        }
      }
    }

    out.add(line);
  }

  file.writeAsStringSync(out.join("\n"), encoding: utf8);
  print('Successfully updated langauges.dart with UTF-8 encoding');
}
