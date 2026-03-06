/// Voice data model and catalog for ElevenLabs voice selection.
/// Each locale maps to 5 deep/warm voices with flag emoji and tagline.

class VoiceOption {
  final String name;
  final String voiceId;
  final String tagline;
  final String flagEmoji;

  const VoiceOption({
    required this.name,
    required this.voiceId,
    required this.tagline,
    required this.flagEmoji,
  });
}

/// Returns the default voice for a locale (first in the list).
String getDefaultVoiceId(String locale) {
  final voices = voicesByLocale[locale];
  if (voices != null && voices.isNotEmpty) {
    return voices.first.voiceId;
  }
  // Fallback to English Adam
  return 'pNInz6obpgDQGcFmaJgB';
}

/// Returns voice options for a given locale.
List<VoiceOption> getVoicesForLocale(String locale) {
  return voicesByLocale[locale] ?? voicesByLocale['en_US']!;
}

// ──────────────────────────────────────────────
// Voice catalog organized by locale
// ──────────────────────────────────────────────

const List<VoiceOption> _englishVoices = [
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Narración madura',
    flagEmoji: '🇺🇸',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🇺🇸',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • News presenter',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy & Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'Bill',
    voiceId: 'pqHfZKP75CvOlQylNhV4',
    tagline: 'Strong & Deep • Documentales',
    flagEmoji: '🇺🇸',
  ),
];

const List<VoiceOption> _spanishVoices = [
  VoiceOption(
    name: 'Voz Nueva 1',
    voiceId: '6xftrpatV0jGmFHxDjUv',
    tagline: 'Custom • Nueva voz añadida',
    flagEmoji: '🇪🇸',
  ),
  VoiceOption(
    name: 'Voz Nueva 2',
    voiceId: 'Nh2zY9kknu6z4pZy6FhD',
    tagline: 'Custom • Nueva voz añadida',
    flagEmoji: '🇪🇸',
  ),
  VoiceOption(
    name: 'Voz Nueva 3',
    voiceId: 'KHCvMklQZZo0O30ERnVn',
    tagline: 'Custom • Nueva voz añadida',
    flagEmoji: '🇪🇸',
  ),
  VoiceOption(
    name: 'Diego Aguado',
    voiceId: '5jTLciGr7JGMshpxjhek',
    tagline: 'Deep • Voz española profunda',
    flagEmoji: '🇪🇸',
  ),
  VoiceOption(
    name: 'Eleguar',
    voiceId: 'q2XMPZ6icuVDBj7rgCxQ',
    tagline: 'Deep • Latinoamericano inmersivo',
    flagEmoji: '🇲🇽',
  ),
  VoiceOption(
    name: 'Aaron',
    voiceId: 'SgWu1CbksCBEYr7fOUMP',
    tagline: 'Warm Baritone • Amigable',
    flagEmoji: '🇦🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración larga',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _frenchVoices = [
  VoiceOption(
    name: 'Eliott',
    voiceId: 'dY1Qa8xkWbp1fM5ny2Lo',
    tagline: 'Warm & Calm • Tono francés',
    flagEmoji: '🇫🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Acento refinado',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Timbre cálido',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _germanVoices = [
  VoiceOption(
    name: 'Stephan',
    voiceId: 'IWm8DnJ4NGjFI7QAM5lM',
    tagline: 'Warm & Friendly • Alemán nativo',
    flagEmoji: '🇩🇪',
  ),
  VoiceOption(
    name: 'Marcus KvE',
    voiceId: '6V1EWbNGUufEsfPFe5VA',
    tagline: 'Deep • Voice over profesional',
    flagEmoji: '🇩🇪',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a alemán',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _portugueseBRVoices = [
  VoiceOption(
    name: 'Márcio',
    voiceId: '29Pm0vQJJRoVfMCsUKB6',
    tagline: 'Deep • Storytelling solemne',
    flagEmoji: '🇧🇷',
  ),
  VoiceOption(
    name: 'Guilherme',
    voiceId: 'tlcdlAx9D2VUpCZ2etQ7',
    tagline: 'Deep • Dialogismo narrativo',
    flagEmoji: '🇧🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Acento refinado',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _portuguesePTVoices = [
  VoiceOption(
    name: 'Márcio',
    voiceId: '29Pm0vQJJRoVfMCsUKB6',
    tagline: 'Deep • Storytelling solemne',
    flagEmoji: '🇧🇷',
  ),
  VoiceOption(
    name: 'Guilherme',
    voiceId: 'tlcdlAx9D2VUpCZ2etQ7',
    tagline: 'Deep • Dialogismo narrativo',
    flagEmoji: '🇧🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Acento refinado',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _chineseVoices = [
  VoiceOption(
    name: 'Lazarus Liew',
    voiceId: 'Ixmp8zKRajBp10jLtsrq',
    tagline: 'Warm & Natural • Mandarín neutro',
    flagEmoji: '🇨🇳',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a chino',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _hindiVoices = [
  VoiceOption(
    name: 'Ranbir M',
    voiceId: 'yRis6UiS4dtT4Aqv72DC',
    tagline: 'Deep & Engaging • Hindi nativo',
    flagEmoji: '🇮🇳',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a hindi',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _indonesianVoices = [
  VoiceOption(
    name: 'Fathur',
    voiceId: '2k2NyISF1WNbjiJRa66a',
    tagline: 'Deep • Narración y noticias',
    flagEmoji: '🇮🇩',
  ),
  VoiceOption(
    name: 'Dany Saputra',
    voiceId: 'x5tvfc5X0Qh4cqmLpgrs',
    tagline: 'Warm • Narrativa fuerte',
    flagEmoji: '🇮🇩',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _russianVoices = [
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a ruso',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'Bill',
    voiceId: 'pqHfZKP75CvOlQylNhV4',
    tagline: 'Strong & Deep • Documentales',
    flagEmoji: '🇺🇸',
  ),
];

const List<VoiceOption> _arabicVoices = [
  VoiceOption(
    name: 'Haytham',
    voiceId: 'UR972wNGq3zluze0LoIp',
    tagline: 'Warm • Narración y podcasts',
    flagEmoji: '🇸🇦',
  ),
  VoiceOption(
    name: 'Haytham Conv.',
    voiceId: 'IES4nrmZdUBHByLBde0P',
    tagline: 'Warm & Energetic • Conversacional',
    flagEmoji: '🇸🇦',
  ),
  VoiceOption(
    name: 'Fares',
    voiceId: '5Spsi3mCH9e7futpnGE5',
    tagline: 'Gulf Arabic • Balanced & Warm',
    flagEmoji: '🇸🇦',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _vietnameseVoices = [
  VoiceOption(
    name: 'MinhTrung',
    voiceId: 'FTYCiQT21H9XQvhRu0ch',
    tagline: 'Deep & Warm • Vietnamita nativo',
    flagEmoji: '🇻🇳',
  ),
  VoiceOption(
    name: 'DangTungDuy',
    voiceId: '3VnrjnYrskPMDsapTr8X',
    tagline: 'Deep & Warm • Educación',
    flagEmoji: '🇻🇳',
  ),
  VoiceOption(
    name: 'Tran Kim Hung',
    voiceId: 'DXiwi9uoxet6zAiZXynP',
    tagline: 'Deep • Southern Vietnamese',
    flagEmoji: '🇻🇳',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _turkishVoices = [
  VoiceOption(
    name: 'Melih Karaoğlu',
    voiceId: 'NIqrB1HKNze8aX8Hyl35',
    tagline: 'Deep & Charismatic • Marketing',
    flagEmoji: '🇹🇷',
  ),
  VoiceOption(
    name: 'Düz Adam',
    voiceId: 'KUyRrVDjGxd32dlMuV24',
    tagline: 'Deep & Calm • Narrativa turca',
    flagEmoji: '🇹🇷',
  ),
  VoiceOption(
    name: 'Atay',
    voiceId: 'FhkeyHQl3JdGNNM9719E',
    tagline: 'Deep & Smooth • Susurro calmado',
    flagEmoji: '🇹🇷',
  ),
  VoiceOption(
    name: 'Daghan',
    voiceId: 'InTcBOYbBDjVPg15q0rr',
    tagline: 'Professional • Voz turca pro',
    flagEmoji: '🇹🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _tagalogVoices = [
  VoiceOption(
    name: 'Atomic Voice',
    voiceId: 'P1K0rMb2NHP150zt1hjo',
    tagline: 'Deep • Filipino narrator',
    flagEmoji: '🇵🇭',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a tagalog',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _dutchVoices = [
  VoiceOption(
    name: 'James',
    voiceId: 'G53Wkf3yrsXvhoQsmslL',
    tagline: 'Deep • Holandés nativo',
    flagEmoji: '🇳🇱',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Acento refinado',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _italianVoices = [
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a italiano',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'Bill',
    voiceId: 'pqHfZKP75CvOlQylNhV4',
    tagline: 'Strong & Deep • Documentales',
    flagEmoji: '🇺🇸',
  ),
];

const List<VoiceOption> _tamilVoices = [
  VoiceOption(
    name: 'Chakravarti',
    voiceId: 'QQi0BaxoWChvvX4kUPre',
    tagline: 'Warm • Voz tamil cálida',
    flagEmoji: '🇮🇳',
  ),
  VoiceOption(
    name: 'Adrishta',
    voiceId: 'ql6Gx6v8qU9oflZLdTsZ',
    tagline: 'Rich & Warm • Audiobooks',
    flagEmoji: '🇮🇳',
  ),
  VoiceOption(
    name: 'Ranbir M',
    voiceId: 'yRis6UiS4dtT4Aqv72DC',
    tagline: 'Deep & Engaging • India',
    flagEmoji: '🇮🇳',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _japaneseVoices = [
  VoiceOption(
    name: 'Koby',
    voiceId: '7V2labMjY8jnJlxDRW75',
    tagline: 'Deep & Husky • Narración madura',
    flagEmoji: '🇯🇵',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a japonés',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _koreanVoices = [
  VoiceOption(
    name: 'Taemin',
    voiceId: 'Ir7oQcBXWiq4oFGROCfj',
    tagline: 'Warm & Natural • Coreano claro',
    flagEmoji: '🇰🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a coreano',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _polishVoices = [
  VoiceOption(
    name: 'Karol',
    voiceId: 'XP3c7PKDwbCj3z2cnpa9',
    tagline: 'Deep & Soothing • Narración',
    flagEmoji: '🇵🇱',
  ),
  VoiceOption(
    name: 'Tomasz Zborek',
    voiceId: 'g8ZOdhoD9R6eYKPTjKbE',
    tagline: 'Deep & Clean • Voz limpia',
    flagEmoji: '🇵🇱',
  ),
  VoiceOption(
    name: 'Admundo PRO',
    voiceId: 'XoHJ8hwSLOtb2sXYdAzv',
    tagline: 'Deep & Pleasant • Versátil',
    flagEmoji: '🇵🇱',
  ),
  VoiceOption(
    name: 'Dominik Lektor',
    voiceId: 'gzP09k7BnuE4KBPrvBnk',
    tagline: 'Natural Warm • Tono medio-bajo',
    flagEmoji: '🇵🇱',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _swedishVoices = [
  VoiceOption(
    name: 'Tommy',
    voiceId: '6eknYWL7D5Z4nRkDy15t',
    tagline: 'Warm & Deep • Narrador sueco',
    flagEmoji: '🇸🇪',
  ),
  VoiceOption(
    name: 'Jonas',
    voiceId: 'Hyidyy6OA9R3GpDKGwoZ',
    tagline: 'Deep • Storytelling sueco',
    flagEmoji: '🇸🇪',
  ),
  VoiceOption(
    name: 'Max F.B.',
    voiceId: 'JhAQDwsLijg4qbxGNQGH',
    tagline: 'Deep & Low • Voz con carácter',
    flagEmoji: '🇸🇪',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
];

const List<VoiceOption> _norwegianVoices = [
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a noruego',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'Bill',
    voiceId: 'pqHfZKP75CvOlQylNhV4',
    tagline: 'Strong & Deep • Documentales',
    flagEmoji: '🇺🇸',
  ),
];

const List<VoiceOption> _danishVoices = [
  VoiceOption(
    name: 'Mathias',
    voiceId: 'ygiXC2Oa1BiHksD3WkJZ',
    tagline: 'Rich Baritone • Audiobooks',
    flagEmoji: '🇩🇰',
  ),
  VoiceOption(
    name: 'Thomas Hansen',
    voiceId: 'C43bq5qXRueL1cBQEOt3',
    tagline: 'Warm • Narración danesa',
    flagEmoji: '🇩🇰',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a danés',
    flagEmoji: '🇬🇧',
  ),
];

const List<VoiceOption> _greekVoices = [
  VoiceOption(
    name: 'Theos',
    voiceId: 'n0vzWypeCK1NlWPVwhOc',
    tagline: 'Assertive & Warm • TV y docs',
    flagEmoji: '🇬🇷',
  ),
  VoiceOption(
    name: 'Adam',
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    tagline: 'Deep • Multilingüe universal',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Brian',
    voiceId: 'nPczCjzI2devNBz1zQrb',
    tagline: 'Deep • Narración profunda',
    flagEmoji: '🌍',
  ),
  VoiceOption(
    name: 'Daniel',
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    tagline: 'Deep • Adaptable a griego',
    flagEmoji: '🇬🇧',
  ),
  VoiceOption(
    name: 'George',
    voiceId: 'JBFqnCBsd6RMkjVDRZzb',
    tagline: 'Raspy Warm • Storytelling',
    flagEmoji: '🇬🇧',
  ),
];

/// Master map: locale code → list of 5 voices
const Map<String, List<VoiceOption>> voicesByLocale = {
  'en_US': _englishVoices,
  'en_GB': _englishVoices,
  'es_ES': _spanishVoices,
  'es_AR': _spanishVoices,
  'es_MX': _spanishVoices,
  'es_CO': _spanishVoices,
  'fr_FR': _frenchVoices,
  'de_DE': _germanVoices,
  'pt_PT': _portuguesePTVoices,
  'pt_BR': _portugueseBRVoices,
  'zh_CN': _chineseVoices,
  'zh_TW': _chineseVoices,
  'hi_IN': _hindiVoices,
  'id_ID': _indonesianVoices,
  'ru_RU': _russianVoices,
  'ar_AR': _arabicVoices,
  'vi_VN': _vietnameseVoices,
  'tr_TR': _turkishVoices,
  'tl_PH': _tagalogVoices,
  'nl_NL': _dutchVoices,
  'it_IT': _italianVoices,
  'ta_IN': _tamilVoices,
  'ja_JP': _japaneseVoices,
  'ko_KR': _koreanVoices,
  'pl_PL': _polishVoices,
  'sv_SE': _swedishVoices,
  'no_NO': _norwegianVoices,
  'da_DK': _danishVoices,
  'el_GR': _greekVoices,
};

/// Flag emoji for each locale (used in UI header)
const Map<String, String> localeFlagEmoji = {
  'en_US': '🇺🇸',
  'en_GB': '🇬🇧',
  'es_ES': '🇪🇸',
  'es_AR': '🇦🇷',
  'es_MX': '🇲🇽',
  'es_CO': '🇨🇴',
  'fr_FR': '🇫🇷',
  'de_DE': '🇩🇪',
  'pt_PT': '🇵🇹',
  'pt_BR': '🇧🇷',
  'zh_CN': '🇨🇳',
  'zh_TW': '🇹🇼',
  'hi_IN': '🇮🇳',
  'id_ID': '🇮🇩',
  'ru_RU': '🇷🇺',
  'ar_AR': '🇸🇦',
  'vi_VN': '🇻🇳',
  'tr_TR': '🇹🇷',
  'tl_PH': '🇵🇭',
  'nl_NL': '🇳🇱',
  'it_IT': '🇮🇹',
  'ta_IN': '🇮🇳',
  'ja_JP': '🇯🇵',
  'ko_KR': '🇰🇷',
  'pl_PL': '🇵🇱',
  'sv_SE': '🇸🇪',
  'no_NO': '🇳🇴',
  'da_DK': '🇩🇰',
  'el_GR': '🇬🇷',
};

/// Short phrases for each locale used for 9-second voice previews.
const Map<String, String> localePreviewPhrases = {
  'en_US':
      'Welcome to Sapere. This is a preview of the voice you have selected. I hope you enjoy listening to our high-quality audio documentaries and learning something new today.',
  'en_GB':
      'Welcome to Sapere. This is a preview of the voice you have selected. I hope you enjoy listening to our high-quality audio documentaries and learning something new today.',
  'es_ES':
      'Bienvenido a Sapere. Esta es una muestra de la voz que has seleccionado. Espero que disfrutes escuchando nuestros audiodocumentales de alta calidad y aprendas algo nuevo hoy.',
  'es_MX':
      'Bienvenido a Sapere. Esta es una muestra de la voz que has seleccionado. Espero que disfrutes escuchando nuestros audiodocumentales de alta calidad y aprendas algo nuevo hoy.',
  'es_CO':
      'Bienvenido a Sapere. Esta es una muestra de la voz que has seleccionado. Espero que disfrutes escuchando nuestros audiodocumentales de alta calidad y aprendas algo nuevo hoy.',
  'es_AR':
      'Bienvenido a Sapere. Esta es una muestra de la voz que has seleccionado. Espero que disfrutes escuchando nuestros audiodocumentales de alta calidad y aprendas algo nuevo hoy.',
  'fr_FR':
      'Bienvenue chez Sapere. Voici un aperçu de la voix que vous avez sélectionnée. J\'espère que vous apprécierez l\'écoute de nos documentaires audio de haute qualité.',
  'de_DE':
      'Willkommen bei Sapere. Dies ist eine Vorschau der von Ihnen ausgewählten Stimme. Ich hoffe, es gefällt Ihnen, unsere hochwertigen Audiodokumentationen zu hören.',
  'it_IT':
      'Benvenuti in Sapere. Questa è un\'anteprima della voce che hai selezionato. Spero che ti piaccia ascoltare i nostri documentari audio di alta qualità oggi.',
  'pt_PT':
      'Bem-vindo ao Sapere. Esta é uma prévia da voz que você selecionou. Espero que goste de ouvir os nossos documentários em áudio de alta qualidade e aprenda algo novo.',
  'pt_BR':
      'Bem-vindo ao Sapere. Esta é uma prévia da voz que você selecionou. Espero que goste de ouvir os nossos documentários em áudio de alta qualidade e aprenda algo novo.',
  'ru_RU':
      'Добро пожаловать в Сапэре. Это предварительный просмотр выбранного вами голоса. Надеюсь, вам понравится слушать наши качественные аудиодокументальные фильмы.',
  'zh_CN': '欢迎来到 Sapere。这是您选择的操作预览。我希望您今天喜欢收听我们的高质量音频纪录片并学到一些新东西。',
  'ja_JP':
      'サペレへようこそ。これは選択した音声のプレビューです。当社の高品質なオーディオドキュメンタリーを楽しんで、今日何か新しいことを学んでいただければ幸いです。',
  'ko_KR':
      '사페레에 오신 것을 환영합니다. 선택하신 음성의 미리보기입니다. 저희의 고품질 오디오 다큐멘터리를 즐겁게 감상하시고 오늘 새로운 것을 배워보시기 바랍니다.',
  'hi_IN':
      'Sapere में आपका स्वागत है। यह आपके द्वारा चुनी गई आवाज़ का पूर्वावलोकन है। मुझे आशा है कि आप हमारे वृत्तचित्रों को सुनने का आनंद लेंगे।',
  'tr_TR':
      'Sapere\'ye hoş geldiniz. Bu seçtiğiniz sesin bir önizlemesidir. Umarım yüksek kaliteli sesli belgesellerimizi dinlemekten keyif alırsınız.',
  'nl_NL':
      'Welkom bij Sapere. Dit is een voorbeeld van de stem die je hebt geselecteerd. Ik hoop dat je geniet van het luisteren naar onze hoogwaardige audiodocumentaires.',
};
