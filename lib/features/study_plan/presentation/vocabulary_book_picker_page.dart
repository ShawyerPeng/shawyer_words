import 'package:flutter/material.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/domain/official_vocabulary_book.dart';
import 'package:shawyer_words/features/study_plan/domain/study_plan_models.dart';

class VocabularyBookPickerPage extends StatefulWidget {
  const VocabularyBookPickerPage({super.key, required this.controller});

  final StudyPlanController controller;

  @override
  State<VocabularyBookPickerPage> createState() =>
      _VocabularyBookPickerPageState();
}

class _VocabularyBookPickerPageState extends State<VocabularyBookPickerPage> {
  static const String _myTab = '我的';
  String _selectedTab = _myTab;
  String _query = '';

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
              StudyPlanStatus.ready => _buildReadyContent(context, state),
            },
          ),
        );
      },
    );
  }

  Widget _buildReadyContent(BuildContext context, StudyPlanState state) {
    final tabs = <String>[_myTab, ...state.categories];
    if (!tabs.contains(_selectedTab)) {
      _selectedTab = _myTab;
    }

    final normalizedQuery = _query.trim().toLowerCase();
    final visibleNotebooks = state.notebooks
        .where((notebook) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return notebook.name.toLowerCase().contains(normalizedQuery) ||
              notebook.description.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    final visibleBooks = state.officialBooks
        .where((book) {
          final matchesCategory = book.category == _selectedTab;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              book.title.toLowerCase().contains(normalizedQuery) ||
              book.subtitle.toLowerCase().contains(normalizedQuery);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);

    return Padding(
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
                widget.controller.updateQuery(value);
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: _SearchPrefixIcon(),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 52,
                  minHeight: 24,
                ),
                hintText: '搜索',
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final selected = tab == _selectedTab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = tab;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tab,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            child: _selectedTab == _myTab
                ? _NotebookSection(
                    notebooks: visibleNotebooks,
                    onSelectNotebook: (notebookId) async {
                      final success = await widget.controller.selectNotebook(
                        notebookId,
                      );
                      if (!context.mounted || !success) {
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                  )
                : ListView.separated(
                    itemCount: visibleBooks.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 108,
                      color: Color(0xFFE8ECF2),
                    ),
                    itemBuilder: (context, index) {
                      final book = visibleBooks[index];
                      return _PickerBookTile(
                        book: book,
                        downloadState:
                            state.downloadStates[book.id] ??
                            const VocabularyDownloadState.idle(),
                        onSelect: () async {
                          if (book.isRemote && book.entries.isEmpty) {
                            return;
                          }
                          final shouldPop = await widget.controller.selectBook(
                            book.id,
                          );
                          if (!context.mounted || !shouldPop) {
                            return;
                          }
                          if (context.mounted &&
                              Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        onDownload: book.isRemote
                            ? () => widget.controller.downloadBook(book.id)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotebookSection extends StatelessWidget {
  const _NotebookSection({
    required this.notebooks,
    required this.onSelectNotebook,
  });

  final List<VocabularyNotebook> notebooks;
  final Future<void> Function(String notebookId) onSelectNotebook;

  @override
  Widget build(BuildContext context) {
    if (notebooks.isEmpty) {
      return const Center(
        child: Text(
          '还没有生词本',
          style: TextStyle(color: Color(0xFF8D97A7), fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      itemCount: notebooks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final notebook = notebooks[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelectNotebook(notebook.id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notebook.description.isEmpty
                            ? (notebook.isDefault ? '默认生词本' : '自定义生词本')
                            : notebook.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF8D97A7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA2B2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PickerBookTile extends StatelessWidget {
  const _PickerBookTile({
    required this.book,
    required this.downloadState,
    required this.onSelect,
    this.onDownload,
  });

  final OfficialVocabularyBook book;
  final VocabularyDownloadState downloadState;
  final Future<void> Function() onSelect;
  final Future<bool> Function()? onDownload;

  @override
  Widget build(BuildContext context) {
    final isDownloaded = !book.isRemote || book.entries.isNotEmpty;
    final isDownloading =
        downloadState.status == VocabularyDownloadStatus.downloading;
    final hasFailed = downloadState.status == VocabularyDownloadStatus.failure;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        book.subtitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: const Color(0xFF9AA2B2)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
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
                          if (book.isRemote) ...[
                            const SizedBox(width: 12),
                            _DownloadButton(
                              key: ValueKey('download-${book.id}'),
                              status: downloadState.status,
                              isDownloaded: isDownloaded,
                              onPressed: onDownload,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (book.isRemote &&
                (isDownloading || hasFailed || isDownloaded)) ...[
              const SizedBox(height: 12),
              _DownloadProgressSection(
                status: downloadState.status,
                progress: isDownloaded ? 1 : downloadState.progress,
                message: isDownloaded
                    ? '已下载'
                    : (downloadState.message ?? (hasFailed ? '下载失败' : '正在下载')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    super.key,
    required this.status,
    required this.isDownloaded,
    this.onPressed,
  });

  final VocabularyDownloadStatus status;
  final bool isDownloaded;
  final Future<bool> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDownloading = status == VocabularyDownloadStatus.downloading;
    final isFailure = status == VocabularyDownloadStatus.failure;
    final label = isDownloaded
        ? '已下载'
        : (isDownloading ? '下载中' : (isFailure ? '重试' : '下载'));

    return OutlinedButton(
      onPressed: isDownloaded || isDownloading || onPressed == null
          ? null
          : () => onPressed!(),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(74, 34),
        foregroundColor: isDownloaded
            ? const Color(0xFF0C8B64)
            : const Color(0xFF10C28E),
        side: BorderSide(
          color: isDownloaded
              ? const Color(0xFF9CDEC3)
              : const Color(0xFF10C28E),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label),
    );
  }
}

class _DownloadProgressSection extends StatelessWidget {
  const _DownloadProgressSection({
    required this.status,
    required this.progress,
    required this.message,
  });

  final VocabularyDownloadStatus status;
  final double? progress;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VocabularyDownloadStatus.failure => const Color(0xFFB9382F),
      _ => const Color(0xFF0C8B64),
    };
    final background = switch (status) {
      VocabularyDownloadStatus.failure => const Color(0xFFFFF1F0),
      _ => const Color(0xFFEAF8F2),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPrefixIcon extends StatelessWidget {
  const _SearchPrefixIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Icon(
              Icons.search_rounded,
              size: 24,
              color: Color(0xFF111827),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF10C28E),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
