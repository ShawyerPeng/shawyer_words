import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';

class DictionaryImportSessionLayer extends StatelessWidget {
  const DictionaryImportSessionLayer({
    super.key,
    required this.session,
    required this.scrollController,
    required this.metadataExpanded,
    required this.filesExpanded,
    required this.searchQuery,
    required this.paginationAnchorPage,
    required this.onToggleMetadata,
    required this.onToggleFiles,
    required this.onBack,
    required this.onClose,
    required this.onAddFile,
    required this.onPreview,
    required this.onInstall,
    required this.onSelectEntry,
    required this.onLoadEntryDetail,
    required this.onSearchChanged,
    required this.onShowPreviousGroup,
    required this.onShowNextGroup,
    required this.onSelectPage,
    this.showPickerOverlay = true,
  });

  final DictionaryImportSession session;
  final ScrollController scrollController;
  final bool metadataExpanded;
  final bool filesExpanded;
  final String searchQuery;
  final int paginationAnchorPage;
  final VoidCallback onToggleMetadata;
  final VoidCallback onToggleFiles;
  final VoidCallback onBack;
  final Future<void> Function() onClose;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onPreview;
  final Future<void> Function() onInstall;
  final Future<void> Function(WordEntry entry) onSelectEntry;
  final Future<WordEntry?> Function(String key) onLoadEntryDetail;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onShowPreviousGroup;
  final VoidCallback onShowNextGroup;
  final Future<void> Function(int pageNumber) onSelectPage;
  final bool showPickerOverlay;

  @override
  Widget build(BuildContext context) {
    if (!session.isOpen) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (showPickerOverlay)
          _ImportOverlay(
            showAddButton:
                session.stage == DictionaryImportSessionStage.pickerOverlay,
            onAddFile: onAddFile,
            onClose: onClose,
          ),
        if (session.stage == DictionaryImportSessionStage.confirming ||
            session.stage == DictionaryImportSessionStage.installing)
          Center(
            child: _ConfirmImportCard(
              session: session,
              onAddFile: onAddFile,
              onPreview: onPreview,
              onInstall: onInstall,
            ),
          ),
        if (session.stage == DictionaryImportSessionStage.previewing &&
            session.preview != null &&
            session.previewPage != null)
          _PreviewPanel(
            session: session,
            scrollController: scrollController,
            metadataExpanded: metadataExpanded,
            filesExpanded: filesExpanded,
            searchQuery: searchQuery,
            paginationAnchorPage: paginationAnchorPage,
            onToggleMetadata: onToggleMetadata,
            onToggleFiles: onToggleFiles,
            onBack: onBack,
            onClose: onClose,
            onAddFile: onAddFile,
            onInstall: onInstall,
            onSelectEntry: onSelectEntry,
            onLoadEntryDetail: onLoadEntryDetail,
            onSearchChanged: onSearchChanged,
            onShowPreviousGroup: onShowPreviousGroup,
            onShowNextGroup: onShowNextGroup,
            onSelectPage: onSelectPage,
          ),
        if (session.stage == DictionaryImportSessionStage.failure)
          Center(
            child: _ImportErrorCard(
              errorMessage: session.errorMessage ?? '词库预览失败，请重新选择文件。',
              onAddFile: onAddFile,
              onClose: onClose,
            ),
          ),
      ],
    );
  }
}

class _ImportOverlay extends StatelessWidget {
  const _ImportOverlay({
    required this.showAddButton,
    required this.onAddFile,
    required this.onClose,
  });

  final bool showAddButton;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        key: const ValueKey('dictionary-import-overlay'),
        color: const Color(0xCC0F1524),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showAddButton)
                      TextButton(
                        onPressed: onAddFile,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('添加文件'),
                      ),
                    IconButton(
                      onPressed: onClose,
                      color: Colors.white,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      FilledButton.tonal(
                        key: const ValueKey(
                          'dictionary-import-overlay-trigger',
                        ),
                        onPressed: onAddFile,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D2A46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Icon(Icons.add_rounded, size: 40),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '请选择词典主文件和关联资源文件',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '取消系统选择后，可点击图标或右上角按钮重新打开 iOS 文件选择窗口。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD4D9E6),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmImportCard extends StatelessWidget {
  const _ConfirmImportCard({
    required this.session,
    required this.onAddFile,
    required this.onPreview,
    required this.onInstall,
  });

  final DictionaryImportSession session;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onPreview;
  final Future<void> Function() onInstall;

  @override
  Widget build(BuildContext context) {
    final preview = session.preview;
    final theme = Theme.of(context);
    if (preview == null) {
      return const SizedBox.shrink();
    }
    final primaryFile = preview.files.cast<DictionaryPreviewFile?>().firstWhere(
      (file) => file?.isPrimary ?? false,
      orElse: () => preview.files.isEmpty ? null : preview.files.first,
    );
    final relatedFiles = [
      for (final file in preview.files)
        if (primaryFile == null || file.path != primaryFile.path) file,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: Colors.white,
        elevation: 24,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '确认导入',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onAddFile,
                    child: const Text('继续添加文件'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '主文件',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _PreviewFileChip(
                fileName: primaryFile?.name ?? '未识别主词典文件',
                emphasized: true,
              ),
              if (relatedFiles.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  '关联文件',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final file in relatedFiles)
                      _PreviewFileChip(fileName: file.name),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onPreview,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F8),
                        foregroundColor: const Color(0xFF343840),
                        elevation: 0,
                      ),
                      child: const Text('预览'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onInstall,
                      child: const Text('安装'),
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

class _PreviewFileChip extends StatelessWidget {
  const _PreviewFileChip({required this.fileName, this.emphasized = false});

  final String fileName;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFEAF3FF) : const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        fileName,
        style: TextStyle(
          color: emphasized ? const Color(0xFF295EA8) : const Color(0xFF566074),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImportErrorCard extends StatelessWidget {
  const _ImportErrorCard({
    required this.errorMessage,
    required this.onAddFile,
    required this.onClose,
  });

  final String errorMessage;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: Colors.white,
        elevation: 24,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF60697D),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      child: const Text('关闭'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAddFile,
                      child: const Text('重新选择'),
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

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.session,
    required this.scrollController,
    required this.metadataExpanded,
    required this.filesExpanded,
    required this.searchQuery,
    required this.paginationAnchorPage,
    required this.onToggleMetadata,
    required this.onToggleFiles,
    required this.onBack,
    required this.onClose,
    required this.onAddFile,
    required this.onInstall,
    required this.onSelectEntry,
    required this.onLoadEntryDetail,
    required this.onSearchChanged,
    required this.onShowPreviousGroup,
    required this.onShowNextGroup,
    required this.onSelectPage,
  });

  final DictionaryImportSession session;
  final ScrollController scrollController;
  final bool metadataExpanded;
  final bool filesExpanded;
  final String searchQuery;
  final int paginationAnchorPage;
  final VoidCallback onToggleMetadata;
  final VoidCallback onToggleFiles;
  final VoidCallback onBack;
  final Future<void> Function() onClose;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onInstall;
  final Future<void> Function(WordEntry entry) onSelectEntry;
  final Future<WordEntry?> Function(String key) onLoadEntryDetail;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onShowPreviousGroup;
  final VoidCallback onShowNextGroup;
  final Future<void> Function(int pageNumber) onSelectPage;

  @override
  Widget build(BuildContext context) {
    final preview = session.preview!;
    final page = session.previewPage!;
    final groupedPages = preview.pageNumbersForGroup(paginationAnchorPage);
    final searchResults = preview.searchEntryKeysByPrefix(searchQuery);
    final metadataHtml = preview.metadataDescriptionHtml;
    final metadataPreviewHtml = metadataHtml.length <= 240
        ? metadataHtml
        : '${metadataHtml.substring(0, 240)}...';
    final isCompactHeader = MediaQuery.sizeOf(context).width < 720;
    final metadataText = metadataExpanded ? metadataHtml : metadataPreviewHtml;
    final resultCountLabel = searchQuery.trim().isEmpty
        ? '第 ${page.pageNumber} / ${preview.totalPages} 页'
        : '搜索结果 ${searchResults.length} 项';

    return Material(
      color: const Color(0xCC0F1524),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            children: [
              if (isCompactHeader) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: onBack,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          preview.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onClose,
                      color: Colors.white,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: onAddFile,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('继续添加文件'),
                      ),
                      FilledButton(
                        onPressed: onInstall,
                        child: const Text('安装'),
                      ),
                    ],
                  ),
                ),
              ] else
                Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preview.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onAddFile,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('继续添加文件'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onInstall,
                      child: const Text('安装'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onClose,
                      color: Colors.white,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: NestedScrollView(
                      key: const ValueKey('dictionary-preview-scroll-view'),
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(
                            child: _PreviewSectionCard(
                              title: '词典元信息',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SimpleHtmlText(
                                    html: metadataText.isEmpty
                                        ? '未提供词典描述。'
                                        : metadataText,
                                  ),
                                  if (metadataHtml.length >
                                      metadataPreviewHtml.length)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: onToggleMetadata,
                                        child: Text(
                                          metadataExpanded ? '收起' : '更多',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: _ExpandablePreviewCard(
                              title: '文件信息',
                              expanded: filesExpanded,
                              onToggle: onToggleFiles,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final file in preview.files)
                                    _PreviewFileChip(
                                      fileName: file.name,
                                      emphasized: file.isPrimary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _PreviewHeaderDelegate(
                              minExtent: 170,
                              maxExtent: 170,
                              child: Container(
                                color: const Color(0xFFF7F9FC),
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '所有词条',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        key: const ValueKey(
                                          'dictionary-preview-search-field',
                                        ),
                                        onChanged: onSearchChanged,
                                        decoration: InputDecoration(
                                          hintText: '搜索整本词典的前缀词条',
                                          isDense: true,
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                          ),
                                          suffixIcon:
                                              searchQuery.trim().isEmpty
                                              ? null
                                              : IconButton(
                                                  onPressed: () =>
                                                      onSearchChanged(''),
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                  ),
                                                ),
                                          filled: true,
                                          fillColor: const Color(0xFFF5F7FB),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ];
                      },
                      body: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        color: const Color(0xFFF7F9FC),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  12,
                                ),
                                child: Text(
                                  resultCountLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF556075),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: CustomScrollView(
                                  controller: scrollController,
                                  slivers: [
                                    SliverList.builder(
                                      itemCount: searchQuery.trim().isEmpty
                                          ? page.entries.length
                                          : searchResults.length,
                                      itemBuilder: (context, index) {
                                        final entry = searchQuery.trim().isEmpty
                                            ? page.entries[index]
                                            : WordEntry(
                                                id: searchResults[index],
                                                word: searchResults[index],
                                                rawContent: '',
                                              );
                                        final ordinal =
                                            searchQuery.trim().isEmpty
                                            ? ((page.pageNumber - 1) *
                                                      preview.pageSize) +
                                                  index +
                                                  1
                                            : preview.entryKeys.indexOf(
                                                    entry.word,
                                                  ) +
                                                  1;
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            0,
                                            18,
                                            10,
                                          ),
                                          child: _PreviewEntryTile(
                                            entry: entry,
                                            ordinal: ordinal,
                                            onTap: () => onSelectEntry(entry),
                                            onOpenDetail: () async {
                                              final detailEntry =
                                                  await onLoadEntryDetail(
                                                    entry.word,
                                                  );
                                              if (!context.mounted ||
                                                  detailEntry == null) {
                                                return;
                                              }
                                              await showDialog<void>(
                                                context: context,
                                                builder: (dialogContext) {
                                                  return _PreviewEntryDetailDialog(
                                                    entry: detailEntry,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                    if (searchQuery.trim().isEmpty)
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            6,
                                            12,
                                            12,
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                key: const ValueKey(
                                                  'dictionary-preview-previous-group',
                                                ),
                                                onPressed:
                                                    onShowPreviousGroup,
                                                icon: const Icon(
                                                  Icons.chevron_left_rounded,
                                                ),
                                              ),
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    for (final pageNumber
                                                        in groupedPages)
                                                      InkWell(
                                                        key: ValueKey(
                                                          'dictionary-preview-page-$pageNumber',
                                                        ),
                                                        onTap: () =>
                                                            onSelectPage(
                                                              pageNumber,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        child: Container(
                                                          width: 34,
                                                          height: 34,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                pageNumber ==
                                                                    page
                                                                        .pageNumber
                                                                ? const Color(
                                                                    0xFF1E2230,
                                                                  )
                                                                : const Color(
                                                                    0xFFE9EDF5,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '$pageNumber',
                                                            style: TextStyle(
                                                              color:
                                                                  pageNumber ==
                                                                      page
                                                                          .pageNumber
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF5C667A,
                                                                    ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                key: const ValueKey(
                                                  'dictionary-preview-next-group',
                                                ),
                                                onPressed: onShowNextGroup,
                                                icon: const Icon(
                                                  Icons.chevron_right_rounded,
                                                ),
                                              ),
                                            ],
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
}

class _PreviewSectionCard extends StatelessWidget {
  const _PreviewSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ExpandablePreviewCard extends StatelessWidget {
  const _ExpandablePreviewCard({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF5C667A),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }
}

class _PreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PreviewHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PreviewHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}

class _PreviewEntryTile extends StatelessWidget {
  const _PreviewEntryTile({
    required this.entry,
    required this.ordinal,
    required this.onTap,
    required this.onOpenDetail,
  });

  final WordEntry entry;
  final int ordinal;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    '$ordinal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A93A5),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.word,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2433),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: ValueKey(
                    'dictionary-preview-entry-detail-${entry.word}',
                  ),
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  color: const Color(0xFF5F697D),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
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

class _PreviewEntryDetailDialog extends StatelessWidget {
  const _PreviewEntryDetailDialog({required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.word,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: _SimpleHtmlText(html: entry.rawContent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleHtmlText extends StatelessWidget {
  const _SimpleHtmlText({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final parsed = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(div|p|li|section|article|h\d|b)>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();

    return SelectableText(
      parsed,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF586174), height: 1.6),
    );
  }
}
