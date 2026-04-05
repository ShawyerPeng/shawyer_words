import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StudyTopBar(
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 14),
          _StudyHeaderCard(
            currentBook: state.currentBook,
            newCount: plannedNewCount,
            reviewCount: plannedReviewCount,
            masteredCount: state.masteredCount,
            remainingCount: state.remainingCount,
            onStart: state.currentBook == null
                ? null
                : () => _openStudySession(context, state.currentBook!),
            onChangeBook: () => _openBookPicker(context),
            onOpenWordList: state.currentBook == null
                ? null
                : () => _openWordListPage(context, state.currentBook!),
          ),
          if (state.currentBook != null) ...[
            const SizedBox(height: 14),
            _DailyTaskSettingsCard(
              dailyNewCount: dailyNewCount,
              dailyReviewCount: dailyReviewCount,
              dailyReviewRatio: dailyReviewRatio,
              dailyPlanSummary: dailyPlanSummary,
              onTap: () => _openTaskSettingsPage(context, state.currentBook!),
            ),
          ],
          const SizedBox(height: 24),
          _WeekProgressCard(days: state.weekDays),
          const SizedBox(height: 28),
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

  Future<void> _openStudySession(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
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
      for (final item in plan.mixedQueue) item.entry,
    ];
    final entrySourcesByWord = <String, StudyTaskSource>{
      for (final item in plan.mixedQueue)
        WordKnowledgeRecord.normalizeWord(item.entry.word): item.source,
    };
    if (sessionEntries.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无今日任务')));
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
}

class _StudyHeaderCard extends StatelessWidget {
  const _StudyHeaderCard({
    required this.currentBook,
    required this.newCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.remainingCount,
    required this.onStart,
    required this.onChangeBook,
    required this.onOpenWordList,
  });

  final OfficialVocabularyBook? currentBook;
  final int newCount;
  final int reviewCount;
  final int masteredCount;
  final int remainingCount;
  final VoidCallback? onStart;
  final VoidCallback onChangeBook;
  final VoidCallback? onOpenWordList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: currentBook == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择你的词汇表',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '系统提供四级、六级、考研、专四、专八、托福、雅思、SAT 等官方词汇表。',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF8B93A5),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onChangeBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10C28E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('选择词汇表'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookCover(
                      title: currentBook!.title,
                      coverKey: currentBook!.coverKey,
                      size: 84,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentBook!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: onOpenWordList,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF10C28E),
                                  side: const BorderSide(
                                    color: Color(0xFFD8F1E8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.list_alt_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  '词表',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: onChangeBook,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10C28E),
                              side: const BorderSide(color: Color(0xFFD8F1E8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              '更改',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: remainingCount == 0
                        ? 0
                        : masteredCount / remainingCount,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE9EBF0),
                    color: const Color(0xFF10C28E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '复习中 $reviewCount   已掌握 $masteredCount   未学 $remainingCount / ${currentBook!.wordCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF99A1B2),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF0F2F6)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(
                        value: '$newCount',
                        label: '待学习',
                        valueKey: const ValueKey('study-header-new-count'),
                      ),
                    ),
                    Expanded(
                      child: _MetricBlock(
                        value: '$reviewCount',
                        label: '待复习',
                        valueKey: const ValueKey('study-header-review-count'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10C28E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('开始', style: TextStyle(fontSize: 18)),
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
    required this.dailyPlanSummary,
    required this.onTap,
  });

  final int dailyNewCount;
  final int dailyReviewCount;
  final int dailyReviewRatio;
  final DailyStudyPlanSummary? dailyPlanSummary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '每日任务量',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '新词 $dailyNewCount   复习 $dailyReviewCount   比例 1:$dailyReviewRatio',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF99A1B2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dailyPlanSummary != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _planSummaryLabel(dailyPlanSummary!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF657085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (dailyPlanSummary!.reasonSummary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _planReasonLabel(dailyPlanSummary!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8A93A5),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF99A1B2)),
            ],
          ),
        ),
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

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.value, required this.label, this.valueKey});

  final String value;
  final String label;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          key: valueKey,
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
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  key: const ValueKey('import-notebook-selector'),
                  borderRadius: BorderRadius.circular(18),
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
                          borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
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
