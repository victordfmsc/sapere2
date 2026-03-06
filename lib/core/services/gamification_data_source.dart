import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:sapere/models/gamification_models.dart';

class GamificationDataSource {
  static Future<List<GamifiedSubject>> loadSubjectsFromCSV() async {
    try {
      final locale = Get.locale?.toString() ?? 'es_ES';
      String filePath =
          'assets/csv/cadenas_aprendizaje_30_materias_$locale.csv';

      String rawData;
      try {
        rawData = await rootBundle.loadString(filePath);
      } catch (e) {
        print('Localized CSV not found for $locale, falling back to es_ES');
        rawData = await rootBundle.loadString(
          'assets/csv/cadenas_aprendizaje_30_materias_es_ES.csv',
        );
      }

      List<List<dynamic>> listData = const CsvToListConverter().convert(
        rawData,
        fieldDelimiter: ',',
      );

      // Remove header
      if (listData.isNotEmpty) {
        listData.removeAt(0);
      }

      Map<String, GamifiedSubject> subjectsMap = {};

      for (var row in listData) {
        if (row.length >= 9) {
          String category = row[0].toString();
          String subjectNameWithIcon = row[1].toString();
          String icon = row[2].toString();
          int episodeNumber = int.tryParse(row[3].toString()) ?? 0;
          String level = row[4].toString();
          String title = row[5].toString();
          String description = row[6].toString();
          int xpBase = int.tryParse(row[7].toString()) ?? 0;
          String badge = row[8].toString();

          String subjectName = subjectNameWithIcon.replaceAll(icon, '').trim();

          GamifiedEpisode episode = GamifiedEpisode(
            episodeNumber: episodeNumber,
            level: level,
            title: title,
            description: description,
            xpBase: xpBase,
            badgeOnCompletion: badge.isNotEmpty ? badge : null,
          );

          if (subjectsMap.containsKey(subjectName)) {
            subjectsMap[subjectName]!.episodes.add(episode);
          } else {
            subjectsMap[subjectName] = GamifiedSubject(
              category: category,
              name: subjectName,
              icon: icon,
              episodes: [episode],
            );
          }
        }
      }

      return subjectsMap.values.toList();
    } catch (e) {
      print('Error parsing gamification CSV: $e');
      return [];
    }
  }

  // Helper method to group subjects by category
  static Map<String, List<GamifiedSubject>> groupByCategory(
    List<GamifiedSubject> subjects,
  ) {
    Map<String, List<GamifiedSubject>> categorized = {};
    for (var subject in subjects) {
      if (categorized.containsKey(subject.category)) {
        categorized[subject.category]!.add(subject);
      } else {
        categorized[subject.category] = [subject];
      }
    }
    return categorized;
  }
}
