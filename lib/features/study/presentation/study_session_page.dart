import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/application/study_session_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/study/presentation/word_card_view.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class StudySessionPage extends StatelessWidget {
  const StudySessionPage({
    super.key,
    required this.controller,
    required this.wordDetailPageBuilder,
  });

  factory StudySessionPage.forBook({
    Key? key,
    required List<WordEntry> entries,
    required StudyRepository studyRepository,
    required FsrsRepository fsrsRepository,
    required WordKnowledgeRepository wordKnowledgeRepository,
    required WordDetailPageBuilder wordDetailPageBuilder,
    Map<String, StudyTaskSource> entrySourcesByWord =
        const <String, StudyTaskSource>{},
  }) {
    return StudySessionPage(
      key: key,
      controller: StudySessionController(
        entries: entries,
        studyRepository: studyRepository,
        fsrsRepository: fsrsRepository,
        wordKnowledgeRepository: wordKnowledgeRepository,
        entrySourcesByWord: entrySourcesByWord,
      ),
      wordDetailPageBuilder: wordDetailPageBuilder,
    );
  }

  final StudySessionController controller;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final entry = state.currentEntry;
        final taskSource = controller.currentTaskSource;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: SafeArea(
            child: entry == null
                ? _CompletedView(
                    forgotCount: state.forgotCount,
                    fuzzyCount: state.fuzzyCount,
                    knownCount: state.knownCount,
                    masteredCount: state.masteredCount,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.currentIndex}/${state.entries.length}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF7F8799),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const Spacer(),
                            const Icon(Icons.star_border_rounded, size: 34),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: controller.markMastered,
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('标记熟悉'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2F80ED),
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.more_vert_rounded, size: 34),
                          ],
                        ),
                        const SizedBox(height: 34),
                        if (taskSource != null) ...[
                          _TaskSourceBadge(source: taskSource),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          entry.word,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E8ED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '美 ${entry.pronunciation ?? ''}'.trim(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Expanded(
                          child: SingleChildScrollView(
                            child: WordCardView(
                              entry: entry,
                              definitionVisible: state.definitionRevealed,
                              onRevealDefinition: controller.revealDefinition,
                              onOpenDetail: () =>
                                  _openWordDetail(context, entry),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _DecisionButton(
                                    label: '忘记',
                                    color: const Color(0xFFFF4A3D),
                                    onTap: controller.markForgot,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DecisionButton(
                                    label: '模糊',
                                    color: const Color(0xFFFF8A00),
                                    onTap: controller.markFuzzy,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DecisionButton(
                                    label: '认识',
                                    color: const Color(0xFF10C28E),
                                    onTap: controller.markKnown,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _openWordDetail(BuildContext context, WordEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => wordDetailPageBuilder(entry.word, entry),
      ),
    );
  }
}

class _TaskSourceBadge extends StatelessWidget {
  const _TaskSourceBadge({required this.source});

  final StudyTaskSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = switch (source) {
      StudyTaskSource.newWord => (
        label: '新学',
        background: const Color(0xFFEAF2FF),
        foreground: const Color(0xFF2F80ED),
      ),
      StudyTaskSource.probeWord => (
        label: '抽查',
        background: const Color(0xFFF3E8FF),
        foreground: const Color(0xFF8E44AD),
      ),
      StudyTaskSource.mustReview || StudyTaskSource.normalReview => (
        label: '复习',
        background: const Color(0xFFFFF1E6),
        foreground: const Color(0xFFFF8A00),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF171D2D),
        minimumSize: const Size(double.infinity, 72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            width: 34,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({
    required this.forgotCount,
    required this.fuzzyCount,
    required this.knownCount,
    required this.masteredCount,
  });

  final int forgotCount;
  final int fuzzyCount;
  final int knownCount;
  final int masteredCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '本轮学习完成',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text('已掌握 $masteredCount 个'),
            const SizedBox(height: 8),
            Text('认识 $knownCount 个'),
            const SizedBox(height: 8),
            Text('模糊 $fuzzyCount 个'),
            const SizedBox(height: 8),
            Text('忘记 $forgotCount 个'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
