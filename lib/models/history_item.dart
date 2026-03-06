class HistoryItem {
  final String id;
  final String title;
  final String coverUrl;
  final String type; // 'audio' or 'text'
  final int positionMs;
  final int totalDurationMs;
  final double scrollOffset;
  final DateTime lastAccessed;

  HistoryItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.type,
    this.positionMs = 0,
    this.totalDurationMs = 0,
    this.scrollOffset = 0.0,
    required this.lastAccessed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'type': type,
      'positionMs': positionMs,
      'totalDurationMs': totalDurationMs,
      'scrollOffset': scrollOffset,
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      type: map['type'] ?? 'audio',
      positionMs: map['positionMs'] ?? 0,
      totalDurationMs: map['totalDurationMs'] ?? 0,
      scrollOffset: (map['scrollOffset'] ?? 0.0).toDouble(),
      lastAccessed:
          map['lastAccessed'] != null
              ? DateTime.parse(map['lastAccessed'])
              : DateTime.now(),
    );
  }
}
