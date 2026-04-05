import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_book_picker_page.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_wordlist_page.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_record.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class StudyPlanSettingsPage extends StatefulWidget {
  const StudyPlanSettingsPage({
    super.key,
    required this.settingsController,
    required this.studyPlanController,
    required this.wordKnowledgeRepository,
    required this.fsrsRepository,
    required this.wordDetailPageBuilder,
  });

  final SettingsController settingsController;
  final StudyPlanController studyPlanController;
  final WordKnowledgeRepository wordKnowledgeRepository;
  final FsrsRepository fsrsRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  State<StudyPlanSettingsPage> createState() => _StudyPlanSettingsPageState();
}

class _StudyPlanSettingsPageState extends State<StudyPlanSettingsPage> {
  bool _loadingProgress = false;
  int _learnedCount = 0;
  int _masteredCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.studyPlanController.state.status == StudyPlanStatus.initial) {
      widget.studyPlanController.load();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadProgress();
    });
  }

  Future<void> _reloadProgress() async {
    final book = widget.studyPlanController.state.currentBook;
    if (book == null || book.entries.isEmpty) {
      if (mounted) {
        setState(() {
          _learnedCount = 0;
          _masteredCount = 0;
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _loadingProgress = true);
    }
    try {
      final bookWords = book.entries
          .map((entry) => WordKnowledgeRecord.normalizeWord(entry.word))
          .toSet();
      final records = await widget.wordKnowledgeRepository.loadAll();
      var learned = 0;
      var mastered = 0;
      for (final record in records) {
        if (!bookWords.contains(record.word)) {
          continue;
        }
        learned += 1;
        if (record.isKnown) {
          mastered += 1;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _learnedCount = learned;
        _masteredCount = mastered;
        _loadingProgress = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.settingsController,
        widget.studyPlanController,
      ]),
      builder: (context, _) {
        final settings = widget.settingsController.state.settings;
        final planState = widget.studyPlanController.state;
        final book = planState.currentBook;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              children: [
                SettingsHeader(
                  title: '学习计划',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 20),
                _CurrentBookCard(
                  book: book,
                  masteredCount: _masteredCount,
                  learnedCount: _learnedCount,
                  isLoading: _loadingProgress,
                  onOpenWordList: book == null
                      ? null
                      : () => _openWordList(context, book),
                  onReset: book == null ? null : () => _confirmReset(context),
                  onChangeBook: () => _openBookPicker(context),
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '每日计划',
                  children: [
                    SettingsActionTile(
                      title: '新学单词量',
                      value: '${settings.dailyStudyTarget}',
                      onTap: () => _pickDailyNewCount(context, settings),
                    ),
                    SettingsActionTile(
                      title: '复习任务上限',
                      value: _reviewLimitLabel(
                        settings.dailyReviewLimitMultiplier,
                      ),
                      onTap: () => _pickReviewLimit(context, settings),
                    ),
                    SettingsActionTile(
                      title: '计划策略',
                      value: _studyPlanningModeLabel(
                        settings.studyPlanningMode,
                      ),
                      onTap: () => showSingleChoiceSheet<StudyPlanningMode>(
                        context,
                        title: '计划策略',
                        currentValue: settings.studyPlanningMode,
                        options: const <SettingsOption<StudyPlanningMode>>[
                          SettingsOption(
                            value: StudyPlanningMode.balanced,
                            label: '均衡推进',
                          ),
                          SettingsOption(
                            value: StudyPlanningMode.reviewFirst,
                            label: '复习优先',
                          ),
                          SettingsOption(
                            value: StudyPlanningMode.sprint,
                            label: '冲刺突击',
                          ),
                        ],
                        onSelected:
                            widget.settingsController.updateStudyPlanningMode,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('智能复习'),
                      subtitle: const Text('开启后可减少熟悉单词的复习次数'),
                      value: settings.smartReviewEnabled,
                      onChanged:
                          widget.settingsController.updateSmartReviewEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '学习设置',
                  children: [
                    SettingsActionTile(
                      title: '背单词模式',
                      value: _studyModeLabel(settings.studyMode),
                      onTap: () => showSingleChoiceSheet<StudyMode>(
                        context,
                        title: '背单词模式',
                        currentValue: settings.studyMode,
                        options: const <SettingsOption<StudyMode>>[
                          SettingsOption(value: StudyMode.easy, label: '轻松模式'),
                          SettingsOption(value: StudyMode.fast, label: '速刷模式'),
                          SettingsOption(
                            value: StudyMode.intensive,
                            label: '牢记模式',
                          ),
                          SettingsOption(
                            value: StudyMode.phonics,
                            label: '拼读模式',
                          ),
                        ],
                        onSelected: widget.settingsController.updateStudyMode,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('单词预览'),
                      value: settings.wordPreviewEnabled,
                      onChanged:
                          widget.settingsController.updateWordPreviewEnabled,
                    ),
                    SettingsActionTile(
                      title: '出词方式',
                      value: _wordPickModeLabel(settings.wordPickMode),
                      onTap: () => showSingleChoiceSheet<WordPickMode>(
                        context,
                        title: '出词方式',
                        currentValue: settings.wordPickMode,
                        options: const <SettingsOption<WordPickMode>>[
                          SettingsOption(
                            value: WordPickMode.system,
                            label: '系统推荐',
                          ),
                          SettingsOption(
                            value: WordPickMode.manual,
                            label: '自主选词',
                          ),
                        ],
                        onSelected:
                            widget.settingsController.updateWordPickMode,
                      ),
                    ),
                    SettingsActionTile(
                      title: '单词学习顺序',
                      value: _newWordOrderLabel(settings.newWordOrder),
                      onTap: () => showSingleChoiceSheet<NewWordOrder>(
                        context,
                        title: '单词学习顺序',
                        currentValue: settings.newWordOrder,
                        options: const <SettingsOption<NewWordOrder>>[
                          SettingsOption(
                            value: NewWordOrder.unit,
                            label: '单元顺序',
                          ),
                          SettingsOption(
                            value: NewWordOrder.alphabetAsc,
                            label: '字母顺序（A-Z）',
                          ),
                          SettingsOption(
                            value: NewWordOrder.alphabetDesc,
                            label: '字母逆序（Z-A）',
                          ),
                          SettingsOption(
                            value: NewWordOrder.frequency,
                            label: '词频优先',
                          ),
                          SettingsOption(
                            value: NewWordOrder.random,
                            label: '随机乱序',
                          ),
                        ],
                        onSelected:
                            widget.settingsController.updateNewWordOrder,
                      ),
                    ),
                    SettingsActionTile(
                      title: '单词复习顺序',
                      value: _reviewOrderLabel(settings.reviewOrder),
                      onTap: () => showSingleChoiceSheet<ReviewOrder>(
                        context,
                        title: '单词复习顺序',
                        currentValue: settings.reviewOrder,
                        options: const <SettingsOption<ReviewOrder>>[
                          SettingsOption(
                            value: ReviewOrder.reviewFirst,
                            label: '优先复习',
                          ),
                          SettingsOption(
                            value: ReviewOrder.learnFirst,
                            label: '优先学习',
                          ),
                          SettingsOption(
                            value: ReviewOrder.mixed,
                            label: '混合模式',
                          ),
                        ],
                        onSelected: widget.settingsController.updateReviewOrder,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('熟词加速'),
                      subtitle: const Text('开启后，单词首轮答对，本次学习中将不再重复出现'),
                      value: settings.knownWordAccelerationEnabled,
                      onChanged: widget
                          .settingsController
                          .updateKnownWordAccelerationEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '高级设置',
                  children: [
                    SwitchListTile(
                      title: const Text('同时学习多本词书'),
                      value: settings.multiBookEnabled,
                      onChanged:
                          widget.settingsController.updateMultiBookEnabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _reviewLimitLabel(int multiplier) {
    if (multiplier <= 0) {
      return '不设上限';
    }
    return '新学词的$multiplier倍';
  }

  String _studyModeLabel(StudyMode mode) {
    return switch (mode) {
      StudyMode.easy => '轻松模式',
      StudyMode.fast => '速刷模式',
      StudyMode.intensive => '牢记模式',
      StudyMode.phonics => '拼读模式',
    };
  }

  String _studyPlanningModeLabel(StudyPlanningMode mode) {
    return switch (mode) {
      StudyPlanningMode.balanced => '均衡推进',
      StudyPlanningMode.reviewFirst => '复习优先',
      StudyPlanningMode.sprint => '冲刺突击',
    };
  }

  String _wordPickModeLabel(WordPickMode mode) {
    return switch (mode) {
      WordPickMode.system => '系统推荐',
      WordPickMode.manual => '自主选词',
    };
  }

  String _newWordOrderLabel(NewWordOrder order) {
    return switch (order) {
      NewWordOrder.unit => '单元顺序',
      NewWordOrder.alphabetAsc => '字母顺序（A-Z）',
      NewWordOrder.alphabetDesc => '字母逆序（Z-A）',
      NewWordOrder.frequency => '词频优先',
      NewWordOrder.random => '随机乱序',
    };
  }

  String _reviewOrderLabel(ReviewOrder order) {
    return switch (order) {
      ReviewOrder.reviewFirst => '优先复习',
      ReviewOrder.learnFirst => '优先学习',
      ReviewOrder.mixed => '混合模式',
    };
  }

  Future<void> _openWordList(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocabularyWordListPage(
          book: book,
          settingsController: widget.settingsController,
          studyPlanController: widget.studyPlanController,
          fsrsRepository: widget.fsrsRepository,
          wordKnowledgeRepository: widget.wordKnowledgeRepository,
          wordDetailPageBuilder: widget.wordDetailPageBuilder,
        ),
      ),
    );
  }

  Future<void> _openBookPicker(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            VocabularyBookPickerPage(controller: widget.studyPlanController),
      ),
    );
    await _reloadProgress();
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确定重置？'),
          content: const Text('重置后，所有学习记录将被清空。'),
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
    if (confirmed != true) {
      return;
    }
    await widget.settingsController.clearLearningProgress();
    await _reloadProgress();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('学习记录已清空')));
  }

  Future<void> _pickDailyNewCount(
    BuildContext context,
    AppSettings settings,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final options = List<int>.generate(50, (index) => (index + 1) * 10);
        final initial = options.indexOf(
          settings.dailyStudyTarget.clamp(10, 500),
        );
        final controller = FixedExtentScrollController(
          initialItem: initial < 0 ? 1 : initial,
        );
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
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
              const SizedBox(height: 14),
              Text(
                '新学单词量',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 260,
                child: ListWheelScrollView.useDelegate(
                  controller: controller,
                  physics: const FixedExtentScrollPhysics(),
                  itemExtent: 54,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: options.length,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          '${options[index]}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: FilledButton(
                  onPressed: () {
                    final selected = options[controller.selectedItem];
                    Navigator.of(context).pop(selected);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10C28E),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || picked == null) {
      return;
    }
    await widget.settingsController.updateDailyStudyTarget(picked);
  }

  Future<void> _pickReviewLimit(
    BuildContext context,
    AppSettings settings,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final options = <int>[0, 1, 2, 3, 4, 5];
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                const SizedBox(height: 18),
                Text(
                  '复习任务上限',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (final option in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_reviewLimitLabel(option)),
                    trailing: option == settings.dailyReviewLimitMultiplier
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10C28E),
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (picked == null) {
      return;
    }
    await widget.settingsController.updateDailyReviewLimitMultiplier(picked);
  }
}

class _CurrentBookCard extends StatelessWidget {
  const _CurrentBookCard({
    required this.book,
    required this.masteredCount,
    required this.learnedCount,
    required this.isLoading,
    required this.onOpenWordList,
    required this.onReset,
    required this.onChangeBook,
  });

  final OfficialVocabularyBook? book;
  final int masteredCount;
  final int learnedCount;
  final bool isLoading;
  final VoidCallback? onOpenWordList;
  final VoidCallback? onReset;
  final VoidCallback onChangeBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordCount = book?.wordCount ?? 0;
    final title = book?.title ?? '未选择词书';
    final subtitle = book?.subtitle ?? '';

    final progress = wordCount <= 0
        ? 0.0
        : (masteredCount / wordCount).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BookCover(
                title: title,
                coverKey: book?.coverKey ?? 'mint',
                size: 66,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8B93A5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '掌握 $masteredCount，已学 $learnedCount，共 $wordCount 词',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8B93A5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE9EBF0),
              color: const Color(0xFF10C28E),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.list_alt_rounded,
                  label: '查看词表',
                  onTap: onOpenWordList,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.restart_alt_rounded,
                  label: '重置词书',
                  onTap: onReset,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.swap_horiz_rounded,
                  label: '更换词书',
                  onTap: onChangeBook,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
      color: const Color(0xFFF3F5FA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled
                    ? const Color(0xFF10C28E)
                    : const Color(0xFFB0B7C8),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? const Color(0xFF1B2030)
                        : const Color(0xFFB0B7C8),
                    fontWeight: FontWeight.w700,
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF10C28E),
        ),
      ),
    );
  }
}
