enum StudyDecisionType { forgot, fuzzy, known, mastered }

class StudyDecisionRecord {
  const StudyDecisionRecord({
    required this.entryId,
    required this.decision,
    required this.recordedAt,
  });

  final String entryId;
  final StudyDecisionType decision;
  final DateTime recordedAt;
}

abstract class StudyRepository {
  Future<void> saveDecision({
    required String entryId,
    required StudyDecisionType decision,
  });

  Future<List<StudyDecisionRecord>> loadDecisionRecords() async {
    return const <StudyDecisionRecord>[];
  }
}
