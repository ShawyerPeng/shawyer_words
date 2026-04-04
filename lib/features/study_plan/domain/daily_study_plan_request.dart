import 'package:flutter/foundation.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';

@immutable
class DailyStudyPlanRequest {
  const DailyStudyPlanRequest({
    required this.book,
    required this.bookEntries,
    required this.cardsByWord,
    required this.knowledgeByWord,
    required this.settings,
    required this.now,
  });

  final OfficialVocabularyBook book;
  final List<WordEntry> bookEntries;
  final Map<String, FsrsCard> cardsByWord;
  final Map<String, WordKnowledgeRecord> knowledgeByWord;
  final AppSettings settings;
  final DateTime now;
}
