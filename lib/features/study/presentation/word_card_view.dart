import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class WordCardView extends StatelessWidget {
  const WordCardView({
    super.key,
    required this.entry,
    required this.definitionVisible,
    required this.onRevealDefinition,
    required this.onOpenDetail,
  });

  final WordEntry entry;
  final bool definitionVisible;
  final VoidCallback onRevealDefinition;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: definitionVisible ? null : onRevealDefinition,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '释义',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 26),
                if (definitionVisible && _hasValue(entry.definition))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.definition!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: onOpenDetail,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: const Color(0xFF10C28E),
                        ),
                        child: const Text('查看完整释义'),
                      ),
                    ],
                  )
                else if (definitionVisible)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '该词条暂无内置释义',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF8A93A6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onOpenDetail,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: const Color(0xFF10C28E),
                        ),
                        child: const Text('查看完整释义'),
                      ),
                    ],
                  )
                else
                  const _MaskedDefinitionLines(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '例句',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              if (_hasValue(entry.exampleSentence))
                Text(
                  entry.exampleSentence!,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.45),
                )
              else
                Text(entry.rawContent, style: theme.textTheme.bodyLarge),
              if (_hasValue(entry.partOfSpeech)) ...[
                const SizedBox(height: 26),
                Text(
                  entry.partOfSpeech!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF9EA6B7),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              const _PageIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _MaskedDefinitionLines extends StatelessWidget {
  const _MaskedDefinitionLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFF4F4F4), Color(0xFFF8F8F8), Color(0xFFF4F4F4)],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 44,
          width: 290,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFF4F4F4), Color(0xFFF8F8F8), Color(0xFFF4F4F4)],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(6, (index) {
        final active = index == 0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF10C28E) : const Color(0xFFE5E8EE),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
