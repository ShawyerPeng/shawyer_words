import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/presentation/study_plan_settings_page.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/study_session_page.dart';
import 'package:shawyer_words/features/study_plan/application/daily_task_planner.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/daily_study_plan.dart';
import 'package:shawyer_words/features/study_plan/domain/daily_study_plan_request.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_book_picker_page.dart';
import 'package:shawyer_words/features/study_plan/presentation/study_task_settings_page.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_wordlist_page.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_models.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

enum _NotebookAction { edit, delete }

class StudyHomePage extends StatefulWidget {
  const StudyHomePage({
    super.key,
    required this.controller,
    required this.settingsController,
    required this.wordKnowledgeRepository,
    required this.fsrsRepository,
    required this.studyRepository,
    required this.wordDetailPageBuilder,
    this.dailyTaskPlanner = const DailyTaskPlanner(),
  });

  final StudyPlanController controller;
  final SettingsController settingsController;
  final WordKnowledgeRepository wordKnowledgeRepository;
  final FsrsRepository fsrsRepository;
  final StudyRepository studyRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;
  final DailyTaskPlanner dailyTaskPlanner;

  @override
  State<StudyHomePage> createState() => _StudyHomePageState();
}

class _StudyHomePageState extends State<StudyHomePage> {
  DailyStudyPlanSummary? _dailyPlanSummary;
  int _planRequestToken = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleDependenciesChanged);
    widget.settingsController.addListener(_handleDependenciesChanged);
    if (widget.controller.state.status == StudyPlanStatus.initial) {
      widget.controller.load();
    }
    _reloadDailyPlanSummary();
  }

  @override
  void didUpdateWidget(covariant StudyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleDependenciesChanged);
      widget.controller.addListener(_handleDependenciesChanged);
    }
    if (oldWidget.settingsController != widget.settingsController) {
      oldWidget.settingsController.removeListener(_handleDependenciesChanged);
      widget.settingsController.addListener(_handleDependenciesChanged);
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.settingsController != widget.settingsController ||
        oldWidget.wordKnowledgeRepository != widget.wordKnowledgeRepository ||
        oldWidget.fsrsRepository != widget.fsrsRepository ||
        oldWidget.dailyTaskPlanner != widget.dailyTaskPlanner) {
      _reloadDailyPlanSummary();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleDependenciesChanged);
    widget.settingsController.removeListener(_handleDependenciesChanged);
    super.dispose();
  }

  void _handleDependenciesChanged() {
    _reloadDailyPlanSummary();
  }

  Future<void> _reloadDailyPlanSummary() async {
    final state = widget.controller.state;
    if (state.status != StudyPlanStatus.ready || state.currentBook == null) {
      if (_dailyPlanSummary != null && mounted) {
        setState(() => _dailyPlanSummary = null);
      }
      return;
    }

    final requestToken = ++_planRequestToken;
    final plan = await _buildDailyPlan(state.currentBook!);
    if (!mounted || requestToken != _planRequestToken) {
      return;
    }
    setState(() => _dailyPlanSummary = plan.summary);
  }

  Future<DailyStudyPlan> _buildDailyPlan(OfficialVocabularyBook book) async {
    final now = DateTime.now().toUtc();
    final settings = widget.settingsController.state.settings;
    final knowledgeRecords = await widget.wordKnowledgeRepository.loadAll();
    final knowledgeByWord = <String, WordKnowledgeRecord>{
      for (final record in knowledgeRecords) record.word: record,
    };

    final allCards = await widget.fsrsRepository.loadAll();
    final cardsByWord = <String, FsrsCard>{
      for (final card in allCards) card.word: card,
    };

    return widget.dailyTaskPlanner.plan(
      DailyStudyPlanRequest(
        book: book,
        bookEntries: book.entries,
        cardsByWord: cardsByWord,
        knowledgeByWord: knowledgeByWord,
        settings: settings,
        now: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.controller,
        widget.settingsController,
      ]),
      builder: (context, _) {
        final state = widget.controller.state;
        return SafeArea(
          child: switch (state.status) {
            StudyPlanStatus.loading || StudyPlanStatus.initial => const Center(
              child: CircularProgressIndicator(),
            ),
            StudyPlanStatus.failure => Center(
              child: Text(state.errorMessage ?? '学习计划加载失败'),
            ),
            StudyPlanStatus.ready => _StudyHomeContent(
              controller: widget.controller,
              settingsController: widget.settingsController,
              wordKnowledgeRepository: widget.wordKnowledgeRepository,
              fsrsRepository: widget.fsrsRepository,
              studyRepository: widget.studyRepository,
              wordDetailPageBuilder: widget.wordDetailPageBuilder,
              dailyTaskPlanner: widget.dailyTaskPlanner,
              dailyPlanSummary: _dailyPlanSummary,
            ),
          },
        );
      },
    );
  }
}

class _StudyHomeContent extends StatelessWidget {
  const _StudyHomeContent({
    required this.controller,
    required this.settingsController,
    required this.wordKnowledgeRepository,
    required this.fsrsRepository,
    required this.studyRepository,
    required this.wordDetailPageBuilder,
    required this.dailyTaskPlanner,
    required this.dailyPlanSummary,
  });

  final StudyPlanController controller;
  final SettingsController settingsController;
  final WordKnowledgeRepository wordKnowledgeRepository;
  final FsrsRepository fsrsRepository;
  final StudyRepository studyRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;
  final DailyTaskPlanner dailyTaskPlanner;
  final DailyStudyPlanSummary? dailyPlanSummary;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final selectedNotebook = state.selectedNotebook;
    final settings = settingsController.state.settings;
    final dailyNewCount = settings.dailyStudyTarget;
    final dailyReviewRatio = settings.dailyReviewRatio.clamp(1, 4);
    final dailyReviewCount = dailyNewCount * dailyReviewRatio;
    final plannedNewCount = dailyPlanSummary?.newCount ?? dailyNewCount;
    final plannedReviewCount = dailyPlanSummary == null
        ? dailyReviewCount
        : dailyPlanSummary!.reviewCount + dailyPlanSummary!.probeCount;
    final currentBook = state.currentBook;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StudyHeroBanner(),
          _StudyHeaderCard(
            currentBook: currentBook,
            masteredCount: state.masteredCount,
            remainingCount: state.remainingCount,
            onChangeBook: () => _openBookPicker(context),
            onOpenWordList: currentBook == null
                ? null
                : () => _openWordListPage(context, currentBook),
            onOpenTaskSettings: currentBook == null
                ? null
                : () => _openStudyPlanPage(context),
          ),
          if (currentBook != null) ...[
            const SizedBox(height: 16),
            _DailyTaskSettingsCard(
              dailyNewCount: dailyNewCount,
              dailyReviewCount: dailyReviewCount,
              dailyReviewRatio: dailyReviewRatio,
              plannedNewCount: plannedNewCount,
              plannedReviewCount: plannedReviewCount,
              dailyPlanSummary: dailyPlanSummary,
              onOpenSettings: () => _openTaskSettingsPage(context, currentBook),
              onStartNew: () => _openStudySessionForSources(
                context,
                currentBook,
                sources: const <StudyTaskSource>{StudyTaskSource.newWord},
                emptyMessage: '暂无新学任务',
              ),
              onStartReview: () => _openStudySessionForSources(
                context,
                currentBook,
                sources: const <StudyTaskSource>{
                  StudyTaskSource.mustReview,
                  StudyTaskSource.normalReview,
                  StudyTaskSource.probeWord,
                  StudyTaskSource.newWord,
                },
                emptyMessage: '暂无复习任务',
              ),
            ),
            const SizedBox(height: 16),
            _FreePracticeCard(
              hasCurrentBook: true,
              onListPractice: () => _openWordListPage(context, currentBook),
              onMemoryAidVideo: () => _showPracticeComingSoon(context, '助记视频'),
              onPortableListening: () =>
                  _showPracticeComingSoon(context, '随身听'),
              onPhonics: () => _showPracticeComingSoon(context, '自然拼读'),
              onWordDictation: () => _showPracticeComingSoon(context, '单词听写'),
              onListeningDrill: () => _showPracticeComingSoon(context, '听力训练'),
              onShadowing: () => _showPracticeComingSoon(context, '跟读对比'),
              onDefinitionPractice: () =>
                  _showPracticeComingSoon(context, '释义巩固'),
              onSpellingPractice: () =>
                  _showPracticeComingSoon(context, '拼写练习'),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF10C28E),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                key: const ValueKey('my-vocabulary-entry'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openNotebookPickerSheet(context, state),
                child: Row(
                  children: [
                    Text(
                      selectedNotebook == null
                          ? '我的词汇'
                          : '${selectedNotebook.name} (${selectedNotebook.wordCount})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _openNotebookPickerSheet(context, state),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF99A1B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (selectedNotebook == null || selectedNotebook.words.isEmpty)
            _MyBooksEmptyCard(
              onImport: () =>
                  _openImportVocabularyPage(context, selectedNotebook?.id),
            )
          else
            _NotebookWordListCard(notebook: selectedNotebook),
        ],
      ),
    );
  }

  Future<void> _openBookPicker(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocabularyBookPickerPage(controller: controller),
      ),
    );
  }

  Future<void> _openTaskSettingsPage(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyTaskSettingsPage(
          settingsController: settingsController,
          book: book,
        ),
      ),
    );
  }

  Future<void> _openStudyPlanPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyPlanSettingsPage(
          settingsController: settingsController,
          studyPlanController: controller,
          wordKnowledgeRepository: wordKnowledgeRepository,
          fsrsRepository: fsrsRepository,
          wordDetailPageBuilder: wordDetailPageBuilder,
        ),
      ),
    );
  }

  Future<void> _openWordListPage(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocabularyWordListPage(
          book: book,
          settingsController: settingsController,
          studyPlanController: controller,
          fsrsRepository: fsrsRepository,
          wordKnowledgeRepository: wordKnowledgeRepository,
          wordDetailPageBuilder: wordDetailPageBuilder,
        ),
      ),
    );
  }

  Future<void> _openNotebookPickerSheet(
    BuildContext parentContext,
    StudyPlanState state,
  ) async {
    await showModalBottomSheet<void>(
      context: parentContext,
      backgroundColor: const Color(0xFFF7F8FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '生词本',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                for (final notebook in state.notebooks) ...[
                  _NotebookPickerTile(
                    notebook: notebook,
                    selected: notebook.id == state.selectedNotebookId,
                    onTap: () async {
                      await controller.selectNotebook(notebook.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    onMenuTap: () async {
                      Navigator.of(context).pop();
                      await _handleNotebookAction(parentContext, notebook);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                FilledButton(
                  key: const ValueKey('create-notebook-button'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _showCreateNotebookDialog(parentContext);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10C28E),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('新建生词本'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleNotebookAction(
    BuildContext context,
    VocabularyNotebook notebook,
  ) async {
    final action = await _showNotebookActionSheet(context);
    if (!context.mounted || action == null) {
      return;
    }
    if (action == _NotebookAction.edit) {
      await _showEditNotebookDialog(context, notebook);
      return;
    }
    await _confirmDeleteNotebook(context, notebook);
  }

  Future<void> _showCreateNotebookDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '新建生词本',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('create-notebook-name-input'),
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: '输入生词本名称',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('create-notebook-description-input'),
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '输入描述（可选）',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final success = await controller.createNotebook(
                          name: nameController.text,
                          description: descriptionController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('创建'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditNotebookDialog(
    BuildContext context,
    VocabularyNotebook notebook,
  ) async {
    final nameController = TextEditingController(text: notebook.name);
    final descriptionController = TextEditingController(
      text: notebook.description,
    );
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '编辑生词本',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('edit-notebook-name-input'),
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: '输入生词本名称',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('edit-notebook-description-input'),
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '输入描述（可选）',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final success = await controller.updateNotebook(
                          notebookId: notebook.id,
                          name: nameController.text,
                          description: descriptionController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _confirmDeleteNotebook(
    BuildContext context,
    VocabularyNotebook notebook,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除生词本'),
          content: Text('确认删除“${notebook.name}”？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }
    await controller.deleteNotebook(notebook.id);
  }

  Future<void> _openImportVocabularyPage(
    BuildContext context,
    String? notebookId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImportVocabularyPage(
          controller: controller,
          initialNotebookId: notebookId,
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openStudySession(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
    await _openStudySessionForSources(
      context,
      book,
      sources: const <StudyTaskSource>{
        StudyTaskSource.mustReview,
        StudyTaskSource.normalReview,
        StudyTaskSource.probeWord,
        StudyTaskSource.newWord,
      },
      emptyMessage: '暂无今日任务',
    );
  }

  Future<void> _openStudySessionForSources(
    BuildContext context,
    OfficialVocabularyBook book, {
    required Set<StudyTaskSource> sources,
    required String emptyMessage,
  }) async {
    final now = DateTime.now().toUtc();
    final settings = settingsController.state.settings;
    final bookEntries = book.entries;
    final knowledgeRecords = await wordKnowledgeRepository.loadAll();
    final knowledgeByWord = <String, WordKnowledgeRecord>{
      for (final record in knowledgeRecords) record.word: record,
    };

    final allCards = await fsrsRepository.loadAll();
    final cardsByWord = <String, FsrsCard>{};
    for (final card in allCards) {
      cardsByWord[card.word] = card;
    }

    final plan = dailyTaskPlanner.plan(
      DailyStudyPlanRequest(
        book: book,
        bookEntries: bookEntries,
        cardsByWord: cardsByWord,
        knowledgeByWord: knowledgeByWord,
        settings: settings,
        now: now,
      ),
    );
    final sessionEntries = <WordEntry>[
      for (final item in plan.mixedQueue)
        if (sources.contains(item.source)) item.entry,
    ];
    final entrySourcesByWord = <String, StudyTaskSource>{
      for (final item in plan.mixedQueue)
        if (sources.contains(item.source))
          WordKnowledgeRecord.normalizeWord(item.entry.word): item.source,
    };
    if (sessionEntries.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emptyMessage)));
      return;
    }

    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudySessionPage.forBook(
          entries: sessionEntries,
          studyRepository: studyRepository,
          fsrsRepository: fsrsRepository,
          wordKnowledgeRepository: wordKnowledgeRepository,
          wordDetailPageBuilder: wordDetailPageBuilder,
          entrySourcesByWord: entrySourcesByWord,
        ),
      ),
    );
  }

  void _showPracticeComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label 即将上线')));
  }
}

class _StudyHeaderCard extends StatelessWidget {
  const _StudyHeaderCard({
    required this.currentBook,
    required this.masteredCount,
    required this.remainingCount,
    required this.onChangeBook,
    required this.onOpenWordList,
    required this.onOpenTaskSettings,
  });

  final OfficialVocabularyBook? currentBook;
  final int masteredCount;
  final int remainingCount;
  final VoidCallback onChangeBook;
  final VoidCallback? onOpenWordList;
  final VoidCallback? onOpenTaskSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (currentBook == null) {
      return _ReferenceSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请选择词汇表',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1F24),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '系统提供四级、六级、考研、专四、专八、托福、雅思、SAT 等官方词汇表。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8A8E97),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            _PrimaryYellowButton(label: '选择词汇表', onTap: onChangeBook),
          ],
        ),
      );
    }

    final learnedCount = (currentBook!.wordCount - remainingCount).clamp(
      0,
      currentBook!.wordCount,
    );
    final progress = currentBook!.wordCount == 0
        ? 0.0
        : learnedCount / currentBook!.wordCount;

    return _ReferenceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  currentBook!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF202229),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SectionIconButton(
                icon: Icons.hexagon_outlined,
                onTap: onOpenTaskSettings ?? onChangeBook,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                '正在学习',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF626771),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Text(
                '已学 $learnedCount/${currentBook!.wordCount} 词',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF454850),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReferenceProgressBar(progress: progress),
          const SizedBox(height: 6),
          Row(
            children: [
              if (onOpenWordList != null)
                TextButton(
                  onPressed: onOpenWordList,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFFBCC1C9),
                  ),
                  child: const Text(
                    '列表刷词',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: onChangeBook,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFFBCC1C9),
                ),
                child: const Text(
                  '更换词书',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyTaskSettingsCard extends StatelessWidget {
  const _DailyTaskSettingsCard({
    required this.dailyNewCount,
    required this.dailyReviewCount,
    required this.dailyReviewRatio,
    required this.plannedNewCount,
    required this.plannedReviewCount,
    required this.dailyPlanSummary,
    required this.onOpenSettings,
    required this.onStartNew,
    required this.onStartReview,
  });

  final int dailyNewCount;
  final int dailyReviewCount;
  final int dailyReviewRatio;
  final int plannedNewCount;
  final int plannedReviewCount;
  final DailyStudyPlanSummary? dailyPlanSummary;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onStartNew;
  final VoidCallback? onStartReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ReferenceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '今日计划',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1F24),
                ),
              ),
              const Spacer(),
              if (onOpenSettings != null)
                _SectionIconButton(
                  icon: Icons.tune_rounded,
                  onTap: onOpenSettings,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: dailyPlanSummary != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _planSummaryLabel(dailyPlanSummary!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF5D626C),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _planReasonLabel(dailyPlanSummary!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: const Color(0xFFA4A9B2),
                          height: 1.35,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '新词 $dailyNewCount   复习 $dailyReviewCount   比例 1:$dailyReviewRatio',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      color: const Color(0xFF5D626C),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 98,
            child: Row(
              children: [
                Expanded(
                  child: _PlanCounter(
                    label: '新学',
                    completed: 0,
                    total: plannedNewCount,
                    valueKey: const ValueKey('study-header-new-count'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 64,
                  color: const Color(0xFFE7EBF1),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: _PlanCounter(
                    label: '复习',
                    completed: 0,
                    total: plannedReviewCount,
                    valueKey: const ValueKey('study-header-review-count'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryYellowButton(
                  label: '新学',
                  onTap: onStartNew,
                  height: 50,
                  buttonKey: const ValueKey('daily-plan-start-new'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryYellowButton(
                  label: '复习',
                  onTap: onStartReview,
                  height: 50,
                  buttonKey: const ValueKey('daily-plan-start-review'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _planSummaryLabel(DailyStudyPlanSummary summary) {
    final parts = <String>[
      _planningModeLabel(summary.strategyLabel),
      _backlogLabel(summary.backlogLevel),
      '复习 ${summary.reviewCount}',
      '新词 ${summary.newCount}',
      if (summary.probeCount > 0) '抽查 ${summary.probeCount}',
    ];
    return parts.join(' · ');
  }

  String _planReasonLabel(DailyStudyPlanSummary summary) {
    return summary.reasonSummary.take(2).join(' · ');
  }

  String _planningModeLabel(String strategyLabel) {
    return switch (strategyLabel) {
      'reviewFirst' => '复习优先',
      'sprint' => '冲刺突击',
      _ => '均衡推进',
    };
  }

  String _backlogLabel(StudyBacklogLevel backlogLevel) {
    return switch (backlogLevel) {
      StudyBacklogLevel.none => '无积压',
      StudyBacklogLevel.light => '积压轻微',
      StudyBacklogLevel.medium => '积压中等',
      StudyBacklogLevel.heavy => '积压较重',
    };
  }
}

class _StudyHeroBanner extends StatelessWidget {
  const _StudyHeroBanner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ReferenceSectionCard extends StatelessWidget {
  const _ReferenceSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrimaryYellowButton extends StatelessWidget {
  const _PrimaryYellowButton({
    required this.label,
    required this.onTap,
    this.height = 56,
    this.buttonKey,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const <Color>[Color(0xFFFFD94D), Color(0xFFFFCD05)]
              : const <Color>[Color(0xFFF0F1F4), Color(0xFFE3E5EA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x33FFC800),
                  offset: Offset(0, 5),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: height,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? const Color(0xFF1B1E25)
                      : const Color(0xFF9297A1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCounter extends StatelessWidget {
  const _PlanCounter({
    required this.label,
    required this.completed,
    required this.total,
    this.valueKey,
  });

  final String label;
  final int completed;
  final int total;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          key: valueKey,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$completed',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1D1F24),
                  letterSpacing: -1.2,
                ),
              ),
              TextSpan(
                text: ' / ',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 21,
                  color: const Color(0xFFA4AAB4),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: '$total',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 21,
                  color: const Color(0xFFA4AAB4),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: const Color(0xFF9DA3AE),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ReferenceProgressBar extends StatelessWidget {
  const _ReferenceProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final thumbCenter = clamped == 0
              ? 4.0
              : (trackWidth * clamped).clamp(4.0, trackWidth - 4.0);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: trackWidth * clamped,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DDE6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: thumbCenter - 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FreePracticeCard extends StatelessWidget {
  const _FreePracticeCard({
    required this.hasCurrentBook,
    required this.onListPractice,
    required this.onMemoryAidVideo,
    required this.onPortableListening,
    required this.onPhonics,
    required this.onWordDictation,
    required this.onListeningDrill,
    required this.onShadowing,
    required this.onDefinitionPractice,
    required this.onSpellingPractice,
  });

  final bool hasCurrentBook;
  final VoidCallback? onListPractice;
  final VoidCallback onMemoryAidVideo;
  final VoidCallback onPortableListening;
  final VoidCallback onPhonics;
  final VoidCallback onWordDictation;
  final VoidCallback onListeningDrill;
  final VoidCallback onShadowing;
  final VoidCallback onDefinitionPractice;
  final VoidCallback onSpellingPractice;

  @override
  Widget build(BuildContext context) {
    final iconItems = <({IconData icon, String label, VoidCallback? onTap})>[
      (
        icon: Icons.view_list_rounded,
        label: '列表刷词',
        onTap: hasCurrentBook ? onListPractice : null,
      ),
      (icon: Icons.videocam_outlined, label: '助记视频', onTap: onMemoryAidVideo),
      (
        icon: Icons.headphones_rounded,
        label: '随身听',
        onTap: onPortableListening,
      ),
      (icon: Icons.spellcheck_rounded, label: '自然拼读', onTap: onPhonics),
      (icon: Icons.text_fields_rounded, label: '单词听写', onTap: onWordDictation),
    ];

    return _ReferenceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自由练习',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1F24),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PracticeFeatureTile(
                  color: const Color(0xFFE8F2FB),
                  accentColor: const Color(0xFF5D75E6),
                  icon: Icons.headphones_rounded,
                  label: '听力训练',
                  onTap: onListeningDrill,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PracticeFeatureTile(
                  color: const Color(0xFFF2EEFC),
                  accentColor: const Color(0xFF8B56EA),
                  icon: Icons.mic_none_rounded,
                  label: '跟读对比',
                  onTap: onShadowing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PracticeFeatureTile(
                  color: const Color(0xFFFFF4DA),
                  accentColor: const Color(0xFFFF9300),
                  icon: Icons.menu_book_rounded,
                  label: '释义巩固',
                  onTap: onDefinitionPractice,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PracticeFeatureTile(
                  color: const Color(0xFFE4F6EF),
                  accentColor: const Color(0xFF1DBD84),
                  icon: Icons.edit_outlined,
                  label: '拼写练习',
                  onTap: onSpellingPractice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final item in iconItems)
                Expanded(
                  child: _PracticeIconShortcut(
                    icon: item.icon,
                    label: item.label,
                    onTap: item.onTap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeFeatureTile extends StatelessWidget {
  const _PracticeFeatureTile({
    required this.color,
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final Color accentColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF23252B),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionIconButton extends StatelessWidget {
  const _SectionIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 19, color: const Color(0xFF2B2D33)),
        ),
      ),
    );
  }
}

class _PracticeQuickIcon extends StatelessWidget {
  const _PracticeQuickIcon({required this.icon, required this.enabled});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF5F7FB) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 19,
        color: enabled ? const Color(0xFF2C2E35) : const Color(0xFFB5BAC3),
      ),
    );
  }
}

class _PracticeIconShortcut extends StatelessWidget {
  const _PracticeIconShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PracticeQuickIcon(icon: icon, enabled: enabled),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF44474F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF99A1B2),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF99A1B2),
            ),
          ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _WeekProgressCard extends StatelessWidget {
  const _WeekProgressCard({required this.days});

  final List<StudyCalendarDay> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final day in days)
            _WeekDayCell(
              weekdayLabel: day.weekdayLabel,
              dayOfMonth: day.dayOfMonth,
              isToday: day.isToday,
            ),
        ],
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.weekdayLabel,
    required this.dayOfMonth,
    required this.isToday,
  });

  final String weekdayLabel;
  final int dayOfMonth;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          weekdayLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xFF9CA3B5)),
        ),
        const SizedBox(height: 18),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            border: isToday
                ? Border.all(color: const Color(0xFFFF9500), width: 3)
                : null,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayOfMonth',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MyBooksEmptyCard extends StatelessWidget {
  const _MyBooksEmptyCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F8F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_books_outlined,
              size: 58,
              color: Color(0xFF10C28E),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            '暂无单词',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '收藏或是导入词汇',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF9CA3B5),
            ),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            key: const ValueKey('empty-import-words-button'),
            onPressed: onImport,
            icon: const Icon(Icons.add_rounded),
            label: const Text('导入词汇'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10C28E),
              foregroundColor: Colors.white,
              minimumSize: const Size(220, 62),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookPickerTile extends StatelessWidget {
  const _NotebookPickerTile({
    required this.notebook,
    required this.selected,
    required this.onTap,
    this.onMenuTap,
  });

  final VocabularyNotebook notebook;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF10C28E),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${notebook.name} (${notebook.wordCount})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10C28E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notebook.isDefault
                          ? '默认生词本'
                          : '${notebook.wordCount} 个单词',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8D97A7),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Color(0xFF10C28E)),
              IconButton(
                key: ValueKey('notebook-actions-${notebook.id}'),
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_vert, color: Color(0xFF10C28E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookWordListCard extends StatelessWidget {
  const _NotebookWordListCard({required this.notebook});

  final VocabularyNotebook notebook;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupNotebookWordsByDay(notebook.items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in grouped) ...[
          Row(
            children: [
              Text(
                '${section.$1} (${section.$2.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF959DAC),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFB0B7C4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in section.$2) ...[
            _NotebookWordRow(item: item),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

class _NotebookWordRow extends StatelessWidget {
  const _NotebookWordRow({required this.item});

  final VocabularyNotebookWord item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(
            Icons.volume_up_outlined,
            size: 30,
            color: Color(0xFF16B686),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.word,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '已添加到生词本',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF9AA1AF), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _StudyTopBar extends StatelessWidget {
  const _StudyTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 30),
                Positioned(
                  left: 6,
                  bottom: -2,
                  child: Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10C28E),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '单词',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E2433),
          ),
        ),
        const Spacer(),
        const Icon(Icons.style_outlined, size: 30, color: Color(0xFF1B2232)),
        const SizedBox(width: 16),
        const Icon(
          Icons.keyboard_alt_outlined,
          size: 30,
          color: Color(0xFF1B2232),
        ),
        const SizedBox(width: 16),
        const Icon(
          Icons.more_horiz_rounded,
          size: 30,
          color: Color(0xFF1B2232),
        ),
      ],
    );
  }
}

List<(String, List<VocabularyNotebookWord>)> _groupNotebookWordsByDay(
  List<VocabularyNotebookWord> items,
) {
  final sorted = List<VocabularyNotebookWord>.from(items)
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  final groups = <DateTime, List<VocabularyNotebookWord>>{};

  DateTime normalize(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  for (final item in sorted) {
    final key = normalize(item.addedAt);
    groups.putIfAbsent(key, () => <VocabularyNotebookWord>[]).add(item);
  }

  final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  String formatDate(DateTime date) {
    if (date == today) {
      return '今天';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month-$day';
  }

  return keys
      .map(
        (key) =>
            (formatDate(key), groups[key] ?? const <VocabularyNotebookWord>[]),
      )
      .toList(growable: false);
}

Future<_NotebookAction?> _showNotebookActionSheet(BuildContext context) {
  return showModalBottomSheet<_NotebookAction>(
    context: context,
    backgroundColor: const Color(0xFFF7F8FC),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('编辑'),
                onTap: () => Navigator.of(context).pop(_NotebookAction.edit),
              ),
              ListTile(
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.of(context).pop(_NotebookAction.delete),
              ),
              ListTile(
                title: const Text('取消'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ImportVocabularyPage extends StatefulWidget {
  const _ImportVocabularyPage({
    required this.controller,
    required this.initialNotebookId,
  });

  final StudyPlanController controller;
  final String? initialNotebookId;

  @override
  State<_ImportVocabularyPage> createState() => _ImportVocabularyPageState();
}

class _ImportVocabularyPageState extends State<_ImportVocabularyPage> {
  late final TextEditingController _inputController;
  String? _selectedNotebookId;
  static const int _maxChars = 1000;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    final state = widget.controller.state;
    _selectedNotebookId = widget.initialNotebookId ?? state.selectedNotebookId;
    if (_selectedNotebookId == null && state.notebooks.isNotEmpty) {
      _selectedNotebookId = state.notebooks.first.id;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    VocabularyNotebook? notebook;
    for (final item in state.notebooks) {
      if (item.id == _selectedNotebookId) {
        notebook = item;
        break;
      }
    }
    final remaining = (_maxChars - _inputController.text.length).clamp(
      0,
      _maxChars,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 30),
                  ),
                  const Spacer(),
                  const Text(
                    '导入词汇',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: notebook == null ? null : _saveWords,
                    child: const Text('保存'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  key: const ValueKey('import-notebook-selector'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: _openNotebookSelector,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F8F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Color(0xFF10C28E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notebook?.name ?? '请选择生词本',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          key: const ValueKey('import-words-input'),
                          controller: _inputController,
                          maxLength: _maxChars,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          minLines: null,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: '输入单词，每行一个',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 18, height: 1.45),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '还可输入$remaining个字符',
                        style: const TextStyle(
                          color: Color(0xFF8B93A5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotebookSelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF7F8FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final state = widget.controller.state;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '生词本',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                for (final notebook in state.notebooks) ...[
                  _NotebookPickerTile(
                    notebook: notebook,
                    selected: notebook.id == _selectedNotebookId,
                    onTap: () => Navigator.of(context).pop(notebook.id),
                    onMenuTap: () async {
                      Navigator.of(context).pop();
                      await _handleNotebookAction(notebook);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                FilledButton(
                  key: const ValueKey('create-notebook-button'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _showCreateNotebookDialog();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10C28E),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('新建生词本'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _selectedNotebookId = selected;
    });
  }

  Future<void> _handleNotebookAction(VocabularyNotebook notebook) async {
    final action = await _showNotebookActionSheet(context);
    if (!mounted || action == null) {
      return;
    }
    if (action == _NotebookAction.edit) {
      await _showEditNotebookDialog(notebook);
      return;
    }
    await _confirmDeleteNotebook(notebook);
  }

  Future<void> _showCreateNotebookDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '新建生词本',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('create-notebook-name-input'),
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: '输入生词本名称',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('create-notebook-description-input'),
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '输入描述（可选）',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final success = await widget.controller.createNotebook(
                          name: nameController.text,
                          description: descriptionController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('创建'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedNotebookId = widget.controller.state.selectedNotebookId;
    });
  }

  Future<void> _showEditNotebookDialog(VocabularyNotebook notebook) async {
    final nameController = TextEditingController(text: notebook.name);
    final descriptionController = TextEditingController(
      text: notebook.description,
    );
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '编辑生词本',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('edit-notebook-name-input'),
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: '输入生词本名称',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('edit-notebook-description-input'),
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '输入描述（可选）',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final success = await widget.controller.updateNotebook(
                          notebookId: notebook.id,
                          name: nameController.text,
                          description: descriptionController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedNotebookId = widget.controller.state.selectedNotebookId;
    });
  }

  Future<void> _confirmDeleteNotebook(VocabularyNotebook notebook) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除生词本'),
          content: Text('确认删除“${notebook.name}”？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }
    await widget.controller.deleteNotebook(notebook.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedNotebookId = widget.controller.state.selectedNotebookId;
    });
  }

  Future<void> _saveWords() async {
    final notebookId = _selectedNotebookId;
    if (notebookId == null) {
      return;
    }
    final words = _inputController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (words.isEmpty) {
      return;
    }
    final success = await widget.controller.importWordsToNotebook(
      notebookId: notebookId,
      words: words,
    );
    if (!mounted || !success) {
      return;
    }
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !Navigator.of(context).canPop()) {
        return;
      }
      Navigator.of(context).pop();
    });
  }
}

// ignore: unused_element
class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.title,
    required this.coverKey,
    required this.size,
  });

  final String title;
  final String coverKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (coverKey) {
      'aurora' => const [Color(0xFFF6E6B5), Color(0xFFBFEFDB)],
      'mint' => const [Color(0xFFD9F5EE), Color(0xFFECFBF3)],
      'amber' => const [Color(0xFFFFE7BF), Color(0xFFFFF4D8)],
      'violet' => const [Color(0xFFE7E0FF), Color(0xFFF5F1FF)],
      'sky' => const [Color(0xFFDDF4FF), Color(0xFFF1FBFF)],
      'rose' => const [Color(0xFFFFE0EA), Color(0xFFFFF2F6)],
      'ocean' => const [Color(0xFFD8F0FF), Color(0xFFEFF9FF)],
      'graphite' => const [Color(0xFFE8EAEE), Color(0xFFF5F6F8)],
      _ => const [Color(0xFFD9F5EE), Color(0xFFECFBF3)],
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        title.replaceAll('乱序完整版', '').split(' ').first,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF10C28E),
        ),
      ),
    );
  }
}
