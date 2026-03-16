import 'package:shawyer_words/features/study/domain/study_repository.dart';

class InMemoryStudyRepository implements StudyRepository {
  InMemoryStudyRepository() : decisions = <StudyDecisionRecord>[];

  final List<StudyDecisionRecord> decisions;

  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {
    decisions.add(StudyDecisionRecord(entryId: entryId, decision: decision));
  }
}

class StudyDecisionRecord {
  const StudyDecisionRecord({
    required this.entryId,
    required this.decision,
  });

  final String entryId;
  final StudyDecisionType decision;
}
