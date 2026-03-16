import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class WordDetailPage extends StatelessWidget {
  const WordDetailPage({
    super.key,
    required this.entry,
  });

  final WordEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: const SizedBox(
                  height: 56,
                  width: 56,
                  child: BackButton(),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140A1633),
                      blurRadius: 32,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.word,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (_hasValue(entry.pronunciation))
                          _MetaChip(label: entry.pronunciation!),
                        if (_hasValue(entry.partOfSpeech))
                          _MetaChip(label: entry.partOfSpeech!),
                      ],
                    ),
                  ],
                ),
              ),
              if (_hasValue(entry.definition))
                _DetailSection(
                  title: '释义',
                  content: entry.definition!,
                ),
              if (_hasValue(entry.exampleSentence))
                _DetailSection(
                  title: '例句',
                  content: entry.exampleSentence!,
                  italic: true,
                ),
              _DetailSection(
                title: 'Raw dictionary content',
                content: entry.rawContent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FBF5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.content,
    this.italic = false,
  });

  final String title;
  final String content;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                color: const Color(0xFF3E4658),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
