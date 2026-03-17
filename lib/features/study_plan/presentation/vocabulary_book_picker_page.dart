import 'package:flutter/material.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';

class VocabularyBookPickerPage extends StatefulWidget {
  const VocabularyBookPickerPage({super.key, required this.controller});

  final StudyPlanController controller;

  @override
  State<VocabularyBookPickerPage> createState() =>
      _VocabularyBookPickerPageState();
}

class _VocabularyBookPickerPageState extends State<VocabularyBookPickerPage> {
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
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: SafeArea(
            child: switch (state.status) {
              StudyPlanStatus.initial || StudyPlanStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              StudyPlanStatus.failure => Center(
                child: Text(state.errorMessage ?? '词汇表加载失败'),
              ),
              StudyPlanStatus.ready => Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            '单词本',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        onChanged: widget.controller.updateQuery,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: '搜索',
                          contentPadding: EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    if (state.importStatus != VocabularyImportStatus.idle) ...[
                      const SizedBox(height: 14),
                      _ImportStatusBanner(
                        status: state.importStatus,
                        message: state.importMessage ?? '',
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final category = state.categories[index];
                          final selected = category == state.selectedCategory;
                          return GestureDetector(
                            onTap: () =>
                                widget.controller.selectCategory(category),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? const Color(0xFF151B2C)
                                            : const Color(0xFF9AA2B2),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 20,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF10C28E)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.visibleBooks.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 108,
                          color: Color(0xFFE8ECF2),
                        ),
                        itemBuilder: (context, index) {
                          final book = state.visibleBooks[index];
                          return _PickerBookTile(
                            book: book,
                            onTap: () async {
                              final shouldPop = await widget.controller
                                  .selectBook(book.id);
                              if (!context.mounted || !shouldPop) {
                                return;
                              }
                              if (book.isRemote) {
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 600),
                                );
                              }
                              if (context.mounted &&
                                  Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

class _ImportStatusBanner extends StatelessWidget {
  const _ImportStatusBanner({required this.status, required this.message});

  final VocabularyImportStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor, icon) = switch (status) {
      VocabularyImportStatus.importing => (
        const Color(0xFFEAF8F2),
        const Color(0xFF0C8B64),
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      VocabularyImportStatus.success => (
        const Color(0xFFEAF8F2),
        const Color(0xFF0C8B64),
        const Icon(Icons.check_circle_rounded, size: 18),
      ),
      VocabularyImportStatus.failure => (
        const Color(0xFFFFF1F0),
        const Color(0xFFB9382F),
        const Icon(Icons.error_rounded, size: 18),
      ),
      VocabularyImportStatus.idle => (
        Colors.transparent,
        Colors.transparent,
        const SizedBox.shrink(),
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(color: foregroundColor),
            child: DefaultTextStyle(
              style: TextStyle(color: foregroundColor),
              child: icon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerBookTile extends StatelessWidget {
  const _PickerBookTile({required this.book, required this.onTap});

  final OfficialVocabularyBook book;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF6E6B5), Color(0xFFBFEFDB)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                book.title.replaceAll('乱序完整版', '').split(' ').first,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10C28E),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    book.subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF9AA2B2),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      ),
    );
  }
}
