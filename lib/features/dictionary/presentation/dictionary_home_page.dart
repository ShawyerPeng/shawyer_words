import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_import_preview.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_import_session_layer.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';

class DictionaryHomePage extends StatefulWidget {
  const DictionaryHomePage({
    super.key,
    required this.controller,
    required this.pickDictionaryFile,
    this.startImportOnFirstFrame = false,
  });

  final DictionaryController controller;
  final DictionaryFilePicker pickDictionaryFile;
  final bool startImportOnFirstFrame;

  @override
  State<DictionaryHomePage> createState() => _DictionaryHomePageState();
}

class _DictionaryHomePageState extends State<DictionaryHomePage> {
  final ScrollController _previewListController = ScrollController();
  bool _isPicking = false;
  bool _isMetadataExpanded = false;
  bool _isFilesExpanded = false;
  String _previewSearchQuery = '';
  int _paginationAnchorPage = 1;

  DictionaryController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.startImportOnFirstFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _beginImportSession();
        }
      });
    }
  }

  @override
  void dispose() {
    _previewListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final session = state.importSession;
        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 140),
                child: switch (state.status) {
                  DictionaryStatus.importing
                      when session.stage ==
                          DictionaryImportSessionStage.closed =>
                    const Center(child: CircularProgressIndicator()),
                  DictionaryStatus.ready when state.currentEntry != null =>
                    _ReadyState(controller: _controller),
                  DictionaryStatus.failure => _FailureState(
                    onImport: _beginImportSession,
                    errorMessage:
                        state.errorMessage ?? 'Dictionary import failed.',
                  ),
                  _ => _EmptyState(onImport: _beginImportSession),
                },
              ),
            ),
            if (session.isOpen)
              DictionaryImportSessionLayer(
                session: session,
                scrollController: _previewListController,
                metadataExpanded: _isMetadataExpanded,
                filesExpanded: _isFilesExpanded,
                searchQuery: _previewSearchQuery,
                paginationAnchorPage: _paginationAnchorPage,
                onToggleMetadata: () {
                  setState(() {
                    _isMetadataExpanded = !_isMetadataExpanded;
                  });
                },
                onToggleFiles: () {
                  setState(() {
                    _isFilesExpanded = !_isFilesExpanded;
                  });
                },
                onBack: () {
                  _previewListController.jumpTo(0);
                  setState(() {
                    _previewSearchQuery = '';
                  });
                  _controller.returnToImportConfirmation();
                },
                onClose: () async {
                  _previewListController.jumpTo(0);
                  setState(() {
                    _previewSearchQuery = '';
                  });
                  await _controller.closeImportSession();
                },
                onAddFile: _requestImportSource,
                onPreview: () async {
                  await _controller.openImportPreview();
                  final page = _controller.state.importSession.previewPage;
                  if (page != null) {
                    setState(() {
                      _previewSearchQuery = '';
                      _paginationAnchorPage = page.pageNumber;
                    });
                  }
                },
                onInstall: _controller.installImport,
                onSelectEntry: (entry) async {
                  _controller.selectPreviewEntry(entry);
                },
                onLoadEntryDetail: (key) => _controller.loadPreviewEntry(key),
                onSearchChanged: (value) {
                  setState(() {
                    _previewSearchQuery = value;
                  });
                },
                onShowPreviousGroup: _showPreviousPageGroup,
                onShowNextGroup: _showNextPageGroup,
                onSelectPage: _selectPreviewPage,
              ),
          ],
        );
      },
    );
  }

  Future<void> _beginImportSession() async {
    _controller.startImportSession();
    setState(() {
      _isMetadataExpanded = false;
      _isFilesExpanded = false;
      _previewSearchQuery = '';
      _paginationAnchorPage = 1;
    });
    await _requestImportSource();
  }

  Future<void> _requestImportSource() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final filePath = await _pickDictionaryFile(context);
      if (!mounted || filePath == null || filePath.isEmpty) {
        return;
      }
      await _controller.addImportSource(filePath);
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<String?> _pickDictionaryFile(BuildContext context) async {
    try {
      return await widget.pickDictionaryFile();
    } on PlatformException catch (error) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_formatPickerError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  Future<void> _selectPreviewPage(int pageNumber) async {
    await _controller.goToPreviewPage(pageNumber);
    if (_previewListController.hasClients) {
      _previewListController.jumpTo(0);
    }
    setState(() {
      _previewSearchQuery = '';
      _paginationAnchorPage = pageNumber;
    });
  }

  void _showPreviousPageGroup() {
    final preview = _controller.state.importSession.preview;
    if (preview == null) {
      return;
    }
    final pages = preview.pageNumbersForGroup(_paginationAnchorPage);
    if (pages.isEmpty || pages.first == 1) {
      return;
    }
    setState(() {
      _paginationAnchorPage = pages.first - 1;
    });
  }

  void _showNextPageGroup() {
    final preview = _controller.state.importSession.preview;
    if (preview == null) {
      return;
    }
    final pages = preview.pageNumbersForGroup(_paginationAnchorPage);
    if (pages.isEmpty || pages.last >= preview.totalPages) {
      return;
    }
    setState(() {
      _paginationAnchorPage = pages.last + 1;
    });
  }

  String _formatPickerError(PlatformException error) {
    return switch (error.code) {
      'invalid_file_type' => '请选择词库目录、压缩包，或单个 MDX 文件。',
      'picker_busy' => '词库导入窗口已经打开，请先完成当前选择。',
      'picker_unavailable' => '当前无法打开文件选择器，请稍后重试。',
      'picker_copy_failed' => '所选词库文件复制失败，请重新选择后再试。',
      _ => error.message ?? '选择词库时发生错误，请稍后重试。',
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});

  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '背单词',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '先导入词库目录、压缩包，或单个 MDX 文件，再开始你的卡片学习。',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF778095),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120A1633),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FBF5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.file_upload_outlined,
                  color: Color(0xFF0BC58C),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '导入词库包',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '支持导入词库目录、压缩包，或单个 MDX 文件，识别 MDX、MDD、CSS、JS 和其它资源文件，并托管到应用内部目录。',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF80889B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onImport,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0BC58C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
                child: const Text('导入词库包'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.onImport, required this.errorMessage});

  final Future<void> Function() onImport;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '背单词',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF60697D),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onImport, child: const Text('重新选择词库包')),
            ],
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
                  TextButton(onPressed: onAddFile, child: const Text('添加文件')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '主文件',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (primaryFile != null)
                _FileChip(file: primaryFile)
              else
                const Text('尚未识别到主文件'),
              const SizedBox(height: 18),
              Text(
                '关联文件',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final file in relatedFiles) _FileChip(file: file),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          session.stage ==
                              DictionaryImportSessionStage.installing
                          ? null
                          : onPreview,
                      child: const Text('预览'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          session.stage ==
                              DictionaryImportSessionStage.installing
                          ? null
                          : onInstall,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0BC58C),
                      ),
                      child:
                          session.stage ==
                              DictionaryImportSessionStage.installing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('安装'),
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
    required this.paginationAnchorPage,
    required this.onToggleMetadata,
    required this.onBack,
    required this.onClose,
    required this.onAddFile,
    required this.onInstall,
    required this.onSelectEntry,
    required this.onShowPreviousGroup,
    required this.onShowNextGroup,
    required this.onSelectPage,
  });

  final DictionaryImportSession session;
  final ScrollController scrollController;
  final bool metadataExpanded;
  final int paginationAnchorPage;
  final VoidCallback onToggleMetadata;
  final VoidCallback onBack;
  final Future<void> Function() onClose;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onInstall;
  final ValueChanged<WordEntry> onSelectEntry;
  final VoidCallback onShowPreviousGroup;
  final VoidCallback onShowNextGroup;
  final Future<void> Function(int pageNumber) onSelectPage;

  @override
  Widget build(BuildContext context) {
    final preview = session.preview!;
    final previewPage = session.previewPage!;
    final theme = Theme.of(context);
    final visiblePages = preview.pageNumbersForGroup(paginationAnchorPage);
    final metadataPreviewText = preview.metadataText.isEmpty
        ? '未读取到词典元信息。'
        : preview.metadataText;
    final collapsedLength = (metadataPreviewText.length / 3).ceil().clamp(
      0,
      metadataPreviewText.length,
    );
    final metadataText = metadataExpanded
        ? metadataPreviewText
        : metadataPreviewText.substring(0, collapsedLength);

    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: const Color(0xFFF8FAFD),
            elevation: 24,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preview.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onAddFile,
                        child: const Text('添加文件'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onInstall,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0BC58C),
                        ),
                        child: const Text('安装'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PreviewCard(
                          title: '词典元信息',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metadataText,
                                maxLines: metadataExpanded ? null : 4,
                                overflow: metadataExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.fade,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: const Color(0xFF5A6275),
                                ),
                              ),
                              if (!metadataExpanded &&
                                  metadataPreviewText.length >
                                      metadataText.length)
                                TextButton(
                                  onPressed: onToggleMetadata,
                                  child: const Text('更多'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PreviewCard(
                          title: '文件信息',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final file in preview.files)
                                _FileChip(file: file),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '第 ${previewPage.pageNumber} / ${preview.totalPages} 页',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '词条',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView.separated(
                                    controller: scrollController,
                                    itemCount: previewPage.entries.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final entry = previewPage.entries[index];
                                      final isSelected =
                                          session.selectedPreviewEntry?.id ==
                                          entry.id;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: const Color(
                                          0xFFEAF5FF,
                                        ),
                                        title: Text(entry.word),
                                        subtitle: entry.definition == null
                                            ? null
                                            : Text(
                                                entry.definition!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                        onTap: () {
                                          onSelectEntry(entry);
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (context) {
                                              return SafeArea(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    24,
                                                  ),
                                                  child: _EntryDetail(
                                                    entry: entry,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _PageGroupButton(
                                      key: const ValueKey(
                                        'dictionary-preview-previous-group',
                                      ),
                                      icon: Icons.chevron_left_rounded,
                                      enabled:
                                          visiblePages.isNotEmpty &&
                                          visiblePages.first > 1,
                                      onTap: onShowPreviousGroup,
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final pageNumber in visiblePages)
                                            _PageSquareButton(
                                              key: ValueKey(
                                                'dictionary-preview-page-$pageNumber',
                                              ),
                                              pageNumber: pageNumber,
                                              isSelected:
                                                  pageNumber ==
                                                  previewPage.pageNumber,
                                              onPressed: () =>
                                                  onSelectPage(pageNumber),
                                            ),
                                        ],
                                      ),
                                    ),
                                    _PageGroupButton(
                                      key: const ValueKey(
                                        'dictionary-preview-next-group',
                                      ),
                                      icon: Icons.chevron_right_rounded,
                                      enabled:
                                          visiblePages.isNotEmpty &&
                                          visiblePages.last <
                                              preview.totalPages,
                                      onTap: onShowNextGroup,
                                    ),
                                  ],
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
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(onPressed: onAddFile, child: const Text('重新选择')),
                  const SizedBox(width: 12),
                  TextButton(onPressed: onClose, child: const Text('关闭')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.file});

  final DictionaryPreviewFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: file.isPrimary
            ? const Color(0xFFE7FFF5)
            : const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(file.name),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PageSquareButton extends StatelessWidget {
  const _PageSquareButton({
    super.key,
    required this.pageNumber,
    required this.isSelected,
    required this.onPressed,
  });

  final int pageNumber;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF0BC58C)
              : const Color(0xFFEFF3FA),
          foregroundColor: isSelected ? Colors.white : const Color(0xFF324056),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text('$pageNumber'),
      ),
    );
  }
}

class _PageGroupButton extends StatelessWidget {
  const _PageGroupButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF324056)),
        ),
      ),
    );
  }
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.pronunciation != null) Text(entry.pronunciation!),
          if (entry.partOfSpeech != null) ...[
            const SizedBox(height: 6),
            Text(entry.partOfSpeech!),
          ],
          if (entry.definition != null) ...[
            const SizedBox(height: 12),
            Text(
              entry.definition!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 12),
          _SimpleHtmlView(html: entry.rawContent),
        ],
      ),
    );
  }
}

class _SimpleHtmlView extends StatelessWidget {
  const _SimpleHtmlView({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final parsed = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(div|p|li|section|article|h\d)>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();

    return SelectableText(
      parsed,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
    );
  }
}

class _ReadyState extends StatelessWidget {
  const _ReadyState({required this.controller});

  final DictionaryController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final entry = state.currentEntry!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '背单词',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          state.dictionary?.name ?? 'Imported Dictionary',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF7B8497),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (state.activePackage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: Color(0xFF0BC58C),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    state.activePackage!.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C3242),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Expanded(
          child: Center(
            child: Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.horizontal,
              background: const _DecisionBackground(
                alignment: Alignment.centerLeft,
                label: 'Known',
                color: Color(0xFFD7EFE5),
              ),
              secondaryBackground: const _DecisionBackground(
                alignment: Alignment.centerRight,
                label: 'Unknown',
                color: Color(0xFFF4D6D6),
              ),
              onDismissed: (direction) {
                final decision = switch (direction) {
                  DismissDirection.startToEnd => StudyDecisionType.known,
                  DismissDirection.endToStart => StudyDecisionType.unknown,
                  _ => StudyDecisionType.unknown,
                };
                controller.recordDecision(decision);
              },
              child: _LegacyWordCard(entry: entry),
            ),
          ),
        ),
      ],
    );
  }
}

class _DecisionBackground extends StatelessWidget {
  const _DecisionBackground({
    required this.alignment,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E2535),
        ),
      ),
    );
  }
}

class _LegacyWordCard extends StatelessWidget {
  const _LegacyWordCard({required this.entry});

  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.word, style: theme.textTheme.headlineMedium),
          if (_hasValue(entry.pronunciation)) ...[
            const SizedBox(height: 8),
            Text(
              entry.pronunciation!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (_hasValue(entry.partOfSpeech)) ...[
            const SizedBox(height: 16),
            _LegacySectionLabel(label: entry.partOfSpeech!),
          ],
          if (_hasValue(entry.definition)) ...[
            const SizedBox(height: 12),
            Text(entry.definition!, style: theme.textTheme.bodyLarge),
          ],
          if (_hasValue(entry.exampleSentence)) ...[
            const SizedBox(height: 16),
            Text(
              entry.exampleSentence!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!_hasValue(entry.definition) &&
              !_hasValue(entry.exampleSentence)) ...[
            const SizedBox(height: 16),
            Text(entry.rawContent, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _LegacySectionLabel extends StatelessWidget {
  const _LegacySectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
