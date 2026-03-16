import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class WordCardView extends StatelessWidget {
  const WordCardView({
    super.key,
    required this.entry,
    this.onTap,
  });

  final WordEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.word, style: theme.textTheme.headlineMedium),
              if (_hasValue(entry.pronunciation)) ...[
                const SizedBox(height: 8),
                Text(
                  entry.pronunciation!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (_hasValue(entry.partOfSpeech)) ...[
                const SizedBox(height: 16),
                _SectionLabel(label: entry.partOfSpeech!),
              ],
              if (_hasValue(entry.definition)) ...[
                const SizedBox(height: 12),
                Text(entry.definition!, style: theme.textTheme.bodyLarge),
              ],
              if (_hasValue(entry.exampleSentence)) ...[
                const SizedBox(height: 16),
                Text(
                  entry.exampleSentence!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (!_hasValue(entry.definition) && !_hasValue(entry.exampleSentence))
                ...[
                  const SizedBox(height: 16),
                  Text(entry.rawContent, style: theme.textTheme.bodyMedium),
                ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
