import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class VocabularyWordListPage extends StatefulWidget {
  const VocabularyWordListPage({
    super.key,
    required this.book,
    required this.settingsController,
    required this.studyPlanController,
    required this.fsrsRepository,
    required this.wordKnowledgeRepository,
    required this.wordDetailPageBuilder,
  });

  final OfficialVocabularyBook book;
  final SettingsController settingsController;
  final StudyPlanController studyPlanController;
  final FsrsRepository fsrsRepository;
  final WordKnowledgeRepository wordKnowledgeRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  State<VocabularyWordListPage> createState() => _VocabularyWordListPageState();
}

enum _WordListDisplayMode { all, maskDefinition, maskWord }

class _VocabularyWordListPageState extends State<VocabularyWordListPage> {
  bool _loading = true;
  String? _errorMessage;
  Map<String, WordKnowledgeRecord> _knowledgeByWord =
      const <String, WordKnowledgeRecord>{};
  Map<String, FsrsCard> _cardsByWord = const <String, FsrsCard>{};
  bool _batchWorking = false;
  _WordListDisplayMode _displayMode = _WordListDisplayMode.all;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final bookWords = widget.book.entries
          .map((entry) => WordKnowledgeRecord.normalizeWord(entry.word))
          .toSet();
      final records = await widget.wordKnowledgeRepository.loadAll();
      final map = <String, WordKnowledgeRecord>{};
      for (final record in records) {
        if (bookWords.contains(record.word)) {
          map[record.word] = record;
        }
      }
      final cards = await widget.fsrsRepository.loadAll();
      final cardMap = <String, FsrsCard>{};
      for (final card in cards) {
        if (bookWords.contains(card.word)) {
          cardMap[card.word] = card;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _knowledgeByWord = Map<String, WordKnowledgeRecord>.unmodifiable(map);
        _cardsByWord = Map<String, FsrsCard>.unmodifiable(cardMap);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = <_WordListTab>[
      const _WordListTab(
        key: ValueKey('wordlist-today'),
        label: '今日任务',
        type: _WordListTabType.today,
      ),
      const _WordListTab(
        key: ValueKey('wordlist-learning'),
        label: '在学单词',
        type: _WordListTabType.learning,
      ),
      const _WordListTab(
        key: ValueKey('wordlist-unlearned'),
        label: '未学单词',
        type: _WordListTabType.unlearned,
      ),
      const _WordListTab(
        key: ValueKey('wordlist-easy'),
        label: '简单词',
        type: _WordListTabType.easy,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.settingsController,
        widget.studyPlanController,
      ]),
      builder: (context, _) {
        final settings = widget.settingsController.state.settings;
        final now = DateTime.now().toUtc();
        final computed = _computeLists(
          book: widget.book,
          settings: settings,
          knowledgeByWord: _knowledgeByWord,
          cardsByWord: _cardsByWord,
          now: now,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5FA),
          body: SafeArea(
            child: DefaultTabController(
              length: tabs.length,
              child: Builder(
                builder: (tabContext) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(tabContext).pop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '我的词表',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('wordlist-action-mark-known'),
                              tooltip: '标记掌握',
                              onPressed: _loading || _batchWorking
                                  ? null
                                  : () => _confirmMarkKnown(tabContext, computed),
                              icon: const Icon(
                                Icons.done_all_rounded,
                                color: Color(0xFF99A1B2),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('wordlist-action-add-notebook'),
                              tooltip: '加入生词本',
                              onPressed: _loading || _batchWorking
                                  ? null
                                  : () => _confirmAddToNotebook(tabContext, computed),
                              icon: const Icon(
                                Icons.playlist_add_rounded,
                                color: Color(0xFF99A1B2),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('wordlist-action-display'),
                              tooltip: '显示设置',
                              onPressed: _batchWorking
                                  ? null
                                  : () => _openDisplaySettings(tabContext),
                              icon: const Icon(
                                Icons.visibility_rounded,
                                color: Color(0xFF99A1B2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8B93A5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${widget.book.wordCount} 词',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF8B93A5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TabBar(
                        tabs: [
                          for (final tab in tabs)
                            Tab(key: tab.key, text: tab.label),
                        ],
                        labelColor: const Color(0xFF10C28E),
                        unselectedLabelColor: const Color(0xFF9AA2B2),
                        labelStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelStyle:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        indicatorColor: const Color(0xFF10C28E),
                        indicatorWeight: 3,
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : (_errorMessage != null
                                ? Center(child: Text(_errorMessage!))
                                : TabBarView(
                                    children: [
                                      _TodayTaskTab(
                                        computed: computed,
                                        onRefresh: _reload,
                                        onOpenWord: _openWord,
                                        displayMode: _displayMode,
                                      ),
                                      _WordEntryListTab(
                                        items: computed.learning,
                                        onRefresh: _reload,
                                        onOpenWord: _openWord,
                                        displayMode: _displayMode,
                                      ),
                                      _WordEntryListTab(
                                        items: computed.unlearned,
                                        onRefresh: _reload,
                                        onOpenWord: _openWord,
                                        displayMode: _displayMode,
                                      ),
                                      _WordEntryListTab(
                                        items: computed.easy,
                                        onRefresh: _reload,
                                        onOpenWord: _openWord,
                                        displayMode: _displayMode,
                                      ),
                                    ],
                                  )),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWord(WordEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.wordDetailPageBuilder(entry.word, entry),
      ),
    );
    if (mounted) {
      await _reload();
    }
  }

  List<WordEntry> _entriesForTab(_ComputedLists computed, int tabIndex) {
    return switch (tabIndex) {
      0 => <WordEntry>[...computed.todayNew, ...computed.todayReview],
      1 => computed.learning,
      2 => computed.unlearned,
      3 => computed.easy,
      _ => const <WordEntry>[],
    };
  }

  Future<void> _openDisplaySettings(BuildContext context) async {
    final selected = await showModalBottomSheet<_WordListDisplayMode>(
      context: context,
      backgroundColor: const Color(0xFFF7F8FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '显示设置',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<_WordListDisplayMode>(
                  title: const Text('全部显示'),
                  value: _WordListDisplayMode.all,
                  groupValue: _displayMode,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                RadioListTile<_WordListDisplayMode>(
                  title: const Text('遮挡释义'),
                  value: _WordListDisplayMode.maskDefinition,
                  groupValue: _displayMode,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                RadioListTile<_WordListDisplayMode>(
                  title: const Text('遮挡单词'),
                  value: _WordListDisplayMode.maskWord,
                  groupValue: _displayMode,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _displayMode = selected);
  }

  Future<void> _confirmMarkKnown(BuildContext context, _ComputedLists computed) async {
    final tabController = DefaultTabController.of(context);
    final tabIndex = tabController?.index ?? 0;
    final items = _entriesForTab(computed, tabIndex);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前列表暂无可操作单词')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批量标记掌握'),
          content: Text('将当前列表共 ${items.length} 个单词标记为已掌握？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _runBatch(
      context,
      message: '正在标记掌握...',
      task: () => _batchMarkKnown(items),
    );
  }

  Future<void> _confirmAddToNotebook(
    BuildContext context,
    _ComputedLists computed,
  ) async {
    final tabController = DefaultTabController.of(context);
    final tabIndex = tabController?.index ?? 0;
    final items = _entriesForTab(computed, tabIndex);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前列表暂无可操作单词')),
      );
      return;
    }

    final notebooks = widget.studyPlanController.state.notebooks;
    if (notebooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可用生词本')),
      );
      return;
    }
    final notebook = notebooks.firstWhere(
      (item) => item.isDefault,
      orElse: () => widget.studyPlanController.state.selectedNotebook!,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批量加入生词本'),
          content: Text('将当前列表共 ${items.length} 个单词加入「${notebook.name}」？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _runBatch(
      context,
      message: '正在加入生词本...',
      task: () async {
        final words = <String>{
          for (final entry in items) WordKnowledgeRecord.normalizeWord(entry.word),
        }.toList(growable: false);
        await widget.studyPlanController.importWordsToNotebook(
          notebookId: notebook.id,
          words: words,
        );
      },
    );
  }

  Future<void> _batchMarkKnown(List<WordEntry> items) async {
    for (final entry in items) {
      final normalized = WordKnowledgeRecord.normalizeWord(entry.word);
      final current = _knowledgeByWord[normalized];
      if (current?.isKnown ?? false) {
        continue;
      }
      await widget.wordKnowledgeRepository.markKnown(
        normalized,
        skipConfirmNextTime: false,
      );
    }
    await _reload();
  }

  Future<void> _runBatch(
    BuildContext context, {
    required String message,
    required Future<void> Function() task,
  }) async {
    if (!mounted) {
      return;
    }
    setState(() => _batchWorking = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
    try {
      await task();
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作完成')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _batchWorking = false);
      }
    }
  }
}

enum _WordListTabType { today, learning, unlearned, easy }

class _WordListTab {
  const _WordListTab({required this.key, required this.label, required this.type});

  final Key key;
  final String label;
  final _WordListTabType type;
}

class _ComputedLists {
  const _ComputedLists({
    required this.todayNew,
    required this.todayReview,
    required this.learning,
    required this.unlearned,
    required this.easy,
  });

  final List<WordEntry> todayNew;
  final List<WordEntry> todayReview;
  final List<WordEntry> learning;
  final List<WordEntry> unlearned;
  final List<WordEntry> easy;
}

_ComputedLists _computeLists({
  required OfficialVocabularyBook book,
  required AppSettings settings,
  required Map<String, WordKnowledgeRecord> knowledgeByWord,
  required Map<String, FsrsCard> cardsByWord,
  required DateTime now,
}) {
  final entries = book.entries;
  final normalizedWords = <String>[
    for (final entry in entries) WordKnowledgeRecord.normalizeWord(entry.word),
  ];
  final byWord = <String, WordEntry>{
    for (var i = 0; i < entries.length; i += 1) normalizedWords[i]: entries[i],
  };

  final easyKeys = <String>[];
  final masteredKeys = <String>{};
  for (final record in knowledgeByWord.values) {
    if (!byWord.containsKey(record.word)) {
      continue;
    }
    if (record.isKnown) {
      masteredKeys.add(record.word);
    }
    if (record.skipKnownConfirm) {
      easyKeys.add(record.word);
    }
  }

  easyKeys.sort((a, b) {
    final ar = knowledgeByWord[a];
    final br = knowledgeByWord[b];
    if (ar == null && br == null) {
      return 0;
    }
    if (ar == null) {
      return 1;
    }
    if (br == null) {
      return -1;
    }
    return br.updatedAt.compareTo(ar.updatedAt);
  });

  final easy = <WordEntry>[for (final key in easyKeys) byWord[key]!];

  final learningKeys = <String>[
    for (final key in cardsByWord.keys)
      if (byWord.containsKey(key) &&
          !easyKeys.contains(key) &&
          !masteredKeys.contains(key))
        key,
  ]..sort((a, b) {
    final ac = cardsByWord[a];
    final bc = cardsByWord[b];
    if (ac == null && bc == null) {
      return 0;
    }
    if (ac == null) {
      return 1;
    }
    if (bc == null) {
      return -1;
    }
    return ac.due.compareTo(bc.due);
  });

  final learning = <WordEntry>[for (final key in learningKeys) byWord[key]!];

  final unlearned = <WordEntry>[];
  for (var i = 0; i < entries.length; i += 1) {
    final key = normalizedWords[i];
    if (!cardsByWord.containsKey(key) &&
        !easyKeys.contains(key) &&
        !masteredKeys.contains(key)) {
      unlearned.add(entries[i]);
    }
  }

  final dailyNew = settings.dailyStudyTarget.clamp(1, 200);
  final dailyReview =
      (dailyNew * settings.dailyReviewLimitMultiplier).clamp(0, 2000);

  final todayNew = unlearned.take(dailyNew).toList(growable: false);
  final todayReview = <WordEntry>[
    for (final key in learningKeys)
      if (!(cardsByWord[key]?.due.isAfter(now) ?? true)) byWord[key]!,
  ].take(dailyReview).toList(growable: false);

  return _ComputedLists(
    todayNew: todayNew,
    todayReview: todayReview,
    learning: learning,
    unlearned: unlearned,
    easy: easy,
  );
}

class _TodayTaskTab extends StatelessWidget {
  const _TodayTaskTab({
    required this.computed,
    required this.onRefresh,
    required this.onOpenWord,
    required this.displayMode,
  });

  final _ComputedLists computed;
  final Future<void> Function() onRefresh;
  final Future<void> Function(WordEntry entry) onOpenWord;
  final _WordListDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    final items = <_TodayTaskRow>[
      if (computed.todayNew.isNotEmpty) const _TodayTaskRow.header('新词'),
      for (final entry in computed.todayNew) _TodayTaskRow.entry(entry),
      if (computed.todayReview.isNotEmpty) const _TodayTaskRow.header('复习词'),
      for (final entry in computed.todayReview) _TodayTaskRow.entry(entry),
    ];

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: const [
            SizedBox(height: 140),
            Center(
              child: Text(
                '今日任务已完成',
                style: TextStyle(color: Color(0xFF8D97A7), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        itemCount: items.length,
        separatorBuilder: (_, index) {
          final current = items[index];
          final next = index + 1 < items.length ? items[index + 1] : null;
          if (current.isHeader || (next?.isHeader ?? false)) {
            return const SizedBox(height: 10);
          }
          return const Divider(height: 1, color: Color(0xFFE8ECF2));
        },
        itemBuilder: (context, index) {
          final row = items[index];
          if (row.isHeader) {
            return _SectionHeader(label: row.headerLabel!);
          }
          return _WordListTile(
            entry: row.entry!,
            displayMode: displayMode,
            onTap: () => onOpenWord(row.entry!),
          );
        },
      ),
    );
  }
}

class _TodayTaskRow {
  const _TodayTaskRow._({this.headerLabel, this.entry});

  const _TodayTaskRow.header(String label) : this._(headerLabel: label);
  const _TodayTaskRow.entry(WordEntry entry) : this._(entry: entry);

  final String? headerLabel;
  final WordEntry? entry;

  bool get isHeader => headerLabel != null;
}

class _WordEntryListTab extends StatelessWidget {
  const _WordEntryListTab({
    required this.items,
    required this.onRefresh,
    required this.onOpenWord,
    required this.displayMode,
  });

  final List<WordEntry> items;
  final Future<void> Function() onRefresh;
  final Future<void> Function(WordEntry entry) onOpenWord;
  final _WordListDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: const [
            SizedBox(height: 140),
            Center(
              child: Text(
                '暂无数据',
                style: TextStyle(color: Color(0xFF8D97A7), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFE8ECF2)),
        itemBuilder: (context, index) {
          final entry = items[index];
          return _WordListTile(
            entry: entry,
            displayMode: displayMode,
            onTap: () => onOpenWord(entry),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: label == '新词' ? const Color(0xFFE8FBF3) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    label == '新词' ? const Color(0xFF10C28E) : const Color(0xFFFF8A00),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _WordListTile extends StatelessWidget {
  const _WordListTile({
    required this.entry,
    required this.displayMode,
    required this.onTap,
  });

  final WordEntry entry;
  final _WordListDisplayMode displayMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pronunciation = (entry.pronunciation ?? '').trim();
    final partOfSpeech = (entry.partOfSpeech ?? '').trim();
    final definition = (entry.definition ?? '').trim();
    final maskedWord = displayMode == _WordListDisplayMode.maskWord;
    final maskedDefinition = displayMode == _WordListDisplayMode.maskDefinition;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      maskedWord ? '•••' : entry.word,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (pronunciation.isNotEmpty)
                    Text(
                      pronunciation,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6F778A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (partOfSpeech.isNotEmpty)
                Text(
                  partOfSpeech,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8D97A7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (definition.isNotEmpty && !maskedDefinition)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    definition,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF1B2030),
                      height: 1.45,
                    ),
                  ),
                ),
              if (definition.isNotEmpty && maskedDefinition)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '•••',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF1B2030),
                      height: 1.45,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
