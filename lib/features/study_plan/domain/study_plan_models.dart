import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';

class VocabularyNotebook {
  const VocabularyNotebook({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String description;
  final List<VocabularyNotebookWord> items;
  final bool isDefault;

  int get wordCount => items.length;

  List<String> get words =>
      items.map((item) => item.word).toList(growable: false);
}

class VocabularyNotebookWord {
  const VocabularyNotebookWord({required this.word, required this.addedAt});

  final String word;
  final DateTime addedAt;
}

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
    required this.notebooks,
    required this.selectedNotebookId,
    required this.newCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.remainingCount,
    required this.weekDays,
  });

  final OfficialVocabularyBook? currentBook;
  final List<OfficialVocabularyBook> myBooks;
  final List<VocabularyNotebook> notebooks;
  final String? selectedNotebookId;
  final int newCount;
  final int reviewCount;
  final int masteredCount;
  final int remainingCount;
  final List<StudyCalendarDay> weekDays;
}
