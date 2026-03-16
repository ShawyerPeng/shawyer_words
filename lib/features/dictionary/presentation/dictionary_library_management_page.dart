import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_detail_page.dart';

class DictionaryLibraryManagementPage extends StatefulWidget {
  const DictionaryLibraryManagementPage({
    super.key,
    required this.controller,
  });

  final DictionaryLibraryController? controller;

  @override
  State<DictionaryLibraryManagementPage> createState() =>
      _DictionaryLibraryManagementPageState();
}

class _DictionaryLibraryManagementPageState
    extends State<DictionaryLibraryManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _draggingId;

  DictionaryLibraryController? get _controller => widget.controller;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const _ManagementScaffold(
        body: SizedBox.shrink(),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return _ManagementScaffold(
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
              ),
          },
        );
      },
    );
  }
}

class _ManagementScaffold extends StatelessWidget {
  const _ManagementScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('所有词典库'),
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

class _LibraryListContent extends StatelessWidget {
  const _LibraryListContent({
    required this.controller,
    required this.searchController,
    required this.draggingId,
    required this.onDragStateChanged,
  });

  final DictionaryLibraryController controller;
  final TextEditingController searchController;
  final String? draggingId;
  final ValueChanged<String?> onDragStateChanged;

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
        _SectionTitle(title: '显示的词库'),
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
                  onDragStarted: () => onDragStateChanged(visibleItems[index].id),
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
        _SectionTitle(title: '隐藏的词库'),
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
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
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
  const _ReorderTarget({
    required this.isActive,
    required this.onAccept,
  });

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
            color: highlighted
                ? const Color(0xFFDAE6FF)
                : Colors.transparent,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
          child: SizedBox(
            width: 280,
            child: buildRow(includeHandle: true),
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          row,
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.drag_handle_rounded,
              color: Color(0xFFCAD0DB),
            ),
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
