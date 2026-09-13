import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class SfxEffect {
  final String id;

  /// idioma (es/en/fr/de/pt/it) → palabras clave en minúsculas.
  final Map<String, List<String>> keywords;

  const SfxEffect({required this.id, required this.keywords});

  String get asset => 'assets/audio/sfx/$id.mp3';
}

const List<SfxEffect> sfxCatalog = [
  SfxEffect(id: 'thunder', keywords: {
    'es': ['trueno', 'truenos', 'relámpago', 'rayo'],
    'en': ['thunder', 'lightning', 'thunderclap'],
    'fr': ['tonnerre', 'foudre', 'éclair'],
    'de': ['donner', 'blitz'],
    'pt': ['trovão', 'trovoada', 'relâmpago', 'raio'],
    'it': ['tuono', 'fulmine', 'lampo'],
  }),
  SfxEffect(id: 'rain', keywords: {
    'es': ['lluvia', 'llovía', 'lloviendo', 'chubasco'],
    'en': ['rain', 'raining', 'drizzle', 'downpour'],
    'fr': ['pluie', 'pleuvait', 'averse'],
    'de': ['regen', 'regnete', 'schauer'],
    'pt': ['chuva', 'chovia', 'aguaceiro'],
    'it': ['pioggia', 'pioveva', 'acquazzone'],
  }),
  SfxEffect(id: 'wind', keywords: {
    'es': ['viento', 'ventisca', 'ráfaga', 'brisa'],
    'en': ['wind', 'gust', 'breeze', 'gale'],
    'fr': ['vent', 'rafale', 'brise'],
    'de': ['wind', 'böe', 'brise', 'sturmwind'],
    'pt': ['vento', 'rajada', 'brisa'],
    'it': ['vento', 'raffica', 'brezza'],
  }),
  SfxEffect(id: 'footsteps', keywords: {
    'es': ['pasos', 'pisadas', 'caminaba', 'caminando'],
    'en': ['footsteps', 'footstep', 'walked', 'walking', 'steps'],
    'fr': ['pas', 'marchait', 'marchant'],
    'de': ['schritte', 'schritt', 'ging', 'gehend'],
    'pt': ['passos', 'pisadas', 'caminhava', 'andando'],
    'it': ['passi', 'camminava', 'camminando'],
  }),
  SfxEffect(id: 'door', keywords: {
    'es': ['puerta', 'portazo', 'portón'],
    'en': ['door', 'doorway', 'slammed'],
    'fr': ['porte', 'portail'],
    'de': ['tür', 'türe', 'tor'],
    'pt': ['porta', 'portão'],
    'it': ['porta', 'portone'],
  }),
  SfxEffect(id: 'sword', keywords: {
    'es': ['espada', 'espadas', 'sable', 'acero'],
    'en': ['sword', 'swords', 'blade', 'sabre', 'saber'],
    'fr': ['épée', 'épées', 'lame', 'sabre'],
    'de': ['schwert', 'schwerter', 'klinge', 'säbel'],
    'pt': ['espada', 'espadas', 'lâmina', 'sabre'],
    'it': ['spada', 'spade', 'lama', 'sciabola'],
  }),
  SfxEffect(id: 'fire', keywords: {
    'es': ['fuego', 'llamas', 'hoguera', 'chimenea', 'incendio'],
    'en': ['fire', 'flames', 'bonfire', 'fireplace', 'blaze'],
    'fr': ['feu', 'flammes', 'cheminée', 'incendie'],
    'de': ['feuer', 'flammen', 'kamin', 'brand'],
    'pt': ['fogo', 'chamas', 'fogueira', 'lareira', 'incêndio'],
    'it': ['fuoco', 'fiamme', 'falò', 'camino', 'incendio'],
  }),
  SfxEffect(id: 'water', keywords: {
    'es': ['agua', 'río', 'arroyo', 'cascada', 'chapoteo'],
    'en': ['water', 'river', 'stream', 'waterfall', 'splash'],
    'fr': ['eau', 'rivière', 'ruisseau', 'cascade'],
    'de': ['wasser', 'fluss', 'bach', 'wasserfall'],
    'pt': ['água', 'rio', 'riacho', 'cascata'],
    'it': ['acqua', 'fiume', 'ruscello', 'cascata'],
  }),
  SfxEffect(id: 'bell', keywords: {
    'es': ['campana', 'campanas', 'campanario', 'campanilla'],
    'en': ['bell', 'bells', 'chime', 'toll'],
    'fr': ['cloche', 'cloches', 'clochette', 'carillon'],
    'de': ['glocke', 'glocken', 'glöckchen'],
    'pt': ['sino', 'sinos', 'campainha'],
    'it': ['campana', 'campane', 'campanello'],
  }),
  SfxEffect(id: 'crowd', keywords: {
    'es': ['multitud', 'muchedumbre', 'gentío', 'público'],
    'en': ['crowd', 'mob', 'throng', 'audience'],
    'fr': ['foule', 'multitude', 'public'],
    'de': ['menge', 'menschenmenge', 'publikum'],
    'pt': ['multidão', 'público', 'gente'],
    'it': ['folla', 'moltitudine', 'pubblico'],
  }),
  SfxEffect(id: 'horse', keywords: {
    'es': ['caballo', 'caballos', 'galope', 'cascos', 'yegua'],
    'en': ['horse', 'horses', 'gallop', 'hooves', 'mare'],
    'fr': ['cheval', 'chevaux', 'galop', 'sabots'],
    'de': ['pferd', 'pferde', 'galopp', 'hufe'],
    'pt': ['cavalo', 'cavalos', 'galope', 'cascos'],
    'it': ['cavallo', 'cavalli', 'galoppo', 'zoccoli'],
  }),
  SfxEffect(id: 'gunshot', keywords: {
    'es': ['disparo', 'disparos', 'pistola', 'escopeta', 'balazo'],
    'en': ['gunshot', 'gunshots', 'shot', 'pistol', 'rifle', 'gunfire'],
    'fr': ['coup de feu', 'tir', 'pistolet', 'fusil'],
    'de': ['schuss', 'schüsse', 'pistole', 'gewehr'],
    'pt': ['disparo', 'tiro', 'pistola', 'espingarda'],
    'it': ['sparo', 'spari', 'pistola', 'fucile'],
  }),
  SfxEffect(id: 'birds', keywords: {
    'es': ['pájaros', 'pájaro', 'aves', 'gorjeo', 'trino'],
    'en': ['birds', 'bird', 'chirping', 'birdsong'],
    'fr': ['oiseaux', 'oiseau', 'gazouillis'],
    'de': ['vögel', 'vogel', 'gezwitscher'],
    'pt': ['pássaros', 'pássaro', 'aves', 'gorjeio'],
    'it': ['uccelli', 'uccello', 'cinguettio'],
  }),
  SfxEffect(id: 'laugh', keywords: {
    'es': ['risa', 'risas', 'carcajada', 'reía', 'rió'],
    'en': ['laugh', 'laughter', 'laughed', 'giggle', 'chuckle'],
    'fr': ['rire', 'rires', 'éclat de rire', 'riait'],
    'de': ['lachen', 'gelächter', 'lachte'],
    'pt': ['riso', 'risada', 'gargalhada', 'riu'],
    'it': ['risata', 'risate', 'rideva', 'rise'],
  }),
  SfxEffect(id: 'heartbeat', keywords: {
    'es': ['corazón', 'latido', 'latidos', 'palpitaba'],
    'en': ['heart', 'heartbeat', 'pounding', 'pulse'],
    'fr': ['cœur', 'battement', 'battements'],
    'de': ['herz', 'herzschlag', 'pochte'],
    'pt': ['coração', 'batida', 'batimento'],
    'it': ['cuore', 'battito', 'battiti'],
  }),
  SfxEffect(id: 'clock', keywords: {
    'es': ['reloj', 'tictac', 'péndulo', 'campanadas'],
    'en': ['clock', 'ticking', 'tick', 'pendulum'],
    'fr': ['horloge', 'pendule', 'tic-tac'],
    'de': ['uhr', 'ticken', 'pendel'],
    'pt': ['relógio', 'tique-taque', 'pêndulo'],
    'it': ['orologio', 'ticchettio', 'pendolo'],
  }),
  SfxEffect(id: 'train', keywords: {
    'es': ['tren', 'locomotora', 'vagón', 'vías'],
    'en': ['train', 'locomotive', 'railway', 'wagon'],
    'fr': ['train', 'locomotive', 'wagon'],
    'de': ['zug', 'lokomotive', 'waggon', 'bahn'],
    'pt': ['trem', 'comboio', 'locomotiva', 'vagão'],
    'it': ['treno', 'locomotiva', 'vagone'],
  }),
  SfxEffect(id: 'car', keywords: {
    'es': ['coche', 'automóvil', 'motor', 'carretera', 'auto'],
    'en': ['car', 'engine', 'highway', 'automobile'],
    'fr': ['voiture', 'moteur', 'autoroute'],
    'de': ['auto', 'wagen', 'motor', 'autobahn'],
    'pt': ['carro', 'automóvel', 'motor', 'estrada'],
    'it': ['auto', 'macchina', 'motore', 'autostrada'],
  }),
  SfxEffect(id: 'wolf', keywords: {
    'es': ['lobo', 'lobos', 'aullido', 'aullaba'],
    'en': ['wolf', 'wolves', 'howl', 'howling'],
    'fr': ['loup', 'loups', 'hurlement'],
    'de': ['wolf', 'wölfe', 'heulen'],
    'pt': ['lobo', 'lobos', 'uivo'],
    'it': ['lupo', 'lupi', 'ululato'],
  }),
  SfxEffect(id: 'sea', keywords: {
    'es': ['mar', 'océano', 'olas', 'marea', 'oleaje'],
    'en': ['sea', 'ocean', 'waves', 'tide', 'surf'],
    'fr': ['mer', 'océan', 'vagues', 'marée'],
    'de': ['meer', 'ozean', 'wellen', 'brandung'],
    'pt': ['mar', 'oceano', 'ondas', 'maré'],
    'it': ['mare', 'oceano', 'onde', 'marea'],
  }),
];

/// Detecta efectos de sonido por palabras clave y los reproduce solo si el
/// asset existe en el bundle (hoy no hay ficheros en assets/audio/sfx/).
class SfxKeywordService {
  final List<SfxEffect> catalog;
  Set<String>? _existingAssets;
  AudioPlayer? _player;

  SfxKeywordService({this.catalog = sfxCatalog});

  static final _wordRegex = RegExp(r'\p{L}+', unicode: true);

  /// True si al menos un asset del catálogo está en el bundle.
  /// Solo es fiable tras [loadAssetIndex].
  bool get hasAssets => _existingAssets?.isNotEmpty ?? false;

  List<String> detect(String sentence, String languageCode) {
    if (sentence.trim().isEmpty) return const [];
    final lang = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    final lower = sentence.toLowerCase();
    final words = _wordRegex.allMatches(lower).map((m) => m.group(0)!).toSet();
    final found = <String>[];
    for (final fx in catalog) {
      final list = fx.keywords[lang] ?? fx.keywords['en'] ?? const [];
      for (final k in list) {
        final hit = k.contains(' ') ? lower.contains(k) : words.contains(k);
        if (hit) {
          found.add(fx.id);
          break;
        }
      }
    }
    return found;
  }

  Future<void> loadAssetIndex() async {
    if (_existingAssets != null) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final all = manifest.listAssets().toSet();
      _existingAssets = catalog.map((e) => e.asset).where(all.contains).toSet();
    } catch (e) {
      debugPrint('[SfxKeywordService] AssetManifest failed: $e');
      _existingAssets = {};
    }
  }

  Future<void> playForSentence(String sentence, String languageCode,
      {double volume = 0.8}) async {
    final ids = detect(sentence, languageCode);
    if (ids.isEmpty) return;
    await playEffect(ids.first, volume: volume);
  }

  Future<void> playEffect(String id, {double volume = 0.8}) async {
    await loadAssetIndex();
    final asset = 'assets/audio/sfx/$id.mp3';
    if (!(_existingAssets?.contains(asset) ?? false)) return;
    try {
      final player = _player ??= AudioPlayer(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
      );
      await player.stop();
      await player.setAudioSource(AudioSource.asset(asset));
      await player.setVolume(volume.clamp(0.0, 1.0));
      player.play();
    } catch (e) {
      debugPrint('[SfxKeywordService] play failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (e) {
      debugPrint('[SfxKeywordService] dispose failed: $e');
    }
    _player = null;
  }
}
