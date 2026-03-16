import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';

class StudyCalendarDay {
  const StudyCalendarDay({
    required this.weekdayLabel,
    required this.dayOfMonth,
    this.isToday = false,
  });

  final String weekdayLabel;
  final int dayOfMonth;
  final bool isToday;
}

class StudyPlanOverview {
  const StudyPlanOverview({
    required this.currentBook,
    required this.myBooks,
    required this.newCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.remainingCount,
    required this.weekDays,
  });

  final OfficialVocabularyBook? currentBook;
  final List<OfficialVocabularyBook> myBooks;
  final int newCount;
  final int reviewCount;
  final int masteredCount;
  final int remainingCount;
  final List<StudyCalendarDay> weekDays;
}
