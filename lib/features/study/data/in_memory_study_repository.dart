import 'package:shawyer_words/features/study/domain/study_repository.dart';

class InMemoryStudyRepository implements StudyRepository {
  InMemoryStudyRepository() : decisions = <StudyDecisionRecord>[];

  final List<StudyDecisionRecord> decisions;

  @override
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  }) async {
    decisions.add(
      StudyDecisionRecord(
        entryId: entryId,
        decision: decision,
        recordedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<StudyDecisionRecord>> loadDecisionRecords() async {
    return List<StudyDecisionRecord>.unmodifiable(decisions);
  }
}
