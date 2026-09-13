/// Detecta el idioma de un texto y devuelve un locale de la app (xx_YY).
class LanguageDetectorService {
  static final _scripts = <RegExp, String>{
    RegExp(r'\p{Script=Hiragana}|\p{Script=Katakana}', unicode: true): 'ja_JP',
    RegExp(r'\p{Script=Hangul}', unicode: true): 'ko_KR',
    RegExp(r'\p{Script=Han}', unicode: true): 'zh_CN',
    RegExp(r'\p{Script=Arabic}', unicode: true): 'ar_AR',
    RegExp(r'\p{Script=Cyrillic}', unicode: true): 'ru_RU',
    RegExp(r'\p{Script=Devanagari}', unicode: true): 'hi_IN',
    RegExp(r'\p{Script=Tamil}', unicode: true): 'ta_IN',
    RegExp(r'\p{Script=Greek}', unicode: true): 'el_GR',
  };

  static const _stopwords = <String, Set<String>>{
    'es_ES': {
      'el', 'la', 'los', 'las', 'de', 'del', 'que', 'y', 'en', 'un', 'una',
      'es', 'por', 'con', 'para', 'no', 'se', 'su', 'al', 'lo', 'como', 'más',
      'pero', 'sus', 'le', 'ya', 'o', 'este', 'sí', 'porque', 'esta', 'entre',
      'cuando', 'muy', 'sin', 'sobre', 'también', 'me', 'hasta', 'hay',
      'donde', 'quien', 'desde', 'todo', 'nos', 'durante', 'todos', 'uno',
      'les', 'ni', 'contra', 'otros', 'ese', 'eso', 'ante', 'ellos', 'e',
      'esto', 'mí', 'antes', 'algunos', 'qué', 'unos', 'yo', 'otro', 'otras',
      'otra', 'él', 'tanto', 'esa', 'estos', 'mucho', 'era', 'fue', 'había',
    },
    'en_US': {
      'the', 'of', 'and', 'to', 'in', 'a', 'is', 'that', 'for', 'it', 'as',
      'was', 'with', 'be', 'by', 'on', 'not', 'he', 'i', 'this', 'are', 'or',
      'his', 'from', 'at', 'which', 'but', 'have', 'an', 'had', 'they', 'you',
      'were', 'their', 'one', 'all', 'we', 'can', 'her', 'has', 'there',
      'been', 'if', 'more', 'when', 'will', 'would', 'who', 'so', 'no',
      'she', 'said', 'what', 'about', 'into', 'than', 'them', 'could',
      'then', 'its', 'only', 'other', 'some', 'these', 'two', 'may', 'do',
    },
    'fr_FR': {
      'le', 'la', 'les', 'de', 'des', 'du', 'et', 'est', 'un', 'une', 'en',
      'que', 'qui', 'dans', 'pour', 'pas', 'sur', 'au', 'plus', 'par',
      'il', 'elle', 'nous', 'vous', 'ils', 'ne', 'ce', 'cette', 'ces',
      'mais', 'avec', 'son', 'sa', 'ses', 'être', 'avoir', 'je', 'tu',
      'aux', 'ou', 'où', 'était', 'été', 'sont', 'ont', 'leur', 'très',
      'comme', 'tout', 'fait', 'même', 'aussi', 'bien', 'sans',
    },
    'de_DE': {
      'der', 'die', 'das', 'und', 'ist', 'nicht', 'ein', 'eine', 'zu', 'den',
      'von', 'mit', 'sich', 'auf', 'für', 'des', 'dem', 'im', 'auch', 'es',
      'an', 'als', 'aus', 'er', 'sie', 'wir', 'ich', 'du', 'ihr', 'aber',
      'oder', 'wie', 'wenn', 'noch', 'nach', 'bei', 'nur', 'war', 'wird',
      'sind', 'hat', 'werden', 'einer', 'einem', 'einen', 'über', 'sehr',
    },
    'pt_PT': {
      'o', 'a', 'os', 'as', 'de', 'do', 'da', 'dos', 'das', 'e', 'é', 'que',
      'em', 'um', 'uma', 'para', 'com', 'não', 'se', 'na', 'no', 'nos',
      'por', 'mais', 'como', 'mas', 'ao', 'ele', 'ela', 'seu', 'sua', 'ou',
      'foi', 'são', 'também', 'já', 'está', 'muito', 'isso', 'esse', 'essa',
      'eu', 'você', 'até', 'pelo', 'pela', 'quando', 'nós', 'ser', 'tem',
    },
    'it_IT': {
      'il', 'lo', 'la', 'i', 'gli', 'le', 'di', 'del', 'della', 'dei', 'delle',
      'e', 'è', 'che', 'un', 'una', 'in', 'per', 'con', 'non', 'si', 'al',
      'alla', 'da', 'ma', 'come', 'più', 'anche', 'sono', 'ha', 'hanno',
      'io', 'tu', 'lui', 'lei', 'noi', 'voi', 'loro', 'questo', 'questa',
      'nel', 'nella', 'sul', 'sulla', 'era', 'erano', 'molto', 'dove',
    },
    'nl_NL': {
      'de', 'het', 'een', 'en', 'van', 'is', 'in', 'dat', 'op', 'te', 'zijn',
      'niet', 'met', 'voor', 'er', 'aan', 'ook', 'als', 'maar', 'om', 'bij',
      'ik', 'je', 'hij', 'zij', 'wij', 'we', 'ze', 'dit', 'die', 'naar',
      'wat', 'nog', 'dan', 'werd', 'heeft', 'hebben', 'wordt', 'kan', 'uit',
    },
    'pl_PL': {
      'i', 'w', 'z', 'na', 'się', 'nie', 'jest', 'to', 'do', 'że', 'o', 'a',
      'jak', 'po', 'ale', 'co', 'tak', 'za', 'od', 'ja', 'ty', 'on', 'ona',
      'my', 'wy', 'oni', 'był', 'była', 'było', 'być', 'przez', 'już',
      'tylko', 'jego', 'jej', 'ich', 'tego', 'tym', 'są', 'może', 'bardzo',
    },
    'sv_SE': {
      'och', 'att', 'det', 'är', 'en', 'ett', 'som', 'i', 'på', 'av', 'för',
      'med', 'till', 'den', 'inte', 'har', 'de', 'om', 'han', 'hon', 'jag',
      'du', 'vi', 'ni', 'var', 'kan', 'från', 'men', 'så', 'sig', 'också',
      'eller', 'vad', 'när', 'här', 'där', 'skulle', 'hade', 'mycket',
    },
    'no_NO': {
      'og', 'i', 'det', 'er', 'en', 'et', 'som', 'på', 'av', 'for', 'med',
      'til', 'den', 'ikke', 'har', 'de', 'om', 'han', 'hun', 'jeg', 'du',
      'vi', 'dere', 'var', 'kan', 'fra', 'men', 'så', 'seg', 'også', 'eller',
      'hva', 'når', 'her', 'der', 'skulle', 'hadde', 'mye', 'noe', 'være',
    },
    'da_DK': {
      'og', 'i', 'det', 'er', 'en', 'et', 'som', 'på', 'af', 'for', 'med',
      'til', 'den', 'ikke', 'har', 'de', 'om', 'han', 'hun', 'jeg', 'du',
      'vi', 'var', 'kan', 'fra', 'men', 'så', 'sig', 'også', 'eller',
      'hvad', 'når', 'her', 'der', 'skulle', 'havde', 'meget', 'noget', 'at',
    },
    'tr_TR': {
      've', 'bir', 'bu', 'da', 'de', 'ile', 'için', 'ne', 'çok', 'daha',
      'ama', 'gibi', 'ben', 'sen', 'o', 'biz', 'siz', 'onlar', 'var', 'yok',
      'mi', 'mı', 'mu', 'mü', 'değil', 'kadar', 'sonra', 'her', 'şey',
      'olan', 'olarak', 'ki', 'en', 'ya', 'hem', 'ise', 'diye', 'şu',
    },
    'id_ID': {
      'dan', 'yang', 'di', 'ke', 'dari', 'untuk', 'dengan', 'ini', 'itu',
      'tidak', 'ada', 'adalah', 'saya', 'kamu', 'dia', 'kami', 'mereka',
      'akan', 'sudah', 'bisa', 'juga', 'pada', 'oleh', 'karena', 'tetapi',
      'atau', 'seperti', 'lebih', 'sangat', 'dalam', 'bahwa', 'sebagai',
    },
    'vi_VN': {
      'và', 'của', 'là', 'có', 'không', 'trong', 'được', 'một', 'này', 'cho',
      'với', 'những', 'các', 'người', 'tôi', 'anh', 'chị', 'em', 'họ',
      'đã', 'sẽ', 'đang', 'rất', 'cũng', 'như', 'nhưng', 'thì', 'để', 'khi',
      'về', 'từ', 'đến', 'ở', 'lại', 'ra', 'vào', 'nào', 'gì', 'đó',
    },
    'tl_PH': {
      'ang', 'ng', 'sa', 'na', 'at', 'ay', 'mga', 'ko', 'mo', 'siya', 'ako',
      'ikaw', 'kami', 'tayo', 'sila', 'ito', 'iyan', 'iyon', 'hindi', 'may',
      'para', 'kung', 'pero', 'dahil', 'niya', 'nila', 'natin', 'namin',
      'lang', 'din', 'rin', 'pa', 'ba', 'naman', 'kasi', 'wala', 'meron',
    },
  };

  static final _wordRegex = RegExp(r'\p{L}+', unicode: true);

  String detect(String text, {String? fallback}) {
    final fb = fallback ?? 'en_US';
    if (text.trim().isEmpty) return fb;

    for (final entry in _scripts.entries) {
      if (entry.key.hasMatch(text)) return entry.value;
    }

    final words = _wordRegex
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
    if (words.isEmpty) return fb;

    String? best;
    var bestScore = 0;
    for (final entry in _stopwords.entries) {
      var score = 0;
      for (final w in words) {
        if (entry.value.contains(w)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }
    if (best == null || bestScore == 0) return fb;
    // Mínimo de señal: 1 stopword por cada 15 palabras (y al menos 1).
    if (bestScore * 15 < words.length) return fb;
    return best;
  }
}
