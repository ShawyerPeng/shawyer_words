import 'package:flutter/material.dart' hide SearchController;
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/presentation/search_entry_bar.dart';

enum SearchContentType { words, articles }

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.controller,
    required this.wordDetailPageBuilder,
  });

  final SearchController controller;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _textController;
  final FocusNode _inputFocusNode = FocusNode();
  SearchContentType _contentType = SearchContentType.words;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.text = widget.controller.state.query;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.prepareForOpen();
      if (!mounted) {
        return;
      }
      _textController.text = widget.controller.state.query;
      _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openEntry(WordEntry entry) async {
    await widget.controller.selectEntry(entry);
    _textController.clear();
    widget.controller.updateQuery('');
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.wordDetailPageBuilder(entry.word, entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            final showHistory =
                _contentType == SearchContentType.words &&
                state.query.trim().isEmpty;

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchEntryBar(
                    shellKey: const ValueKey('search-page-search-bar'),
                    controller: _textController,
                    focusNode: _inputFocusNode,
                    onChanged: (value) {
                      widget.controller.updateQuery(value);
                    },
                    trailing: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(40, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '取消',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      _SearchModeTab(
                        label: '单词',
                        selected: _contentType == SearchContentType.words,
                        onTap: () => setState(
                          () => _contentType = SearchContentType.words,
                        ),
                      ),
                      const SizedBox(width: 28),
                      _SearchModeTab(
                        label: '文章',
                        selected: _contentType == SearchContentType.articles,
                        onTap: () => setState(
                          () => _contentType = SearchContentType.articles,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  if (_contentType == SearchContentType.articles)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text(
                          '文章搜索稍后开放，当前先支持单词查询。',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF7C8699),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Text(
                          showHistory ? '历史查询' : '匹配结果',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (showHistory && state.history.isNotEmpty)
                          TextButton(
                            onPressed: widget.controller.clearHistory,
                            child: const Text('清除'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: showHistory
                          ? _WordList(
                              entries: state.history,
                              leadingBuilder: (_) => const Icon(
                                Icons.history_rounded,
                                color: Color(0xFFA0A7B7),
                                size: 20,
                              ),
                              onTap: _openEntry,
                            )
                          : _WordList(
                              entries: state.results,
                              leadingBuilder: (_) => const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFA0A7B7),
                                size: 20,
                              ),
                              onTap: _openEntry,
                              emptyText: '没有找到匹配的单词',
                            ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchModeTab extends StatelessWidget {
  const _SearchModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: selected
                  ? const Color(0xFF1B2030)
                  : const Color(0xFF9DA5B8),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            width: 56,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0BC58C) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordList extends StatelessWidget {
  const _WordList({
    required this.entries,
    required this.leadingBuilder,
    required this.onTap,
    this.emptyText,
  });

  final List<WordEntry> entries;
  final Widget Function(WordEntry entry) leadingBuilder;
  final Future<void> Function(WordEntry entry) onTap;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            emptyText ?? '暂无历史查询',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF98A0B3),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          onTap: () => onTap(entry),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
          minLeadingWidth: 20,
          horizontalTitleGap: 8,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 0,
          ),
          leading: leadingBuilder(entry),
          title: Text(
            entry.word,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          subtitle: Text(
            [
              if (entry.partOfSpeech != null && entry.partOfSpeech!.isNotEmpty)
                entry.partOfSpeech!,
              if (entry.definition != null && entry.definition!.isNotEmpty)
                entry.definition!,
            ].join('  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9AA2B4),
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}
