import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_import_session_layer.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_detail_page.dart';

class DictionaryLibraryManagementPage extends StatefulWidget {
  const DictionaryLibraryManagementPage({
    super.key,
    required this.controller,
    this.dictionaryController,
    this.pickDictionaryFile,
  });

  final DictionaryLibraryController? controller;
  final DictionaryController? dictionaryController;
  final Future<String?> Function()? pickDictionaryFile;

  @override
  State<DictionaryLibraryManagementPage> createState() =>
      _DictionaryLibraryManagementPageState();
}

class _DictionaryLibraryManagementPageState
    extends State<DictionaryLibraryManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _previewListController = ScrollController();
  String? _draggingId;
  bool _isPicking = false;
  bool _isMetadataExpanded = false;
  bool _isFilesExpanded = false;
  String _previewSearchQuery = '';
  int _paginationAnchorPage = 1;

  DictionaryLibraryController? get _controller => widget.controller;
  DictionaryController? get _dictionaryController =>
      widget.dictionaryController;

  @override
  void initState() {
    super.initState();
    if (_controller?.state.status == DictionaryLibraryStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller?.load();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _previewListController.dispose();
    super.dispose();
  }

  Future<void> _showHelpDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return const _DictionaryLibraryHelpDialog();
      },
    );
  }

  Future<void> _beginInlineImport() async {
    final dictionaryController = _dictionaryController;
    if (dictionaryController == null || widget.pickDictionaryFile == null) {
      return;
    }

    dictionaryController.startImportSession();
    setState(() {
      _isMetadataExpanded = false;
      _isFilesExpanded = false;
      _previewSearchQuery = '';
      _paginationAnchorPage = 1;
    });

    await _requestImportSource();

    if (!mounted) {
      return;
    }
    if (dictionaryController.state.importSession.stage ==
        DictionaryImportSessionStage.pickerOverlay) {
      await dictionaryController.closeImportSession();
    }
  }

  Future<void> _requestImportSource() async {
    final dictionaryController = _dictionaryController;
    final pickDictionaryFile = widget.pickDictionaryFile;
    if (dictionaryController == null ||
        pickDictionaryFile == null ||
        _isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final filePath = await _pickDictionaryFile();
      if (!mounted || filePath == null || filePath.isEmpty) {
        return;
      }
      await dictionaryController.addImportSource(filePath);
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<String?> _pickDictionaryFile() async {
    try {
      return await widget.pickDictionaryFile?.call();
    } on PlatformException {
      return null;
    }
  }

  Future<void> _openPreview() async {
    final dictionaryController = _dictionaryController;
    if (dictionaryController == null) {
      return;
    }

    await dictionaryController.openImportPreview();
    final page = dictionaryController.state.importSession.previewPage;
    if (page != null && mounted) {
      setState(() {
        _previewSearchQuery = '';
        _paginationAnchorPage = page.pageNumber;
      });
    }
  }

  Future<void> _selectPreviewPage(int pageNumber) async {
    final dictionaryController = _dictionaryController;
    if (dictionaryController == null) {
      return;
    }

    await dictionaryController.goToPreviewPage(pageNumber);
    if (_previewListController.hasClients) {
      _previewListController.jumpTo(0);
    }
    if (mounted) {
      setState(() {
        _previewSearchQuery = '';
        _paginationAnchorPage = pageNumber;
      });
    }
  }

  void _showPreviousPageGroup() {
    final preview = _dictionaryController?.state.importSession.preview;
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
    final preview = _dictionaryController?.state.importSession.preview;
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _ManagementScaffold(
        onHelpPressed: _showHelpDialog,
        body: const SizedBox.shrink(),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([controller, _dictionaryController]),
      builder: (context, _) {
        final importController = _dictionaryController;
        return Stack(
          children: [
            _ManagementScaffold(
              onHelpPressed: _showHelpDialog,
              body: switch (controller.state.status) {
                DictionaryLibraryStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                DictionaryLibraryStatus.failure => Center(
                  child: Text(controller.state.errorMessage ?? '词典库加载失败'),
                ),
                _ => _LibraryListContent(
                  controller: controller,
                  searchController: _searchController,
                  draggingId: _draggingId,
                  onDragStateChanged: (value) {
                    setState(() {
                      _draggingId = value;
                    });
                  },
                  onImportPressed: _beginInlineImport,
                ),
              },
            ),
            if (importController != null &&
                importController.state.importSession.isOpen)
              DictionaryImportSessionLayer(
                session: importController.state.importSession,
                scrollController: _previewListController,
                metadataExpanded: _isMetadataExpanded,
                filesExpanded: _isFilesExpanded,
                searchQuery: _previewSearchQuery,
                paginationAnchorPage: _paginationAnchorPage,
                showPickerOverlay: false,
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
                  importController.returnToImportConfirmation();
                },
                onClose: () async {
                  _previewListController.jumpTo(0);
                  setState(() {
                    _previewSearchQuery = '';
                  });
                  await importController.closeImportSession();
                  await _controller?.load();
                },
                onAddFile: _requestImportSource,
                onPreview: _openPreview,
                onInstall: () async {
                  await importController.installImport();
                  await _controller?.load();
                },
                onSelectEntry: (entry) async {
                  importController.selectPreviewEntry(entry);
                },
                onLoadEntryDetail: (key) =>
                    importController.loadPreviewEntry(key),
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
}

class _ManagementScaffold extends StatelessWidget {
  const _ManagementScaffold({required this.body, required this.onHelpPressed});

  final Widget body;
  final VoidCallback onHelpPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('所有词典库'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: onHelpPressed,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFECEEF4),
                foregroundColor: const Color(0xFF545C6B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                '帮助',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: body,
        ),
      ),
    );
  }
}

class _DictionaryLibraryHelpDialog extends StatelessWidget {
  const _DictionaryLibraryHelpDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🤔', style: theme.textTheme.headlineMedium),
                const SizedBox(width: 10),
                Text(
                  '如何导入扩展词典包',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A4F59),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '通过互联网或者方格单词社区，您可以获取扩展词典包文件并添加到您的设备。',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: const Color(0xFF5E6470),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '大部分词典只需要一个 .mdx 主词典文件。',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: const Color(0xFF5E6470),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '其它支持文件，可以根据词典功能按需安装。',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: const Color(0xFF5E6470),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  _HelpFileRow(
                    badgeLabel: '必要',
                    badgeColor: Color(0xFFE44E91),
                    text: '.mdx 词典主文件（大部分词典只需此文件）',
                  ),
                  SizedBox(height: 10),
                  _HelpFileRow(
                    badgeLabel: '可选',
                    badgeColor: Color(0xFFFF79B6),
                    text: '.mdd 词典音频、配图、显示样式等资源',
                  ),
                  SizedBox(height: 10),
                  _HelpFileRow(
                    badgeLabel: '可选',
                    badgeColor: Color(0xFFFF79B6),
                    text: '.js 词典自定义功能',
                  ),
                  SizedBox(height: 10),
                  _HelpFileRow(
                    badgeLabel: '可选',
                    badgeColor: Color(0xFFFF79B6),
                    text: '.css 词典自定义显示',
                  ),
                  SizedBox(height: 10),
                  _HelpFileRow(
                    badgeLabel: '可选',
                    badgeColor: Color(0xFFFF79B6),
                    text: '.jpg 或 .png 词典封面...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F8),
                  foregroundColor: const Color(0xFF343840),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 44,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '好的',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpFileRow extends StatelessWidget {
  const _HelpFileRow({
    required this.badgeLabel,
    required this.badgeColor,
    required this.text,
  });

  final String badgeLabel;
  final Color badgeColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFFF5CA8),
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryListContent extends StatelessWidget {
  const _LibraryListContent({
    required this.controller,
    required this.searchController,
    required this.draggingId,
    required this.onDragStateChanged,
    required this.onImportPressed,
  });

  final DictionaryLibraryController controller;
  final TextEditingController searchController;
  final String? draggingId;
  final ValueChanged<String?> onDragStateChanged;
  final Future<void> Function() onImportPressed;

  @override
  Widget build(BuildContext context) {
    final visibleItems = controller.visibleItems;
    final hiddenItems = controller.hiddenItems;

    return ListView(
      children: [
        TextField(
          controller: searchController,
          onChanged: controller.updateQuery,
          decoration: InputDecoration(
            hintText: '筛选列表内容',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: '显示的词库',
          trailing: TextButton(
            onPressed: onImportPressed,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFECEEF4),
              foregroundColor: const Color(0xFF545C6B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              '导入词库',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _VisibleDropZone(
          isActive: draggingId != null,
          onAccept: (id) => controller.moveToVisibleIndex(id, 0),
          child: Column(
            children: [
              for (var index = 0; index < visibleItems.length; index++) ...[
                _ReorderTarget(
                  isActive: draggingId != null,
                  onAccept: (id) => controller.moveToVisibleIndex(id, index),
                ),
                _DictionaryRow(
                  item: visibleItems[index],
                  canDrag: true,
                  onDragStarted: () =>
                      onDragStateChanged(visibleItems[index].id),
                  onDragEnded: () => onDragStateChanged(null),
                  onDetailPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DictionaryLibraryDetailPage(
                        controller: controller,
                        dictionaryId: visibleItems[index].id,
                      ),
                    ),
                  ),
                ),
              ],
              _ReorderTarget(
                isActive: draggingId != null,
                onAccept: (id) =>
                    controller.moveToVisibleIndex(id, visibleItems.length),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: '隐藏的词库'),
        const SizedBox(height: 12),
        DragTarget<String>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) async {
            onDragStateChanged(null);
            await controller.moveToHidden(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final isHighlighted = candidateData.isNotEmpty;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFEFF4FF) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF4A82F0)
                      : const Color(0xFFE7EBF3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '拖到这里可以隐藏词库',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFB2B8C5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hiddenItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final item in hiddenItems)
                      _DictionaryRow(
                        item: item,
                        canDrag: true,
                        onDragStarted: () => onDragStateChanged(item.id),
                        onDragEnded: () => onDragStateChanged(null),
                        onDetailPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DictionaryLibraryDetailPage(
                              controller: controller,
                              dictionaryId: item.id,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 28,
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4A82F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF7D8496),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}

class _VisibleDropZone extends StatelessWidget {
  const _VisibleDropZone({
    required this.isActive,
    required this.onAccept,
    required this.child,
  });

  final bool isActive;
  final ValueChanged<String> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(isActive ? 8 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: isActive
                ? Border.all(color: const Color(0xFFDCE6FA))
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

class _ReorderTarget extends StatelessWidget {
  const _ReorderTarget({required this.isActive, required this.onAccept});

  final bool isActive;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const SizedBox(height: 8);
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: highlighted ? 20 : 10,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFDAE6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}

class _DictionaryRow extends StatelessWidget {
  const _DictionaryRow({
    required this.item,
    required this.canDrag,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onDetailPressed,
  });

  final DictionaryLibraryItem item;
  final bool canDrag;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    Widget buildRow({required bool includeHandle}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            _DictionaryTypeIcon(typeLabel: item.dictionaryTypeLabel),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              key: ValueKey('dictionary-detail-${item.id}'),
              onPressed: onDetailPressed,
              icon: const Icon(Icons.chevron_right_rounded),
              color: const Color(0xFFAFB6C4),
            ),
            if (includeHandle)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: Color(0xFFCAD0DB),
                ),
              ),
          ],
        ),
      );
    }

    final row = buildRow(includeHandle: false);
    if (!canDrag) {
      return row;
    }

    return LongPressDraggable<String>(
      data: item.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded(),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.92,
          child: SizedBox(width: 280, child: buildRow(includeHandle: true)),
        ),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          row,
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.drag_handle_rounded, color: Color(0xFFCAD0DB)),
          ),
        ],
      ),
    );
  }
}

class _DictionaryTypeIcon extends StatelessWidget {
  const _DictionaryTypeIcon({required this.typeLabel});

  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final isBundled = typeLabel == '系统内置词典';
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: isBundled ? const Color(0xFFEAF2FF) : const Color(0xFFFFF1DE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isBundled ? Icons.menu_book_rounded : Icons.folder_copy_outlined,
        color: isBundled ? const Color(0xFF4A82F0) : const Color(0xFFF59D2A),
      ),
    );
  }
}
