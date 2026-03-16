import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_library_item.dart';
import 'package:shawyer_words/features/dictionary/domain/dictionary_package.dart';

class DictionaryLibraryDetailPage extends StatefulWidget {
  const DictionaryLibraryDetailPage({
    super.key,
    required this.controller,
    required this.dictionaryId,
  });

  final DictionaryLibraryController controller;
  final String dictionaryId;

  @override
  State<DictionaryLibraryDetailPage> createState() =>
      _DictionaryLibraryDetailPageState();
}

class _DictionaryLibraryDetailPageState
    extends State<DictionaryLibraryDetailPage> {
  Future<void> _confirmDelete(DictionaryLibraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除词典？'),
          content: const Text('删除后会同时移除应用内保存的词典文件，且无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.controller.deleteDictionary(item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除词典')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller.state.status == DictionaryLibraryStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final item = widget.controller.itemById(widget.dictionaryId);
        return Scaffold(
          backgroundColor: const Color(0xFFF3F5FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F5FA),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(item?.name ?? '词典详情'),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: switch (widget.controller.state.status) {
                DictionaryLibraryStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                DictionaryLibraryStatus.failure => Center(
                  child: Text(
                    widget.controller.state.errorMessage ?? '词典信息加载失败',
                  ),
                ),
                _ => item == null
                    ? const Center(child: Text('未找到词典信息'))
                    : _DetailContent(
                        item: item,
                        onDelete: item.type == DictionaryPackageType.imported
                            ? () => _confirmDelete(item)
                            : null,
                        onVisibleChanged: (value) async {
                          await widget.controller.setVisibility(
                            item.id,
                            value,
                          );
                        },
                        onAutoExpandChanged: (value) async {
                          await widget.controller.setAutoExpand(
                            item.id,
                            value,
                          );
                        },
                      ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.item,
    required this.onDelete,
    required this.onVisibleChanged,
    required this.onAutoExpandChanged,
  });

  final DictionaryLibraryItem item;
  final VoidCallback? onDelete;
  final ValueChanged<bool> onVisibleChanged;
  final ValueChanged<bool> onAutoExpandChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          item.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        _SwitchTile(
          title: '显示该词库',
          value: item.isVisible,
          onChanged: onVisibleChanged,
        ),
        const SizedBox(height: 12),
        _SwitchTile(
          title: '自动展开',
          value: item.autoExpand,
          onChanged: onAutoExpandChanged,
        ),
        const SizedBox(height: 28),
        Text(
          '词库信息',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF8D95A6),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(label: '词库版本：', value: item.version),
        _InfoTile(label: '分类：', value: item.category),
        _InfoTile(label: '词条数量：', value: '${item.entryCount}'),
        _InfoTile(label: '词典属性：', value: item.dictionaryAttribute),
        _InfoTile(label: '文件大小：', value: item.fileSizeLabel),
        _InfoTile(label: '词典类型：', value: item.dictionaryTypeLabel),
        if (onDelete != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC93D32),
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('删除该词典'),
            ),
          ),
        ],
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
