import 'package:flutter/material.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_player.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_view.dart';

typedef WordDetailPageBuilder =
    Widget Function(String word, WordEntry? initialEntry);
typedef DictionaryHtmlViewBuilder =
    Widget Function(
      DictionaryEntryDetail panel,
      ValueChanged<String> onEntryLinkTap,
      ValueChanged<String> onSoundLinkTap,
    );

class WordDetailPage extends StatefulWidget {
  const WordDetailPage({
    super.key,
    required this.word,
    required this.controller,
    this.initialEntry,
    this.dictionaryHtmlViewBuilder,
    this.wordDetailPageBuilder,
    this.soundRepository,
    this.soundPlayer,
  });

  final String word;
  final WordDetailController controller;
  final WordEntry? initialEntry;
  final DictionaryHtmlViewBuilder? dictionaryHtmlViewBuilder;
  final WordDetailPageBuilder? wordDetailPageBuilder;
  final DictionarySoundRepository? soundRepository;
  final DictionarySoundPlayer? soundPlayer;

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  final Set<String> _expandedDictionaryIds = <String>{};
  late final DictionarySoundRepository _soundRepository;
  late final DictionarySoundPlayer _soundPlayer;

  @override
  void initState() {
    super.initState();
    _soundRepository = widget.soundRepository ?? DictionarySoundRepository();
    _soundPlayer = widget.soundPlayer ?? DictionarySoundPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load(widget.word);
    });
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            final detail = state.detail ?? _fallbackDetail();
            final knowledge = state.knowledge;

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeaderBar(
                              isFavorite: knowledge?.isFavorite ?? false,
                              onToggleFavorite:
                                  widget.controller.toggleFavorite,
                              onMarkKnown: () => _handleMarkKnown(context),
                              onAddNote: () => _openNoteEditor(context),
                            ),
                            const SizedBox(height: 18),
                            _SectionCard(
                              title: '基本',
                              child: _BasicSection(
                                word: detail.word,
                                basic: detail.basic,
                              ),
                            ),
                            _SectionCard(
                              title: '释义',
                              child: _DefinitionsSection(
                                definitions: detail.definitions,
                              ),
                            ),
                            _SectionCard(
                              title: '例句',
                              child: _ExamplesSection(
                                word: detail.word,
                                examples: detail.examples,
                              ),
                            ),
                            const _SectionCard(
                              title: '相关词',
                              child: _PlaceholderBody(
                                text: '同义词、反义词、形近词和派生词会在支持的词典中展示。',
                              ),
                            ),
                            const _SectionCard(
                              title: '单词图谱',
                              child: _PlaceholderBody(text: '单词图谱数据准备后会显示在这里。'),
                            ),
                            const _SectionCard(
                              title: '扩展',
                              child: _PlaceholderBody(
                                text: '对比辨析、词组短语、搭配、词根词缀、词源和助记会在这里展示。',
                              ),
                            ),
                            _SectionCard(
                              title: '笔记',
                              child: _NoteSection(
                                note: knowledge?.note ?? '',
                                onEdit: () => _openNoteEditor(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                '词典',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (detail.dictionaryPanels.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _PlaceholderBody(text: '当前没有可展示的词典结果。'),
                        ),
                      ),
                    ..._buildDictionarySlivers(
                      context,
                      detail.dictionaryPanels,
                    ),
                    if (state.errorMessage != null &&
                        state.status == WordDetailStatus.failure)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: Color(0xFFC25555)),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
                if (state.status == WordDetailStatus.loading ||
                    state.isMutating)
                  const Positioned(
                    right: 24,
                    top: 18,
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDictionarySlivers(
    BuildContext context,
    List<DictionaryEntryDetail> panels,
  ) {
    final htmlViewBuilder =
        widget.dictionaryHtmlViewBuilder ??
        (panel, onEntryLinkTap, onSoundLinkTap) => DictionaryHtmlView(
          panel: panel,
          onEntryLinkTap: onEntryLinkTap,
          onSoundLinkTap: onSoundLinkTap,
        );

    return [
      for (final panel in panels) ...[
        SliverPersistentHeader(
          pinned: true,
          delegate: _DictionaryHeaderDelegate(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _DictionaryHeaderCard(
                panel: panel,
                expanded: _expandedDictionaryIds.contains(panel.dictionaryId),
                onTap: () {
                  setState(() {
                    if (_expandedDictionaryIds.contains(panel.dictionaryId)) {
                      _expandedDictionaryIds.remove(panel.dictionaryId);
                    } else {
                      _expandedDictionaryIds.add(panel.dictionaryId);
                    }
                  });
                },
              ),
            ),
          ),
        ),
        if (_expandedDictionaryIds.contains(panel.dictionaryId))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120A1633),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: panel.errorMessage == null
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.72,
                          child: htmlViewBuilder(panel, _openLinkedWord, (
                            soundUrl,
                          ) {
                            _playLinkedSound(panel, soundUrl);
                          }),
                        )
                      : Text(
                          panel.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFC25555),
                            height: 1.6,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    ];
  }

  Future<void> _handleMarkKnown(BuildContext context) async {
    final skipConfirm =
        widget.controller.state.knowledge?.skipKnownConfirm ?? false;
    if (skipConfirm) {
      await widget.controller.markKnown(skipConfirmNextTime: true);
      return;
    }

    var skipNextTime = false;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '确定标熟吗？',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '标熟后该单词将不再安排学习和复习',
                    style: TextStyle(height: 1.5, color: Color(0xFF667085)),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      setModalState(() => skipNextTime = !skipNextTime);
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: skipNextTime,
                          onChanged: (value) {
                            setModalState(() => skipNextTime = value ?? false);
                          },
                        ),
                        const Expanded(child: Text('下次不再提示')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('确定'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await widget.controller.markKnown(skipConfirmNextTime: skipNextTime);
    }
  }

  Future<void> _openNoteEditor(BuildContext context) async {
    final existingNote = widget.controller.state.knowledge?.note ?? '';
    final controller = TextEditingController(text: existingNote);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '添加笔记',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '记录你的理解、辨析或易错点',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      await widget.controller.saveNote(controller.text);
    }
  }

  void _openLinkedWord(String word) {
    final pageBuilder = widget.wordDetailPageBuilder;
    if (pageBuilder == null) {
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => pageBuilder(word, null)));
  }

  Future<void> _playLinkedSound(
    DictionaryEntryDetail panel,
    String soundUrl,
  ) async {
    final file = await _soundRepository.materializeSoundFile(
      panel: panel,
      soundUrl: soundUrl,
    );
    if (file == null) {
      return;
    }
    await _soundPlayer.playFile(file);
  }

  WordDetail _fallbackDetail() {
    final initialEntry = widget.initialEntry;
    if (initialEntry == null) {
      return WordDetail(word: widget.word);
    }

    return WordDetail(
      word: initialEntry.word,
      basic: WordBasicSummary(
        headword: initialEntry.word,
        pronunciationUs: initialEntry.pronunciation,
      ),
      definitions: initialEntry.definition == null
          ? const <WordSense>[]
          : <WordSense>[
              WordSense(
                partOfSpeech: initialEntry.partOfSpeech ?? '',
                definitionZh: initialEntry.definition!,
              ),
            ],
      examples: initialEntry.exampleSentence == null
          ? const <WordExample>[]
          : <WordExample>[
              WordExample(
                english: initialEntry.exampleSentence!,
                translationZh: '',
              ),
            ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onMarkKnown,
    required this.onAddNote,
  });

  final bool isFavorite;
  final Future<void> Function() onToggleFavorite;
  final Future<void> Function() onMarkKnown;
  final Future<void> Function() onAddNote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: const SizedBox(height: 52, width: 52, child: BackButton()),
        ),
        const Spacer(),
        TextButton(
          onPressed: onMarkKnown,
          child: const Text(
            '标熟',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          key: const ValueKey('word-detail-favorite'),
          onPressed: onToggleFavorite,
          icon: Text(
            isFavorite ? '⭐' : '☆',
            style: TextStyle(
              fontSize: 24,
              color: isFavorite
                  ? const Color(0xFFE7B406)
                  : const Color(0xFF98A2B3),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('word-detail-note'),
          onPressed: onAddNote,
          icon: const Icon(Icons.edit_note_rounded),
        ),
        PopupMenuButton<String>(
          key: const ValueKey('word-detail-options'),
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'report', child: Text('纠错')),
          ],
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120A1633),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _BasicSection extends StatelessWidget {
  const _BasicSection({required this.word, required this.basic});

  final String word;
  final WordBasicSummary basic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          basic.headword ?? word,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (_hasValue(basic.pronunciationUs))
              _InfoChip(label: '美 ${basic.pronunciationUs}'),
            if (_hasValue(basic.pronunciationUk))
              _InfoChip(label: '英 ${basic.pronunciationUk}'),
            if (_hasValue(basic.frequency))
              _InfoChip(label: '词频 ${basic.frequency}'),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _DefinitionsSection extends StatelessWidget {
  const _DefinitionsSection({required this.definitions});

  final List<WordSense> definitions;

  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) {
      return const _PlaceholderBody(text: '当前词典还没有提供可解析的释义。');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: definitions
          .map(
            (definition) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasValue(definition.partOfSpeech))
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(definition.partOfSpeech),
                    ),
                  Expanded(child: Text(definition.definitionZh)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ExamplesSection extends StatelessWidget {
  const _ExamplesSection({required this.word, required this.examples});

  final String word;
  final List<WordExample> examples;

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) {
      return const _PlaceholderBody(text: '当前词典还没有提供例句。');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: examples
          .map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF1B2030),
                        height: 1.6,
                        fontSize: 16,
                      ),
                      children: _highlightWord(example.english, word),
                    ),
                  ),
                  if (_hasValue(example.translationZh))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        example.translationZh,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          height: 1.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  List<TextSpan> _highlightWord(String sentence, String word) {
    if (word.trim().isEmpty) {
      return <TextSpan>[TextSpan(text: sentence)];
    }

    final matches = RegExp(
      RegExp.escape(word),
      caseSensitive: false,
    ).allMatches(sentence);
    if (matches.isEmpty) {
      return <TextSpan>[TextSpan(text: sentence)];
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: sentence.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: sentence.substring(match.start, match.end),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      cursor = match.end;
    }
    if (cursor < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(cursor)));
    }
    return spans;
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.note, required this.onEdit});

  final String note;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    if (note.trim().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('添加你的学习笔记', style: TextStyle(color: Color(0xFF667085))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onEdit, child: const Text('添加笔记')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(note, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onEdit, child: const Text('编辑笔记')),
      ],
    );
  }
}

class _DictionaryHeaderCard extends StatelessWidget {
  const _DictionaryHeaderCard({
    required this.panel,
    required this.expanded,
    required this.onTap,
  });

  final DictionaryEntryDetail panel;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  panel.dictionaryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF667085),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DictionaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DictionaryHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 76;

  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF3F5FA),
      padding: const EdgeInsets.only(top: 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _DictionaryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF667085), height: 1.6),
    );
  }
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
