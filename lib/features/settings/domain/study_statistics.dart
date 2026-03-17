class HeatmapDay {
  const HeatmapDay({required this.date, required this.count});

  final DateTime date;
  final int count;
}

class MonthlyVocabularyPoint {
  const MonthlyVocabularyPoint({required this.label, required this.totalWords});

  final String label;
  final int totalWords;
}

class DailyTrendPoint {
  const DailyTrendPoint({
    required this.label,
    required this.newWords,
    required this.reviewWords,
  });

  final String label;
  final int newWords;
  final int reviewWords;
}

class StudyStatistics {
  const StudyStatistics({
    required this.heatmapDays,
    required this.vocabularyGrowth,
    required this.everydayTrend,
  });

  final List<HeatmapDay> heatmapDays;
  final List<MonthlyVocabularyPoint> vocabularyGrowth;
  final List<DailyTrendPoint> everydayTrend;
}
