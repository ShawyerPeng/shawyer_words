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
  static const String _allTab = '全部';
  static const String _myTab = '我的';
  String _selectedTab = _allTab;
  String _query = '';
  final Map<String, String> _selectedTagByTab = <String, String>{};
  StudyPlanState? _lastReadyState;
  String? _preparingBookId;

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
        if (state.status == StudyPlanStatus.ready) {
          _lastReadyState = state;
        }
        final displayState =
            state.status == StudyPlanStatus.loading && _preparingBookId != null
            ? _lastReadyState
            : state.status == StudyPlanStatus.ready
            ? state
            : null;

        final body = switch (state.status) {
          StudyPlanStatus.initial => const Center(
            child: CircularProgressIndicator(),
          ),
          StudyPlanStatus.loading when displayState != null =>
            _buildReadyContent(context, displayState),
          StudyPlanStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          StudyPlanStatus.failure => Center(
            child: Text(state.errorMessage ?? '词汇表加载失败'),
          ),
          StudyPlanStatus.ready => _buildReadyContent(context, state),
        };

        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F7),
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: body),
                if (_shouldShowPreparingOverlay(state))
                  Positioned.fill(
                    child: _BookPreparingOverlay(
                      progress: _preparingProgress(state),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyContent(BuildContext context, StudyPlanState state) {
    final tabs = <String>[_allTab, _myTab, ...state.categories];
    if (!tabs.contains(_selectedTab)) {
      _selectedTab = _allTab;
    }

    final isNotebookTab = _selectedTab == _myTab;
    final normalizedQuery = _query.trim().toLowerCase();
    final booksForSelectedTab = _selectedTab == _allTab
        ? state.officialBooks
        : _selectedTab == _myTab
        ? const <OfficialVocabularyBook>[]
        : state.officialBooks
              .where((book) => book.category == _selectedTab)
              .toList(growable: false);
    final availableTags = <String>[
      _allTab,
      ...{
        for (final book in booksForSelectedTab) _bookSecondaryTag(book),
      },
    ];
    final selectedTag =
        _selectedTagByTab[_selectedTab] != null &&
            availableTags.contains(_selectedTagByTab[_selectedTab])
        ? _selectedTagByTab[_selectedTab]!
        : _allTab;
    final visibleNotebooks = state.notebooks
        .where((notebook) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return notebook.name.toLowerCase().contains(normalizedQuery) ||
              notebook.description.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    final visibleBooks = booksForSelectedTab
        .where((book) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              book.title.toLowerCase().contains(normalizedQuery) ||
              book.subtitle.toLowerCase().contains(normalizedQuery);
          final matchesTag =
              selectedTag == _allTab || _bookSecondaryTag(book) == selectedTag;
          return matchesQuery && matchesTag;
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PickerTopBar(),
          const SizedBox(height: 12),
          _PickerSearchField(
            onChanged: (value) {
              setState(() {
                _query = value;
              });
              widget.controller.updateQuery(value);
            },
          ),
          const SizedBox(height: 12),
          _PickerTabBar(
            tabs: tabs,
            selectedTab: _selectedTab,
            onSelected: (tab) {
              setState(() {
                _selectedTab = tab;
              });
            },
          ),
          if (!isNotebookTab) ...[
            const SizedBox(height: 10),
            _PickerTagBar(
              tags: availableTags,
              selectedTag: selectedTag,
              onSelected: (tag) {
                setState(() {
                  _selectedTagByTab[_selectedTab] = tag;
                });
              },
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: isNotebookTab
                ? _NotebookSection(
                    notebooks: visibleNotebooks,
                    selectedNotebookId: state.selectedNotebookId,
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
                : _OfficialBookSection(
                    books: visibleBooks,
                    downloadStates: state.downloadStates,
                    onSelectBook: (book) => _handleOfficialBookTap(context, book),
                  ),
          ),
        ],
      ),
    );
  }

  String _bookSecondaryTag(OfficialVocabularyBook book) {
    return _bookDisplayTag(book);
  }

  Future<void> _handleOfficialBookTap(
    BuildContext context,
    OfficialVocabularyBook book,
  ) async {
    if (_preparingBookId != null) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final requiresDownload = book.isRemote && book.entries.isEmpty;

    if (requiresDownload) {
      setState(() {
        _preparingBookId = book.id;
      });
      final downloaded = await widget.controller.downloadBook(book.id);
      if (!mounted) {
        return;
      }
      if (!downloaded) {
        setState(() {
          _preparingBookId = null;
        });
        _showPrepareFailed(messenger);
        return;
      }
    }

    final shouldPop = await widget.controller.selectBook(book.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _preparingBookId = null;
    });

    if (!shouldPop) {
      if (requiresDownload) {
        _showPrepareFailed(messenger);
      }
      return;
    }

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  bool _shouldShowPreparingOverlay(StudyPlanState state) {
    final bookId = _preparingBookId;
    if (bookId == null) {
      return false;
    }
    final downloadState = state.downloadStates[bookId];
    if (downloadState == null) {
      return true;
    }
    return downloadState.status != VocabularyDownloadStatus.failure;
  }

  int _preparingProgress(StudyPlanState state) {
    final bookId = _preparingBookId;
    if (bookId == null) {
      return 0;
    }
    final downloadState = state.downloadStates[bookId];
    if (downloadState?.status == VocabularyDownloadStatus.downloaded) {
      return 100;
    }
    final progress = downloadState?.progress;
    if (progress == null) {
      return 0;
    }
    return (progress * 100).round().clamp(0, 100);
  }

  void _showPrepareFailed(ScaffoldMessengerState messenger) {
    final message = widget.controller.state.importMessage ?? '词书准备失败';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PickerTopBar extends StatelessWidget {
  const _PickerTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Color(0xFF1F232B),
              ),
            ),
          ),
        ),
        const Expanded(
          child: Text(
            '单词本',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171A20),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _PickerSearchField extends StatelessWidget {
  const _PickerSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: _SearchPrefixIcon(),
          prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 18),
          hintText: '搜索词书或生词本',
          hintStyle: TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _PickerTabBar extends StatelessWidget {
  const _PickerTabBar({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E8ED)),
          ),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final selected = tab == selectedTab;
              return GestureDetector(
                onTap: () => onSelected(tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected
                            ? const Color(0xFF171A20)
                            : const Color(0xFFA1A8B4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 18,
                      height: 2.5,
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
        ],
      ),
    );
  }
}

class _PickerTagBar extends StatelessWidget {
  const _PickerTagBar({
    required this.tags,
    required this.selectedTag,
    required this.onSelected,
  });

  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tag = tags[index];
          final selected = tag == selectedTag;
          return GestureDetector(
            onTap: () => onSelected(tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF10C28E)
                    : const Color(0xFFEAECF0),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                tag,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF868D98),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotebookSection extends StatelessWidget {
  const _NotebookSection({
    required this.notebooks,
    required this.selectedNotebookId,
    required this.onSelectNotebook,
  });

  final List<VocabularyNotebook> notebooks;
  final String? selectedNotebookId;
  final Future<void> Function(String notebookId) onSelectNotebook;

  @override
  Widget build(BuildContext context) {
    if (notebooks.isEmpty) {
      return const _PickerEmptyCard(
        icon: Icons.menu_book_outlined,
        title: '还没有生词本',
        subtitle: '你可以先从词书列表里导入单词，之后会在这里统一管理。',
      );
    }

    return ListView.separated(
      itemCount: notebooks.length,
      padding: const EdgeInsets.only(bottom: 4),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notebook = notebooks[index];
        return _NotebookCard(
          key: ValueKey('notebook-card-${notebook.id}'),
          notebook: notebook,
          selected: notebook.id == selectedNotebookId,
          onTap: () => onSelectNotebook(notebook.id),
        );
      },
    );
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({
    super.key,
    required this.notebook,
    required this.selected,
    required this.onTap,
  });

  final VocabularyNotebook notebook;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = notebook.description.isEmpty
        ? (notebook.isDefault ? '默认生词本' : '自定义生词本')
        : notebook.description;

    return Material(
      color: selected ? const Color(0xFFF6FBF8) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xFFBDE5D5)
                  : const Color(0xFFEAEDEF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _NotebookCoverIcon(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notebook.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1F26),
                                ),
                          ),
                        ),
                        if (notebook.isDefault)
                          const _MetaChip(
                            label: '默认',
                            foregroundColor: Color(0xFF0B8B63),
                            backgroundColor: Color(0xFFEAF8F2),
                          ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          const _MetaChip(
                            label: '当前',
                            foregroundColor: Color(0xFF785200),
                            backgroundColor: Color(0xFFFFF0C2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF8D96A4),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        _CountBadge(count: notebook.wordCount),
                        const SizedBox(width: 8),
                        _MetaChip(
                          label: notebook.isDefault ? '系统词本' : '自定义',
                          foregroundColor: const Color(0xFF7D8794),
                          backgroundColor: const Color(0xFFF4F6F8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEEF8F3)
                      : const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: selected
                      ? const Color(0xFF10A874)
                      : const Color(0xFF9AA2B2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookCoverIcon extends StatelessWidget {
  const _NotebookCoverIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 74,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? const <Color>[Color(0xFF96E2C5), Color(0xFF5BBE99)]
              : const <Color>[Color(0xFFE9F7F1), Color(0xFFD6F0E5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            bottom: -2,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 38,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Center(
            child: Text(
              'NOTE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF148C67),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count 词',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3575A9),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _OfficialBookSection extends StatelessWidget {
  const _OfficialBookSection({
    required this.books,
    required this.downloadStates,
    required this.onSelectBook,
  });

  final List<OfficialVocabularyBook> books;
  final Map<String, VocabularyDownloadState> downloadStates;
  final Future<void> Function(OfficialVocabularyBook book) onSelectBook;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const _PickerEmptyCard(
        icon: Icons.search_off_rounded,
        title: '没有找到匹配词书',
        subtitle: '试试切换分类，或使用更短的关键词重新搜索。',
      );
    }

    return ListView.separated(
      itemCount: books.length,
      padding: const EdgeInsets.only(bottom: 4),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = books[index];
        return _PickerBookTile(
          key: ValueKey('book-tile-${book.id}'),
          book: book,
          downloadState:
              downloadStates[book.id] ?? const VocabularyDownloadState.idle(),
          onSelect: () => onSelectBook(book),
        );
      },
    );
  }
}

class _PickerEmptyCard extends StatelessWidget {
  const _PickerEmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF8A93A1), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C2026),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: const Color(0xFF939BA8),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerBookTile extends StatelessWidget {
  const _PickerBookTile({
    super.key,
    required this.book,
    required this.downloadState,
    required this.onSelect,
  });

  final OfficialVocabularyBook book;
  final VocabularyDownloadState downloadState;
  final Future<void> Function() onSelect;

  @override
  Widget build(BuildContext context) {
    final isDownloaded = !book.isRemote || book.entries.isNotEmpty;
    final isPreparing =
        downloadState.status == VocabularyDownloadStatus.downloading;
    final hasFailed = downloadState.status == VocabularyDownloadStatus.failure;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDEF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BookCoverPanel(book: book),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1B1F26),
                                      height: 1.2,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF9AA2B2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          book.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF8D96A4),
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _CountBadge(count: book.wordCount),
                            _MetaChip(
                              label: book.isRemote
                                  ? (isPreparing
                                        ? '准备中'
                                        : (isDownloaded ? '已下载' : '在线词书'))
                                  : '本地词书',
                              foregroundColor: isPreparing || isDownloaded
                                  ? const Color(0xFF0B8B63)
                                  : hasFailed
                                  ? const Color(0xFFB9382F)
                                  : const Color(0xFF7D8794),
                              backgroundColor: isPreparing || isDownloaded
                                  ? const Color(0xFFEAF8F2)
                                  : hasFailed
                                  ? const Color(0xFFFFF1F0)
                                  : const Color(0xFFF4F6F8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookPreparingOverlay extends StatelessWidget {
  const _BookPreparingOverlay({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: const Color(0x73000000),
        child: Center(
          child: Container(
            width: 188,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF10C28E),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '词书准备中 $progress%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171A20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCoverPanel extends StatelessWidget {
  const _BookCoverPanel({required this.book});

  final OfficialVocabularyBook book;

  @override
  Widget build(BuildContext context) {
    final acronym = _bookAcronym(book.title);
    final tag = _bookDisplayTag(book);
    final spec = _bookCoverStyleSpec(tag);
    return Container(
      width: 62,
      height: 86,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: spec.gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -4,
            child: Icon(
              Icons.menu_book_rounded,
              size: 38,
              color: spec.patternColor.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 28,
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: spec.patternColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acronym,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: spec.titleColor,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.8,
                      fontWeight: FontWeight.w800,
                      color: spec.badgeColor,
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

  String _bookAcronym(String title) {
    if (title.contains('四级') || title.contains('CET-4')) {
      return 'CET-4';
    }
    if (title.contains('六级') || title.contains('CET-6')) {
      return 'CET-6';
    }
    if (title.contains('专四')) {
      return 'TEM-4';
    }
    if (title.contains('专八')) {
      return 'TEM-8';
    }
    if (title.toUpperCase().contains('IELTS')) {
      return 'IELTS';
    }
    if (title.toUpperCase().contains('TOEFL')) {
      return 'TOEFL';
    }
    return title.replaceAll('乱序完整版', '').split(' ').first;
  }
}

class _BookCoverStyleSpec {
  const _BookCoverStyleSpec({
    required this.gradientColors,
    required this.titleColor,
    required this.badgeColor,
    required this.patternColor,
  });

  final List<Color> gradientColors;
  final Color titleColor;
  final Color badgeColor;
  final Color patternColor;
}

String _bookDisplayTag(OfficialVocabularyBook book) {
  final source = '${book.title} ${book.subtitle}';
  if (source.contains('乱序')) {
    return '乱序版';
  }
  if (source.contains('外部') || source.contains('导入')) {
    return '外部词表';
  }
  if (source.contains('大纲')) {
    return '考试大纲';
  }
  if (source.contains('进阶')) {
    return '进阶词汇';
  }
  if (source.contains('高频')) {
    return '高频词';
  }
  if (source.contains('核心')) {
    return '核心词';
  }
  if (source.contains('词库')) {
    return '词库版';
  }
  return '精选';
}

_BookCoverStyleSpec _bookCoverStyleSpec(String tag) {
  return switch (tag) {
    '乱序版' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFFFD98B), Color(0xFFEBB15A)],
      titleColor: Color(0xFF7A4C00),
      badgeColor: Color(0xFFC97E00),
      patternColor: Color(0xFFFFFFFF),
    ),
    '外部词表' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFF97E4D1), Color(0xFF58BFA2)],
      titleColor: Color(0xFF0D6751),
      badgeColor: Color(0xFF149172),
      patternColor: Color(0xFFFFFFFF),
    ),
    '考试大纲' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFFFC7A5), Color(0xFFF08C64)],
      titleColor: Color(0xFF833F1A),
      badgeColor: Color(0xFFCC6233),
      patternColor: Color(0xFFFFFFFF),
    ),
    '进阶词汇' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFD6C0FF), Color(0xFF9E82E8)],
      titleColor: Color(0xFF50308F),
      badgeColor: Color(0xFF7351C8),
      patternColor: Color(0xFFFFFFFF),
    ),
    '高频词' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFBEDBFF), Color(0xFF75AEEE)],
      titleColor: Color(0xFF29598B),
      badgeColor: Color(0xFF417EC1),
      patternColor: Color(0xFFFFFFFF),
    ),
    '词库版' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFB7EFE9), Color(0xFF70D0C5)],
      titleColor: Color(0xFF17675F),
      badgeColor: Color(0xFF219689),
      patternColor: Color(0xFFFFFFFF),
    ),
    '核心词' => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFD4F0B1), Color(0xFF98D45D)],
      titleColor: Color(0xFF416D17),
      badgeColor: Color(0xFF679F2F),
      patternColor: Color(0xFFFFFFFF),
    ),
    _ => const _BookCoverStyleSpec(
      gradientColors: <Color>[Color(0xFFF8D979), Color(0xFFB3E8D2)],
      titleColor: Color(0xFF1E5E4D),
      badgeColor: Color(0xFF206A58),
      patternColor: Color(0xFFFFFFFF),
    ),
  };
}

class _SearchPrefixIcon extends StatelessWidget {
  const _SearchPrefixIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Icon(
              Icons.search_rounded,
              size: 22,
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
