import 'package:flutter/cupertino.dart';
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
          backgroundColor: const Color(0xFFF4F5F7),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFF4F5F7),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 44,
            centerTitle: true,
            leadingWidth: 40,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              splashRadius: 18,
              icon: const Icon(
                CupertinoIcons.back,
                size: 24,
                color: Color(0xFF1F2229),
              ),
            ),
            title: const Text(
              '学习计划',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D24),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              children: [
                const SizedBox(height: 6),
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
                const SizedBox(height: 12),
                _SettingsSectionCard(
                  title: '每日计划',
                  children: [
                    _SettingActionRow(
                      title: '新学单词量',
                      value: '${settings.dailyStudyTarget}',
                      onTap: () => _pickDailyNewCount(context, settings),
                    ),
                    _SettingActionRow(
                      title: '复习任务上限',
                      value: _reviewLimitLabel(
                        settings.dailyReviewLimitMultiplier,
                      ),
                      onTap: () => _pickReviewLimit(context, settings),
                    ),
                    _SettingSwitchRow(
                      title: '智能复习',
                      subtitle: '开启后可减少熟悉单词的复习次数',
                      value: settings.smartReviewEnabled,
                      onChanged:
                          widget.settingsController.updateSmartReviewEnabled,
                    ),
                  ],
                ),
                if (book != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      _planEstimateLabel(book, settings.dailyStudyTarget),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF98A1AF),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _SettingsSectionCard(
                  title: '学习设置',
                  children: [
                    _SettingActionRow(
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
                    _SettingActionRow(
                      title: '单词预览',
                      value: _switchValueLabel(settings.wordPreviewEnabled),
                      onTap: () => showSingleChoiceSheet<bool>(
                        context,
                        title: '单词预览',
                        currentValue: settings.wordPreviewEnabled,
                        options: const <SettingsOption<bool>>[
                          SettingsOption(value: false, label: '关闭'),
                          SettingsOption(value: true, label: '打开'),
                        ],
                        onSelected:
                            widget.settingsController.updateWordPreviewEnabled,
                      ),
                    ),
                    _SettingActionRow(
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
                    _SettingActionRow(
                      title: '出词顺序',
                      value: _newWordOrderLabel(settings.newWordOrder),
                      onTap: () => showSingleChoiceSheet<NewWordOrder>(
                        context,
                        title: '出词顺序',
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
                    _SettingActionRow(
                      title: '熟词加速',
                      value: _switchValueLabel(
                        settings.knownWordAccelerationEnabled,
                      ),
                      onTap: () => showSingleChoiceSheet<bool>(
                        context,
                        title: '熟词加速',
                        currentValue: settings.knownWordAccelerationEnabled,
                        options: const <SettingsOption<bool>>[
                          SettingsOption(value: false, label: '关闭'),
                          SettingsOption(value: true, label: '打开'),
                        ],
                        onSelected: widget
                            .settingsController
                            .updateKnownWordAccelerationEnabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SettingsSectionCard(
                  title: '高级设置',
                  children: [
                    _SettingActionRow(
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
                    _SettingActionRow(
                      title: '复习顺序',
                      value: _reviewOrderLabel(settings.reviewOrder),
                      onTap: () => showSingleChoiceSheet<ReviewOrder>(
                        context,
                        title: '复习顺序',
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
                    _SettingActionRow(
                      title: '同时学习多本词书',
                      value: _switchValueLabel(settings.multiBookEnabled),
                      onTap: () => showSingleChoiceSheet<bool>(
                        context,
                        title: '同时学习多本词书',
                        currentValue: settings.multiBookEnabled,
                        options: const <SettingsOption<bool>>[
                          SettingsOption(value: false, label: '关闭'),
                          SettingsOption(value: true, label: '打开'),
                        ],
                        onSelected:
                            widget.settingsController.updateMultiBookEnabled,
                      ),
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

  String _switchValueLabel(bool enabled) {
    return enabled ? '打开' : '关闭';
  }

  String _planEstimateLabel(OfficialVocabularyBook book, int dailyTarget) {
    if (dailyTarget <= 0 || book.wordCount <= 0) {
      return '完成时间将在开始学习后生成';
    }
    final days = (book.wordCount / dailyTarget).ceil();
    return '预计 $days 天后完成计划';
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
                ).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
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
                  ).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
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
    const coverWidth = 64.0;
    const coverHeight = coverWidth * 1.4142;
    final wordCount = book?.wordCount ?? 0;
    final title = book?.title ?? '未选择词书';
    final subtitle = book?.subtitle ?? '';
    final showSubtitle =
        subtitle.trim().isNotEmpty && subtitle.trim() != title.trim();
    final learnedRatio = wordCount <= 0
        ? 0.0
        : (learnedCount / wordCount).clamp(0, 1).toDouble();
    final masteredRatio = wordCount <= 0
        ? 0.0
        : (masteredCount / wordCount).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCover(
                title: title,
                coverKey: book?.coverKey ?? 'mint',
                width: coverWidth,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: coverHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.14,
                          color: const Color(0xFF1A1C22),
                        ),
                      ),
                      if (showSubtitle) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF9AA2AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _BookProgressBar(
                        learnedRatio: learnedRatio,
                        masteredRatio: masteredRatio,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ProgressLegend(
                            color: const Color(0xFFFFC91C),
                            label: '掌握 $masteredCount',
                          ),
                          const SizedBox(width: 12),
                          _ProgressLegend(
                            color: const Color(0xFFFFE08A),
                            label: '已学 $learnedCount',
                          ),
                          const Spacer(),
                          Text(
                            '$wordCount词',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF7F8793),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFFFC91C),
                backgroundColor: Color(0xFFF0F1F4),
              ),
            )
          else
            const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _BookActionButton(
                  icon: Icons.article_outlined,
                  label: '查看词表',
                  onTap: onOpenWordList,
                ),
              ),
              const _ActionDivider(),
              Expanded(
                child: _BookActionButton(
                  icon: Icons.restart_alt_rounded,
                  label: '重置词书',
                  onTap: onReset,
                ),
              ),
              const _ActionDivider(),
              Expanded(
                child: _BookActionButton(
                  icon: Icons.autorenew_rounded,
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

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1E25),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _SettingActionRow extends StatelessWidget {
  const _SettingActionRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF20232A),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                color: const Color(0xFFA4ACB8),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFFB6BDC8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF20232A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF9FA7B5),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFFFD13F),
            inactiveTrackColor: const Color(0xFFD9DEE6),
            thumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _BookActionButton extends StatelessWidget {
  const _BookActionButton({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: enabled
                  ? const Color(0xFF96A0AD)
                  : const Color(0xFFD0D5DD),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: enabled
                      ? const Color(0xFF96A0AD)
                      : const Color(0xFFD0D5DD),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: const Color(0xFFE8EBF0),
    );
  }
}

class _BookProgressBar extends StatelessWidget {
  const _BookProgressBar({
    required this.learnedRatio,
    required this.masteredRatio,
  });

  final double learnedRatio;
  final double masteredRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final learnedWidth = constraints.maxWidth * learnedRatio;
            final masteredWidth = constraints.maxWidth * masteredRatio;
            return Stack(
              children: [
                Container(color: const Color(0xFFF0F1F4)),
                if (learnedWidth > 0)
                  Container(
                    width: learnedWidth,
                    color: const Color(0xFFFFE08A),
                  ),
                if (masteredWidth > 0)
                  Container(
                    width: masteredWidth,
                    color: const Color(0xFFFFC91C),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: const Color(0xFF7F8793),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BookBadgeSpec {
  const _BookBadgeSpec({
    required this.acronym,
    required this.tag,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String acronym;
  final String tag;
  final Color backgroundColor;
  final Color accentColor;
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.title,
    required this.coverKey,
    required this.width,
  });

  final String title;
  final String coverKey;
  final double width;

  @override
  Widget build(BuildContext context) {
    final spec = _coverSpec(title, coverKey);
    const a4Ratio = 1.4142;
    final height = width * a4Ratio;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 7),
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            left: width * 0.44,
            top: height * 0.48,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: width * 0.28,
                height: 8,
                decoration: BoxDecoration(
                  color: spec.accentColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -1,
            child: SizedBox(
              width: width * 0.72,
              height: height * 0.42,
              child: CustomPaint(
                painter: _BookCoverPatternPainter(color: spec.accentColor),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    spec.acronym,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  spec.tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: spec.backgroundColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _BookBadgeSpec _coverSpec(String title, String coverKey) {
    final normalizedTitle = title.toUpperCase();
    if (normalizedTitle.contains('专八')) {
      return const _BookBadgeSpec(
        acronym: 'TEM-8',
        tag: '乱序版',
        backgroundColor: Color(0xFF97DB00),
        accentColor: Color(0xFF5FA800),
      );
    }
    if (normalizedTitle.contains('专四')) {
      return const _BookBadgeSpec(
        acronym: 'TEM-4',
        tag: '词汇书',
        backgroundColor: Color(0xFF5DC671),
        accentColor: Color(0xFF2F8E43),
      );
    }
    if (normalizedTitle.contains('CET-6') || normalizedTitle.contains('六级')) {
      return const _BookBadgeSpec(
        acronym: 'CET-6',
        tag: '词汇书',
        backgroundColor: Color(0xFFFFB84E),
        accentColor: Color(0xFFD78400),
      );
    }
    if (normalizedTitle.contains('CET-4') || normalizedTitle.contains('四级')) {
      return const _BookBadgeSpec(
        acronym: 'CET-4',
        tag: '词汇书',
        backgroundColor: Color(0xFF47C2FF),
        accentColor: Color(0xFF1587BE),
      );
    }
    if (normalizedTitle.contains('IELTS')) {
      return const _BookBadgeSpec(
        acronym: 'IELTS',
        tag: '乱序版',
        backgroundColor: Color(0xFFFFC66D),
        accentColor: Color(0xFFCE8D1E),
      );
    }
    if (normalizedTitle.contains('TOEFL')) {
      return const _BookBadgeSpec(
        acronym: 'TOEFL',
        tag: '词汇书',
        backgroundColor: Color(0xFF6EC5FF),
        accentColor: Color(0xFF2B81BC),
      );
    }
    final fallback = switch (coverKey) {
      'amber' => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFFFFC66D),
        accentColor: Color(0xFFCE8D1E),
      ),
      'violet' => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFFAE9CFF),
        accentColor: Color(0xFF6952D4),
      ),
      'sky' => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFF63C7FF),
        accentColor: Color(0xFF228BC4),
      ),
      'rose' => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFFFF8AA7),
        accentColor: Color(0xFFD84E73),
      ),
      'ocean' => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFF5DBBC4),
        accentColor: Color(0xFF2C7F86),
      ),
      'graphite' => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFF93A1B2),
        accentColor: Color(0xFF5F6B7A),
      ),
      _ => const _BookBadgeSpec(
        acronym: 'WORDS',
        tag: '词汇书',
        backgroundColor: Color(0xFF97DB00),
        accentColor: Color(0xFF5FA800),
      ),
    };
    return fallback;
  }
}

class _BookCoverPatternPainter extends CustomPainter {
  const _BookCoverPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.22)
      ..lineTo(size.width * 0.34, size.height * 0.42)
      ..lineTo(size.width * 0.57, size.height * 0.12)
      ..lineTo(size.width * 0.83, size.height * 0.41)
      ..lineTo(size.width * 1.04, size.height * 0.2)
      ..lineTo(size.width * 1.16, size.height * 0.36);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BookCoverPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
