import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shawyer_words/app/app.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/word_card_view.dart';

class DictionaryHomePage extends StatelessWidget {
  const DictionaryHomePage({
    super.key,
    required this.controller,
    required this.pickDictionaryFile,
  });

  final DictionaryController controller;
  final DictionaryFilePicker pickDictionaryFile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 140),
            child: switch (controller.state.status) {
              DictionaryStatus.importing => const Center(
                child: CircularProgressIndicator(),
              ),
              DictionaryStatus.ready when controller.state.currentEntry != null =>
                _ReadyState(controller: controller),
              DictionaryStatus.failure => _FailureState(
                onImport: () => _handleImport(context),
                errorMessage:
                    controller.state.errorMessage ?? 'Dictionary import failed.',
              ),
              _ => _EmptyState(onImport: () => _handleImport(context)),
            },
          ),
        );
      },
    );
  }

  Future<void> _handleImport(BuildContext context) async {
    final filePath = await _pickDictionaryFile(context);
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    await controller.importDictionary(filePath);
  }

  Future<String?> _pickDictionaryFile(BuildContext context) async {
    try {
      return await pickDictionaryFile();
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
  const _FailureState({
    required this.onImport,
    required this.errorMessage,
  });

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
              FilledButton(
                onPressed: onImport,
                child: const Text('重新选择词库包'),
              ),
            ],
          ),
        ),
      ],
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
              child: WordCardView(entry: entry),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
