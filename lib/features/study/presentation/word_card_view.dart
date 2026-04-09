import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class WordCardView extends StatelessWidget {
  const WordCardView({
    super.key,
    required this.entry,
    required this.onOpenDetail,
    this.onPlayExampleAudio,
  });

  final WordEntry entry;
  final VoidCallback onOpenDetail;
  final VoidCallback? onPlayExampleAudio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '释义',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8B93A1),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (_hasValue(entry.definition))
                Text(
                  entry.definition!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3436),
                  ),
                )
              else
                Text(
                  '该词条暂无内置释义',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF8A93A6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onOpenDetail,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF10C28E),
                ),
                child: const Text('查看完整释义'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F2),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '例句',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8A8D92),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2C14E),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '根据提示，判断释义',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB0B3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: onPlayExampleAudio,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 34,
                            color: onPlayExampleAudio == null
                                ? const Color(0xFFC8CDD5)
                                : const Color(0xFF15C38F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_hasValue(entry.exampleSentence))
                _ExampleSentenceText(
                  sentence: entry.exampleSentence!,
                  word: entry.word,
                )
              else
                Text(
                  entry.rawContent,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: const Color(0xFF3D4543),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _ExampleSentenceText extends StatelessWidget {
  const _ExampleSentenceText({required this.sentence, required this.word});

  final String sentence;
  final String word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = _buildHighlightedSpans(
      sentence: sentence,
      word: word,
      baseStyle: theme.textTheme.headlineSmall?.copyWith(
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3A433F),
      ),
      highlightStyle: theme.textTheme.headlineSmall?.copyWith(
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF33C8AE),
      ),
    );

    return RichText(text: TextSpan(children: spans));
  }

  List<InlineSpan> _buildHighlightedSpans({
    required String sentence,
    required String word,
    required TextStyle? baseStyle,
    required TextStyle? highlightStyle,
  }) {
    if (word.trim().isEmpty) {
      return <InlineSpan>[TextSpan(text: sentence, style: baseStyle)];
    }

    final escaped = RegExp.escape(word.trim());
    final pattern = RegExp(escaped, caseSensitive: false);
    final matches = pattern.allMatches(sentence).toList();
    if (matches.isEmpty) {
      return <InlineSpan>[TextSpan(text: sentence, style: baseStyle)];
    }

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: sentence.substring(start, match.start),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: sentence.substring(match.start, match.end),
          style: highlightStyle,
        ),
      );
      start = match.end;
    }
    if (start < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(start), style: baseStyle));
    }
    return spans;
  }
}
