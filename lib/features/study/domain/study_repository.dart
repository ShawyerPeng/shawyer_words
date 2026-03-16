enum StudyDecisionType { known, unknown }

abstract class StudyRepository {
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  });
}
