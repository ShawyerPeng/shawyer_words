import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';

class StudyTaskSettingsPage extends StatefulWidget {
  const StudyTaskSettingsPage({
    super.key,
    required this.settingsController,
    required this.book,
  });

  final SettingsController settingsController;
  final OfficialVocabularyBook book;

  @override
  State<StudyTaskSettingsPage> createState() => _StudyTaskSettingsPageState();
}

class _StudyTaskSettingsPageState extends State<StudyTaskSettingsPage> {
  static const List<int> _dailyNewOptions = <int>[
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    60,
    70,
    80,
    90,
  ];

  late int _dailyNew;
  late int _reviewRatio;

  @override
  void initState() {
    super.initState();
    final settings = widget.settingsController.state.settings;
    _dailyNew = settings.dailyStudyTarget;
    _reviewRatio = settings.dailyReviewRatio;
    if (!_dailyNewOptions.contains(_dailyNew)) {
      _dailyNew = _dailyNewOptions.contains(20) ? 20 : _dailyNewOptions.first;
    }
    _reviewRatio = _reviewRatio.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = widget.book;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBFF2E1), Color(0xFFF3F5FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '设置任务量',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                  child: Column(
                    children: [
                      _BookCard(book: book),
                      const SizedBox(height: 14),
                      _TaskSettingsCard(
                        ratioLabel: '1:$_reviewRatio',
                        estimatedFinishDate: _estimatedFinishDate(
                          book.wordCount,
                        ),
                        options: _dailyNewOptions,
                        selectedDailyNew: _dailyNew,
                        reviewRatio: _reviewRatio,
                        wordCount: book.wordCount,
                        onPickRatio: _openRatioPicker,
                        onShowRatioHint: _showRatioHint,
                        onSelectDailyNew: (value) =>
                            setState(() => _dailyNew = value),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10C28E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      '完成设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _estimatedFinishDate(int wordCount) {
    final normalizedNow = DateTime.now();
    final today = DateTime(
      normalizedNow.year,
      normalizedNow.month,
      normalizedNow.day,
    );
    final days = (wordCount / _dailyNew).ceil();
    return today.add(Duration(days: days - 1));
  }

  Future<void> _openRatioPicker() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
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
                  '新词复习比例',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (final ratio in const <int>[1, 2, 3, 4])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('1:$ratio'),
                    trailing: ratio == _reviewRatio
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10C28E),
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(ratio),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }
    setState(() => _reviewRatio = picked);
  }

  Future<void> _showRatioHint() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 160, right: 18),
            child: Material(
              color: const Color(0xE6161A25),
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    '复习词过少会导致单词复习次数不足，影响长期记忆。除非你已能熟练掌握，请谨慎选择较低比例；计划中途频繁更改比例可能会打乱复习节奏。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    await widget.settingsController.updateDailyStudyTarget(_dailyNew);
    await widget.settingsController.updateDailyReviewRatio(_reviewRatio);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final OfficialVocabularyBook book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _BookCover(title: book.title, coverKey: book.coverKey, size: 78),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFBF5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${book.wordCount}词',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF10C28E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSettingsCard extends StatefulWidget {
  const _TaskSettingsCard({
    required this.ratioLabel,
    required this.estimatedFinishDate,
    required this.options,
    required this.selectedDailyNew,
    required this.reviewRatio,
    required this.wordCount,
    required this.onPickRatio,
    required this.onShowRatioHint,
    required this.onSelectDailyNew,
  });

  final String ratioLabel;
  final DateTime estimatedFinishDate;
  final List<int> options;
  final int selectedDailyNew;
  final int reviewRatio;
  final int wordCount;
  final VoidCallback onPickRatio;
  final VoidCallback onShowRatioHint;
  final ValueChanged<int> onSelectDailyNew;

  @override
  State<_TaskSettingsCard> createState() => _TaskSettingsCardState();
}

class _TaskSettingsCardState extends State<_TaskSettingsCard> {
  static const double _itemExtent = 64;
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexOfDailyNew(widget.selectedDailyNew);
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  @override
  void didUpdateWidget(covariant _TaskSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDailyNew != widget.selectedDailyNew ||
        oldWidget.options != widget.options) {
      final nextIndex = _indexOfDailyNew(widget.selectedDailyNew);
      if (nextIndex != _selectedIndex) {
        _selectedIndex = nextIndex;
        _scrollController.jumpToItem(_selectedIndex);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _indexOfDailyNew(int dailyNew) {
    final index = widget.options.indexOf(dailyNew);
    return index < 0 ? 0 : index;
  }

  String _formatChineseDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y年$m月$d日';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA62B),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '每日学习任务量',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onPickRatio,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          '当前新词复习词比例 ${widget.ratioLabel}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6F778A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 18,
                          color: Color(0xFF6F778A),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.onShowRatioHint,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: Color(0xFFB0B7C8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFBF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '预计完成  ${_formatChineseDate(widget.estimatedFinishDate)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF10C28E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 340,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    physics: const FixedExtentScrollPhysics(),
                    itemExtent: _itemExtent,
                    overAndUnderCenterOpacity: 0.45,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedIndex = index);
                      widget.onSelectDailyNew(widget.options[index]);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.options.length,
                      builder: (context, index) {
                        final dailyNew = widget.options[index];
                        final selected = index == _selectedIndex;
                        final reviewCount = dailyNew * widget.reviewRatio;
                        final days = (widget.wordCount / dailyNew).ceil();
                        final textColor = selected
                            ? const Color(0xFF1B2030)
                            : const Color(0xFFB0B7C8);

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  await _scrollController.animateToItem(
                                    index,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '新词  $dailyNew',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '复习  $reviewCount',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '需要  $days  天',
                                          textAlign: TextAlign.end,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 移除灰色遮罩，避免遮盖当前选中的值
                /*
                IgnorePointer(
                  child: Container(
                    height: _itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5FA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                */
              ],
            ),
          ),
        ],
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
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF10C28E),
        ),
      ),
    );
  }
}
