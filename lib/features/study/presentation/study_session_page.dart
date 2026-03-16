import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/application/study_session_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/word_card_view.dart';

class StudySessionPage extends StatelessWidget {
  const StudySessionPage({super.key, required this.controller});

  factory StudySessionPage.forBook({
    Key? key,
    required List<WordEntry> entries,
    required StudyRepository studyRepository,
  }) {
    return StudySessionPage(
      key: key,
      controller: StudySessionController(
        entries: entries,
        studyRepository: studyRepository,
      ),
    );
  }

  final StudySessionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final entry = state.currentEntry;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: SafeArea(
            child: entry == null
                ? _CompletedView(
                    knownCount: state.knownCount,
                    unknownCount: state.unknownCount,
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
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 34,
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.more_vert_rounded, size: 34),
                          ],
                        ),
                        const SizedBox(height: 34),
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _DecisionButton(
                                label: '不认识',
                                color: const Color(0xFFFF4A3D),
                                onTap: controller.markUnknown,
                              ),
                            ),
                            const SizedBox(width: 18),
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
                  ),
          ),
        );
      },
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
        minimumSize: const Size(double.infinity, 78),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
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
  const _CompletedView({required this.knownCount, required this.unknownCount});

  final int knownCount;
  final int unknownCount;

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
            Text('认识 $knownCount 个，不认识 $unknownCount 个'),
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
