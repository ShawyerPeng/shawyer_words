import 'package:flutter/material.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/study_session_page.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';
import 'package:shawyer_words/features/study_plan/presentation/vocabulary_book_picker_page.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class StudyHomePage extends StatefulWidget {
  const StudyHomePage({
    super.key,
    required this.controller,
    required this.studyRepository,
    required this.wordDetailPageBuilder,
  });

  final StudyPlanController controller;
  final StudyRepository studyRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  State<StudyHomePage> createState() => _StudyHomePageState();
}

class _StudyHomePageState extends State<StudyHomePage> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.state.status == StudyPlanStatus.initial) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
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
              studyRepository: widget.studyRepository,
              wordDetailPageBuilder: widget.wordDetailPageBuilder,
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
    required this.studyRepository,
    required this.wordDetailPageBuilder,
  });

  final StudyPlanController controller;
  final StudyRepository studyRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StudyHeaderCard(
            currentBook: state.currentBook,
            newCount: state.newCount,
            reviewCount: state.reviewCount,
            masteredCount: state.masteredCount,
            remainingCount: state.remainingCount,
            onStart: state.currentBook == null
                ? null
                : () => _openStudySession(context, state.currentBook!),
            onChangeBook: () => _openBookPicker(context),
          ),
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
              Text(
                '我的词汇表',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.arrow_drop_down_rounded),
              const Spacer(),
              Icon(Icons.more_vert_rounded, color: const Color(0xFF99A1B2)),
            ],
          ),
          const SizedBox(height: 18),
          if (state.myBooks.isEmpty)
            _MyBooksEmptyCard(onImport: () => _openBookPicker(context))
          else
            ...state.myBooks.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MyBookRow(
                  book: book,
                  isCurrent: state.currentBook?.id == book.id,
                  onTap: () => controller.selectBook(book.id),
                ),
              ),
            ),
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

  Future<void> _openStudySession(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudySessionPage.forBook(
          entries: book.entries,
          studyRepository: studyRepository,
          wordDetailPageBuilder: wordDetailPageBuilder,
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
  });

  final OfficialVocabularyBook? currentBook;
  final int newCount;
  final int reviewCount;
  final int masteredCount;
  final int remainingCount;
  final VoidCallback? onStart;
  final VoidCallback onChangeBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D1A33),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
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
                      size: 98,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentBook!.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: onChangeBook,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10C28E),
                              side: const BorderSide(color: Color(0xFFD8F1E8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('更改'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: remainingCount == 0
                        ? 0
                        : masteredCount / remainingCount,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE9EBF0),
                    color: const Color(0xFF10C28E),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '复习中 $reviewCount   已掌握 $masteredCount   未学 $remainingCount / ${currentBook!.wordCount}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF99A1B2),
                  ),
                ),
                const SizedBox(height: 22),
                const Divider(height: 1, color: Color(0xFFF0F2F6)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(value: '$newCount', label: '待学习'),
                    ),
                    Expanded(
                      child: _MetricBlock(value: '$reviewCount', label: '待复习'),
                    ),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10C28E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('开始'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

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

class _WeekProgressCard extends StatelessWidget {
  const _WeekProgressCard({required this.days});

  final List<StudyCalendarDay> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D1A33),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
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

class _MyBookRow extends StatelessWidget {
  const _MyBookRow({
    required this.book,
    required this.isCurrent,
    required this.onTap,
  });

  final OfficialVocabularyBook book;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              _BookCover(title: book.title, coverKey: book.coverKey, size: 78),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF97A0B2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FBF3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${book.wordCount}词',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF10C28E),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FBF3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '当前计划',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF10C28E),
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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF10C28E),
        ),
      ),
    );
  }
}
