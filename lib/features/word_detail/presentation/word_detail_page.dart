import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/word_detail/application/word_detail_controller.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_audio_source_resolver.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_player.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/lexdb_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/domain/word_detail.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef WordDetailPageBuilder =
    Widget Function(String word, WordEntry? initialEntry);
typedef DictionaryHtmlViewBuilder =
    Widget Function(
      DictionaryEntryDetail panel,
      ValueChanged<String> onEntryLinkTap,
      ValueChanged<String> onSoundLinkTap,
    );

enum _DetailNavSection {
  definition,
  related,
  phrase,
  example,
  mnemonic,
  register,
  grammar,
  idiom,
  rootAffix,
  etymology,
}

class _DetailNavItem {
  const _DetailNavItem(this.section, this.title);

  final _DetailNavSection section;
  final String title;
}

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
  int _activeTabIndex = 0;
  int _selectedLexDbEntryIndex = 0;
  bool _showHyphenation = false;
  bool _showTopGradient = true;
  bool _showPinnedTabs = false;
  final Map<_DetailNavSection, GlobalKey> _sectionAnchorKeys =
      <_DetailNavSection, GlobalKey>{
        for (final section in _DetailNavSection.values) section: GlobalKey(),
      };
  late final DictionarySoundRepository _soundRepository;
  late final DictionarySoundPlayer _soundPlayer;
  final Map<String, String> _pronunciationCache = <String, String>{};
  final Set<String> _pronunciationWarmupInFlight = <String>{};
  String? _lastPronunciationWarmupWord;

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
    for (final path in _pronunciationCache.values) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _soundPlayer.dispose();
    super.dispose();
  }

  void _handleScroll(
    double offset, {
    required List<_DetailNavItem> navSections,
    required double topInset,
  }) {
    final shouldShowGradient = offset < 160;
    final stickyTop = topInset + 8;

    var shouldShowPinnedTabs = false;
    var activeIndex = _activeTabIndex;

    if (navSections.length >= 2) {
      final context =
          _sectionAnchorKeys[navSections[1].section]?.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final y = box.localToGlobal(Offset.zero).dy;
          shouldShowPinnedTabs = y <= stickyTop;
        }
      }
    }

    for (var index = 0; index < navSections.length; index += 1) {
      final context =
          _sectionAnchorKeys[navSections[index].section]?.currentContext;
      if (context == null) {
        continue;
      }
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) {
        continue;
      }
      final y = box.localToGlobal(Offset.zero).dy;
      if (y <= stickyTop + 10) {
        activeIndex = index;
      }
    }

    final clampedIndex = activeIndex.clamp(
      0,
      navSections.isEmpty ? 0 : navSections.length - 1,
    );
    if (_showTopGradient == shouldShowGradient &&
        _showPinnedTabs == shouldShowPinnedTabs &&
        _activeTabIndex == clampedIndex) {
      return;
    }

    setState(() {
      _showTopGradient = shouldShowGradient;
      _showPinnedTabs = shouldShowPinnedTabs;
      _activeTabIndex = clampedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final state = widget.controller.state;
          final isInitialLoading =
              state.status == WordDetailStatus.loading && state.detail == null;
          final detail = state.detail ?? _fallbackDetail();
          final tldInfo = isInitialLoading ? null : _collectTldInfo(detail);
          if (state.status == WordDetailStatus.ready && state.detail != null) {
            _warmupPronunciations(detail);
          }
          final knowledge = state.knowledge;
          final examples = isInitialLoading
              ? const <_EntryExampleItem>[]
              : _collectExamples(detail);
          final audioExamples = examples
              .where((example) => _hasValue(example.audioPath))
              .toList(growable: false);
          final phraseItems = isInitialLoading
              ? const <_PhraseItem>[]
              : _collectPhraseItems(detail);
          final inflectionItems = isInitialLoading
              ? const <_InflectionItem>[]
              : _collectInflectionItems(detail);
          final synonymItems = isInitialLoading
              ? const <String>[]
              : _collectRelationItems(
                  detail,
                  relationTypes: const <String>{'synonym'},
                );
          final antonymItems = isInitialLoading
              ? const <String>[]
              : _collectRelationItems(
                  detail,
                  relationTypes: const <String>{'antonym'},
                );
          final thesaurusItems = isInitialLoading
              ? const <_ThesaurusItem>[]
              : _collectThesaurusItems(detail);
          final similarSpellingItems = isInitialLoading
              ? const <String>[]
              : detail.similarSpellingWords;
          final similarSoundItems = isInitialLoading
              ? const <String>[]
              : detail.similarSoundWords;
          final wordFamilyGroups = isInitialLoading
              ? const <_WordFamilyGroup>[]
              : _collectWordFamilyGroups(detail);
          final hasRelatedSection =
              synonymItems.isNotEmpty ||
              thesaurusItems.isNotEmpty ||
              antonymItems.isNotEmpty ||
              similarSpellingItems.isNotEmpty ||
              similarSoundItems.isNotEmpty ||
              inflectionItems.isNotEmpty ||
              wordFamilyGroups.isNotEmpty;
          final registerItems = isInitialLoading
              ? const <String>[]
              : _collectRegisterItems(detail);
          final mnemonicItems = isInitialLoading
              ? const <String>[]
              : _collectMnemonicItems(detail);
          final grammaticalPatterns = isInitialLoading
              ? const <String>[]
              : _collectGrammaticalPatterns(detail);
          final idiomItems = isInitialLoading
              ? const <String>[]
              : _collectIdiomItems(detail);
          final rootAffixItems = isInitialLoading
              ? const <String>[]
              : _collectRootAffixItems(detail);
          final etymologyItems = isInitialLoading
              ? const <_EtymologyItem>[]
              : _collectEtymologyItems(detail);
          final navSections = _buildVisibleNavSections(
            detail: detail,
            hasRelatedSection: hasRelatedSection,
            phraseItems: phraseItems,
            examples: examples,
            registerItems: registerItems,
            mnemonicItems: mnemonicItems,
            grammaticalPatterns: grammaticalPatterns,
            idiomItems: idiomItems,
            rootAffixItems: rootAffixItems,
            etymologyItems: etymologyItems,
            hasOnlineEtymologySection:
                !isInitialLoading && _hasValue(detail.word),
          );
          final activeTabIndex = navSections.isEmpty
              ? 0
              : _activeTabIndex.clamp(0, navSections.length - 1);
          final hyphenation = _extractHyphenation(detail);
          final frequencyTag = _extractFrequencyTag(detail);
          final examTags = isInitialLoading
              ? const <String>[]
              : _extractTldExamTags(detail);
          final pronunciationBadges = _buildPronunciationBadges(detail);
          final selectedLexDbEntryIndex = detail.lexDbEntries.isEmpty
              ? 0
              : _selectedLexDbEntryIndex.clamp(
                  0,
                  detail.lexDbEntries.length - 1,
                );
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: const Color(0xFFF3F5FA)),
              ),
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: AnimatedOpacity(
                  key: const ValueKey('word-detail-top-gradient'),
                  opacity: _showTopGradient ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: Container(
                    height: topInset + 204,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF10C98E), Color(0xFF20CFCF)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -46,
                          top: -34,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  _handleScroll(
                    notification.metrics.pixels,
                    navSections: navSections,
                    topInset: topInset,
                  );
                  return false;
                },
                child: CustomScrollView(
                  primary: true,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopSearchBar(
                              word: detail.word,
                              onCancel: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                              onOptionSelected: (value) {
                                _handleTopMenuSelection(context, value);
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    key: const ValueKey('word-detail-headword'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: hyphenation == null
                                        ? null
                                        : () {
                                            setState(() {
                                              _showHyphenation =
                                                  !_showHyphenation;
                                            });
                                          },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _showHyphenation &&
                                                  _hasValue(hyphenation)
                                              ? hyphenation!
                                              : detail.word,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            height: 1.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    key: const ValueKey('word-detail-favorite'),
                                    onPressed: widget.controller.toggleFavorite,
                                    icon: Text(
                                      knowledge?.isFavorite ?? false
                                          ? '⭐'
                                          : '☆',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (pronunciationBadges.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < pronunciationBadges.length;
                                      index += 1
                                    ) ...[
                                      pronunciationBadges[index],
                                      if (index <
                                          pronunciationBadges.length - 1)
                                        const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            if (_hasValue(frequencyTag) ||
                                examTags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (_hasValue(frequencyTag))
                                      _buildHeaderInfoChip(
                                        '词频 ${frequencyTag!.trim()}',
                                      ),
                                    for (
                                      var index = 0;
                                      index < examTags.length;
                                      index += 1
                                    ) ...[
                                      if (_hasValue(frequencyTag) || index > 0)
                                        const SizedBox(width: 6),
                                      _buildHeaderInfoChip(examTags[index]),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    if (isInitialLoading)
                      const SliverToBoxAdapter(
                        child: _InitialDetailLoadingSliverBody(),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              if (navSections.isNotEmpty) ...[
                                _DetailTabs(
                                  activeIndex: activeTabIndex,
                                  labels: navSections
                                      .map((section) => section.title)
                                      .toList(growable: false),
                                  onSelect: (index) {
                                    _scrollToSection(navSections, index);
                                  },
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE8EBF0),
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  0,
                                ),
                                child: _WordDetailTabBody(
                                  detail: detail,
                                  tldInfo: tldInfo,
                                  selectedLexDbEntryIndex:
                                      selectedLexDbEntryIndex,
                                  inflectionItems: inflectionItems,
                                  synonymItems: synonymItems,
                                  thesaurusItems: thesaurusItems,
                                  antonymItems: antonymItems,
                                  similarSpellingItems: similarSpellingItems,
                                  similarSoundItems: similarSoundItems,
                                  wordFamilyGroups: wordFamilyGroups,
                                  wordFamilyBriefDefinitions:
                                      detail.wordFamilyBriefDefinitions,
                                  onTapLinkedWord: _openLinkedWord,
                                  phraseItems: phraseItems,
                                  examples: examples,
                                  audioExamples: audioExamples,
                                  registerItems: registerItems,
                                  mnemonicItems: mnemonicItems,
                                  grammaticalPatterns: grammaticalPatterns,
                                  idiomItems: idiomItems,
                                  rootAffixItems: rootAffixItems,
                                  etymologyItems: etymologyItems,
                                  onlineEtymologyWord: detail.word,
                                  onTapOpenOnlineEtymology:
                                      _openOnlineEtymology,
                                  sectionKeys: _sectionAnchorKeys,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                          child: Text(
                            '词典',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _OnlineDictionarySection(
                            providers: _onlineDictionaryProviders,
                            onTapProvider: (provider) {
                              _openOnlineDictionary(provider, detail.word);
                            },
                          ),
                        ),
                      ),
                    ],
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
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
              if ((state.status == WordDetailStatus.loading &&
                      !isInitialLoading) ||
                  state.isMutating)
                const Positioned(
                  right: 24,
                  top: 24,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              if (_showPinnedTabs && navSections.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: topInset,
                    color: const Color(0xFFF8F9FB),
                  ),
                ),
              if (_showPinnedTabs && navSections.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: topInset,
                  child: Container(
                    color: const Color(0xFFF8F9FB),
                    child: _DetailTabs(
                      activeIndex: activeTabIndex,
                      labels: navSections
                          .map((section) => section.title)
                          .toList(growable: false),
                      onSelect: (index) {
                        _scrollToSection(navSections, index);
                      },
                    ),
                  ),
                ),
              if (!isInitialLoading && detail.lexDbEntries.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 14,
                  child: IgnorePointer(
                    ignoring: false,
                    child: _EntrySwitcherBar(
                      entries: detail.lexDbEntries,
                      selectedIndex: selectedLexDbEntryIndex,
                      onSelect: (index) {
                        setState(() {
                          _selectedLexDbEntryIndex = index;
                        });
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleTopMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'markKnown':
        return _handleMarkKnown(context);
      case 'note':
        return _openNoteEditor(context);
      case 'report':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('纠错功能开发中')));
        return Future<void>.value();
      default:
        return Future<void>.value();
    }
  }

  List<Widget> _buildPronunciationBadges(WordDetail detail) {
    final chips = <_PronunciationBadgeData>[];
    final dedupe = <String>{};

    void addBadge(String label, String? value, String? audioPath) {
      if (!_hasValue(value)) {
        return;
      }
      final key = '$label|${value!.trim()}';
      if (dedupe.add(key)) {
        chips.add(
          _PronunciationBadgeData(
            label: label,
            phonetic: value,
            audioPath: audioPath,
          ),
        );
        return;
      }
      final index = chips.indexWhere(
        (chip) => chip.label == label && chip.phonetic == value,
      );
      if (index < 0 || _hasValue(chips[index].audioPath)) {
        return;
      }
      chips[index] = _PronunciationBadgeData(
        label: label,
        phonetic: value,
        audioPath: audioPath,
      );
    }

    final firstLexDbEntry = detail.lexDbEntries.isEmpty
        ? null
        : detail.lexDbEntries.first;
    if (firstLexDbEntry != null) {
      for (final pronunciation in firstLexDbEntry.pronunciations) {
        final variant = pronunciation.variant.toLowerCase();
        if (variant.contains('uk') || variant.contains('br')) {
          addBadge('英', pronunciation.phonetic, pronunciation.audioPath);
        } else if (variant.contains('us') || variant.contains('am')) {
          addBadge('美', pronunciation.phonetic, pronunciation.audioPath);
        }
      }
    } else {
      addBadge('英', detail.basic.pronunciationUk, detail.basic.audioUk);
      addBadge('美', detail.basic.pronunciationUs, detail.basic.audioUs);
    }

    if (chips.isEmpty) {
      addBadge('英', detail.basic.pronunciationUk, detail.basic.audioUk);
      addBadge('美', detail.basic.pronunciationUs, detail.basic.audioUs);
    }

    if (chips.isEmpty && firstLexDbEntry != null) {
      // Fallback: show first two IPA values from first entry even if variant isn't classified.
      for (final pronunciation in firstLexDbEntry.pronunciations) {
        final ipa = pronunciation.phonetic?.trim();
        if (ipa == null || ipa.isEmpty) {
          continue;
        }
        final label = chips.any((chip) => chip.label == '英') ? '美' : '英';
        addBadge(label, ipa, pronunciation.audioPath);
        if (chips.length >= 2) {
          break;
        }
      }
    }

    if (chips.isEmpty) {
      return const <Widget>[];
    }

    return chips
        .asMap()
        .entries
        .map(
          (entry) => _PronunciationBadge(
            key: ValueKey('word-detail-pronunciation-${entry.key}'),
            label: entry.value.label,
            phonetic: entry.value.phonetic,
            enabled: _hasValue(entry.value.audioPath),
            onTap: entry.value.audioPath == null
                ? null
                : () => _playPronunciation(entry.value.audioPath!),
          ),
        )
        .toList(growable: false);
  }

  List<String> _extractTldExamTags(WordDetail detail) {
    for (final entry in detail.lexDbEntries) {
      final rawValue = entry.entryAttributes['tld/exam_tags'];
      final parsed = _parseTldExamTags(rawValue);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return const <String>[];
  }

  Widget _buildHeaderInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF5FEFA),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<_EntryExampleItem> _collectExamples(WordDetail detail) {
    final items = <_EntryExampleItem>[];
    final dedupe = <String>{};

    void addExample(String sentence, String? translation, String? audioPath) {
      if (!_hasValue(sentence)) {
        return;
      }
      final normalizedSentence = sentence.trim();
      final normalizedTranslation = translation?.trim() ?? '';
      final dedupeKey =
          '$normalizedSentence|$normalizedTranslation|${audioPath ?? ''}';
      if (!dedupe.add(dedupeKey)) {
        return;
      }
      items.add(
        _EntryExampleItem(
          english: normalizedSentence,
          translationZh: normalizedTranslation,
          audioPath: audioPath,
        ),
      );
    }

    for (final entry in detail.lexDbEntries) {
      for (final sense in entry.senses) {
        for (final example in sense.examplesBeforePatterns) {
          addExample(example.text, example.textZh, example.audioPath);
        }
        for (final example in sense.examplesAfterPatterns) {
          addExample(example.text, example.textZh, example.audioPath);
        }
        for (final pattern in sense.grammarPatterns) {
          for (final example in pattern.examples) {
            addExample(example.text, example.textZh, example.audioPath);
          }
        }
      }
      for (final collocation in entry.collocations) {
        for (final example in collocation.examples) {
          addExample(example.text, example.textZh, example.audioPath);
        }
      }
    }

    return items;
  }

  List<_PhraseItem> _collectPhraseItems(WordDetail detail) {
    final items = <_PhraseItem>[];
    final dedupe = <String>{};

    void addItem(String text, String? translation) {
      final normalizedText = text.trim();
      final normalizedTranslation = translation?.trim() ?? '';
      if (normalizedText.isEmpty) {
        return;
      }
      final key = '$normalizedText|$normalizedTranslation';
      if (!dedupe.add(key)) {
        return;
      }
      items.add(
        _PhraseItem(text: normalizedText, translation: normalizedTranslation),
      );
    }

    void collectFromMap(Map<String, Object?> map) {
      final phrase =
          (map['phrasal_verb'] as String?) ??
          (map['phrase'] as String?) ??
          (map['text'] as String?) ??
          (map['word'] as String?) ??
          (map['headword'] as String?) ??
          '';
      final translation = _extractPhraseTranslation(map);
      addItem(phrase, translation);
    }

    for (final entry in detail.lexDbEntries) {
      final rawPhrasalVerbs = entry.entryAttributes['ldoce/phrasal-verbs'];
      if (!_hasValue(rawPhrasalVerbs)) {
        continue;
      }
      final trimmed = rawPhrasalVerbs!.trim();
      dynamic decoded;
      try {
        decoded = jsonDecode(trimmed);
      } on Object {
        for (final value in _extractForms(trimmed)) {
          addItem(value, null);
        }
        continue;
      }

      if (decoded is List) {
        for (final item in decoded) {
          if (item is String) {
            addItem(item, null);
            continue;
          }
          if (item is Map) {
            collectFromMap(Map<String, Object?>.from(item));
          }
        }
        continue;
      }

      if (decoded is Map) {
        final map = Map<String, Object?>.from(decoded);
        final nestedItems = map['items'];
        if (nestedItems is List) {
          for (final item in nestedItems) {
            if (item is Map) {
              collectFromMap(Map<String, Object?>.from(item));
            } else if (item is String) {
              addItem(item, null);
            }
          }
          continue;
        }
        collectFromMap(map);
      }
    }
    return items;
  }

  String? _extractPhraseTranslation(Map<String, Object?> map) {
    String? pickFirstValue(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    final direct = pickFirstValue(const <String>[
      'definition',
      'definition_cn',
      'definition_zh',
      'translation',
      'meaning',
      'gloss',
      'explain',
      'explanation',
    ]);
    if (_hasValue(direct)) {
      return direct;
    }

    List<String> collectFromObject(Object? value) {
      if (value == null) {
        return const <String>[];
      }
      if (value is String) {
        final text = value.trim();
        return text.isEmpty ? const <String>[] : <String>[text];
      }
      if (value is List) {
        final values = <String>[];
        for (final item in value) {
          values.addAll(collectFromObject(item));
        }
        return values;
      }
      if (value is Map) {
        final nested = Map<String, Object?>.from(value);
        final nestedDirect = <String>[];
        for (final key in const <String>[
          'definition',
          'definition_cn',
          'definition_zh',
          'translation',
          'meaning',
          'gloss',
          'explain',
          'explanation',
        ]) {
          final nestedValue = nested[key];
          if (nestedValue is String && nestedValue.trim().isNotEmpty) {
            nestedDirect.add(nestedValue.trim());
          }
        }
        if (nestedDirect.isNotEmpty) {
          return nestedDirect;
        }
        final values = <String>[];
        for (final key in const <String>[
          'items',
          'senses',
          'definitions',
          'meanings',
          'translations',
          'children',
        ]) {
          values.addAll(collectFromObject(nested[key]));
        }
        return values;
      }
      return const <String>[];
    }

    final nestedCandidates = <String>[
      ...collectFromObject(map['items']),
      ...collectFromObject(map['senses']),
      ...collectFromObject(map['definitions']),
      ...collectFromObject(map['meanings']),
      ...collectFromObject(map['translations']),
      ...collectFromObject(map['children']),
    ];
    final dedupe = <String>{};
    final normalized = nestedCandidates
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && dedupe.add(value))
        .toList(growable: false);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized.join('；');
  }

  List<_InflectionItem> _collectInflectionItems(WordDetail detail) {
    final valuesByCategory = <_InflectionCategory, Set<String>>{
      for (final category in _inflectionOrder) category: <String>{},
    };

    for (final entry in detail.lexDbEntries) {
      final rawInflections = entry.entryAttributes['ldoce/inflections'];
      if (!_hasValue(rawInflections)) {
        continue;
      }
      _mergeInflections(rawInflections!, valuesByCategory);
    }

    return _inflectionOrder
        .map((category) {
          final forms = valuesByCategory[category]!.toList(growable: false);
          return forms.isEmpty
              ? null
              : _InflectionItem(category: category, forms: forms);
        })
        .whereType<_InflectionItem>()
        .toList(growable: false);
  }

  List<String> _collectRelationItems(
    WordDetail detail, {
    required Set<String> relationTypes,
  }) {
    final values = <String>[];
    final dedupe = <String>{};

    bool matchesType(String rawType) {
      final normalized = rawType.trim().toLowerCase();
      if (normalized.isEmpty) {
        return false;
      }
      return relationTypes.any(normalized.contains);
    }

    for (final entry in detail.lexDbEntries) {
      for (final relation in entry.relations) {
        if (!matchesType(relation.relationType)) {
          continue;
        }
        final word = _decodeRelationWord(relation.targetWord);
        if (word.isEmpty || !dedupe.add(word)) {
          continue;
        }
        values.add(word);
      }
    }
    return values;
  }

  String _decodeRelationWord(String rawWord) {
    final trimmed = rawWord.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized = trimmed.replaceAll('+', ' ');
    try {
      return Uri.decodeComponent(normalized).trim();
    } on FormatException {
      return normalized.trim();
    }
  }

  List<_WordFamilyGroup> _collectWordFamilyGroups(WordDetail detail) {
    final grouped = <String, List<String>>{};
    final dedupeByPos = <String, Set<String>>{};

    void addWord(String pos, String word) {
      final normalizedPos = pos.trim();
      final normalizedWord = word.trim();
      if (normalizedWord.isEmpty) {
        return;
      }
      final words = grouped.putIfAbsent(normalizedPos, () => <String>[]);
      final dedupe = dedupeByPos.putIfAbsent(normalizedPos, () => <String>{});
      if (!dedupe.add(normalizedWord)) {
        return;
      }
      words.add(normalizedWord);
    }

    for (final entry in detail.lexDbEntries) {
      for (final attribute in entry.entryAttributes.entries) {
        final key = attribute.key.trim().toLowerCase();
        if (!(key.contains('word_family') ||
            key.contains('word_famil') ||
            key.contains('wordfamily') ||
            key.contains('wordfamil') ||
            key.endsWith('/family') ||
            key == 'family')) {
          continue;
        }
        _extractWordFamilyWords(attribute.value, addWord);
      }
    }

    return grouped.entries
        .map(
          (entry) =>
              _WordFamilyGroup(pos: entry.key, words: entry.value.toList()),
        )
        .where((group) => group.words.isNotEmpty)
        .toList(growable: false);
  }

  List<_ThesaurusItem> _collectThesaurusItems(WordDetail detail) {
    final items = <_ThesaurusItem>[];
    final dedupe = <String>{};

    for (final entry in detail.lexDbEntries) {
      final rawValue = entry.entryAttributes['ldoce/thesaurus'];
      if (!_hasValue(rawValue)) {
        continue;
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(rawValue!);
      } on Object {
        continue;
      }
      final sections = decoded is List
          ? decoded
          : decoded is Map
          ? <Object?>[decoded]
          : const <Object?>[];
      for (final section in sections) {
        if (section is! Map) {
          continue;
        }
        final sectionMap = Map<String, Object?>.from(section);
        final rawItems = sectionMap['items'];
        if (rawItems is! List) {
          continue;
        }
        for (final rawItem in rawItems) {
          if (rawItem is! Map) {
            continue;
          }
          final itemMap = Map<String, Object?>.from(rawItem);
          final word = ((itemMap['word'] as String?) ?? '').trim();
          if (word.isEmpty) {
            continue;
          }
          final definition = ((itemMap['definition'] as String?) ?? '').trim();
          final definitionZh =
              ((itemMap['definition_cn'] as String?) ??
                      (itemMap['definition_zh'] as String?) ??
                      '')
                  .trim();
          final key = '$word|$definition|$definitionZh';
          if (!dedupe.add(key)) {
            continue;
          }

          final examples = <_ThesaurusExampleItem>[];
          final rawExamples = itemMap['examples'];
          if (rawExamples is List) {
            for (final rawExample in rawExamples) {
              if (rawExample is! Map) {
                continue;
              }
              final exampleMap = Map<String, Object?>.from(rawExample);
              final text = ((exampleMap['text'] as String?) ?? '').trim();
              final textZh =
                  ((exampleMap['text_cn'] as String?) ??
                          (exampleMap['text_zh'] as String?) ??
                          '')
                      .trim();
              if (text.isEmpty && textZh.isEmpty) {
                continue;
              }
              examples.add(_ThesaurusExampleItem(text: text, textZh: textZh));
            }
          }
          items.add(
            _ThesaurusItem(
              word: word,
              definition: definition,
              definitionZh: definitionZh,
              examples: examples,
            ),
          );
        }
      }
    }
    return items;
  }

  void _extractWordFamilyWords(
    String rawValue,
    void Function(String pos, String word) onWord,
  ) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on Object {
      for (final word in _extractForms(trimmed)) {
        onWord('', word);
      }
      return;
    }

    void collect(Object? value, String currentPos) {
      if (value == null) {
        return;
      }
      if (value is String) {
        for (final word in _extractForms(value)) {
          onWord(currentPos, word);
        }
        return;
      }
      if (value is List) {
        for (final item in value) {
          collect(item, currentPos);
        }
        return;
      }
      if (value is Map) {
        final map = Map<String, Object?>.from(value);
        final mapPos =
            (map['pos'] as String?) ??
            (map['part_of_speech'] as String?) ??
            (map['category'] as String?) ??
            (map['type'] as String?) ??
            '';
        final nextPos = mapPos.trim().isEmpty ? currentPos : mapPos.trim();
        collect(map['word'], nextPos);
        collect(map['value'], nextPos);
        collect(map['text'], nextPos);
        collect(map['name'], nextPos);
        collect(map['items'], nextPos);
        collect(map['groups'], nextPos);
        collect(map['words'], nextPos);
        collect(map['forms'], nextPos);
        collect(map['entries'], nextPos);
        collect(map['members'], nextPos);
        collect(map['derivative'], nextPos);
        collect(map['derivatives'], nextPos);
        collect(map['variants'], nextPos);
        collect(map['children'], nextPos);
      }
    }

    collect(decoded, '');
  }

  void _mergeInflections(
    String rawJson,
    Map<_InflectionCategory, Set<String>> valuesByCategory,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on Object {
      return;
    }

    void addForms(_InflectionCategory category, Object? rawValue) {
      for (final form in _extractForms(rawValue)) {
        valuesByCategory[category]!.add(form);
      }
    }

    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final category = _normalizeInflectionCategory('${entry.key}');
        if (category == null) {
          continue;
        }
        addForms(category, entry.value);
      }
      return;
    }

    if (decoded is List) {
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, Object?>.from(item);
        final rawType =
            (map['type'] as String?) ??
            (map['key'] as String?) ??
            (map['name'] as String?) ??
            (map['label'] as String?) ??
            '';
        final category = _normalizeInflectionCategory(rawType);
        if (category == null) {
          continue;
        }
        final rawValue =
            map['forms'] ?? map['values'] ?? map['value'] ?? map['word'];
        addForms(category, rawValue);
        final compactCode = rawType.trim().toUpperCase().replaceAll(
          RegExp(r'[\s_/\\-]+'),
          '',
        );
        if (compactCode == 'PTNPP') {
          addForms(_InflectionCategory.pastParticiple, rawValue);
        }
      }
    }
  }

  Iterable<String> _extractForms(Object? rawValue) {
    if (rawValue == null) {
      return const <String>[];
    }
    if (rawValue is String) {
      return rawValue
          .split(RegExp(r'[,，;/|]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty && value != '-');
    }
    if (rawValue is List) {
      final forms = <String>[];
      for (final item in rawValue) {
        if (item is String) {
          final value = item.trim();
          if (value.isNotEmpty && value != '-') {
            forms.add(value);
          }
        } else if (item is Map) {
          final value =
              (item['word'] as String?) ??
              (item['value'] as String?) ??
              (item['text'] as String?);
          if (value != null && value.trim().isNotEmpty) {
            forms.add(value.trim());
          }
        }
      }
      return forms;
    }
    return const <String>[];
  }

  _InflectionCategory? _normalizeInflectionCategory(String rawKey) {
    final key = rawKey.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    final compactCode = rawKey.trim().toUpperCase().replaceAll(
      RegExp(r'[\s_/\\-]+'),
      '',
    );
    if (key.isEmpty) {
      return null;
    }
    if (key == '复数' || key.contains('plural') || compactCode == 'PLURAL') {
      return _InflectionCategory.plural;
    }
    if (key == '第三人称单数' ||
        key.contains('third_person') ||
        key.contains('3rd_person') ||
        key.contains('third_singular') ||
        compactCode == 'TPS') {
      return _InflectionCategory.thirdPersonSingular;
    }
    if (key == '过去式' ||
        key.contains('past_tense') ||
        key == 'past' ||
        compactCode == 'PT') {
      return _InflectionCategory.past;
    }
    if (key == '过去分词' ||
        key.contains('past_participle') ||
        key == 'pp' ||
        compactCode == 'PP') {
      return _InflectionCategory.pastParticiple;
    }
    if (compactCode == 'PTNPP') {
      return _InflectionCategory.past;
    }
    if (key == '现在分词' ||
        key.contains('present_participle') ||
        key.contains('ing') ||
        compactCode == 'PRE') {
      return _InflectionCategory.presentParticiple;
    }
    if (key == '副词' || key.contains('adverb') || compactCode == 'ADV') {
      return _InflectionCategory.adverb;
    }
    if (key == '所有格' || key.contains('possessive') || compactCode == 'POSS') {
      return _InflectionCategory.possessive;
    }
    if (key == '比较级' ||
        key.contains('comparative') ||
        key == 'comp' ||
        compactCode == 'COMPAR') {
      return _InflectionCategory.comparative;
    }
    if (key == '最高级' ||
        key.contains('superlative') ||
        key == 'sup' ||
        compactCode == 'SUPERL') {
      return _InflectionCategory.superlative;
    }
    return null;
  }

  List<String> _collectRegisterItems(WordDetail detail) {
    return _collectLabelValuesByType(detail, <String>[
      'register',
      'tone',
      'style',
    ]);
  }

  List<String> _collectMnemonicItems(WordDetail detail) {
    return _collectLabelValuesByType(detail, <String>[
      'mnemonic',
      'memory',
      'remember',
    ]);
  }

  List<String> _collectGrammaticalPatterns(WordDetail detail) {
    final values = <String>[];
    final dedupe = <String>{};

    void addValue(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || !dedupe.add(text)) {
        return;
      }
      values.add(text);
    }

    for (final entry in detail.lexDbEntries) {
      for (final sense in entry.senses) {
        for (final pattern in sense.grammarPatterns) {
          addValue(pattern.pattern);
          addValue(pattern.gloss);
        }
      }
      for (final collocation in entry.collocations) {
        final grammar = collocation.grammar?.trim().toLowerCase() ?? '';
        if (grammar.isNotEmpty && grammar != 'idiom') {
          addValue(collocation.grammar);
        }
      }
    }
    return values;
  }

  List<String> _collectIdiomItems(WordDetail detail) {
    final values = _collectLabelValuesByType(detail, <String>[
      'idiom',
      'idiomatic',
    ]);
    final dedupe = values.toSet();
    for (final entry in detail.lexDbEntries) {
      for (final collocation in entry.collocations) {
        final grammar = collocation.grammar?.trim().toLowerCase() ?? '';
        if (grammar != 'idiom') {
          continue;
        }
        final text = collocation.collocate.trim();
        if (text.isEmpty || !dedupe.add(text)) {
          continue;
        }
        values.add(text);
      }
    }
    return values;
  }

  List<String> _collectRootAffixItems(WordDetail detail) {
    return _collectLabelValuesByType(detail, <String>[
      'root',
      'affix',
      'prefix',
      'suffix',
      'stem',
    ]);
  }

  List<_EtymologyItem> _collectEtymologyItems(WordDetail detail) {
    final items = <_EtymologyItem>[];
    final dedupe = <String>{};

    for (final entry in detail.lexDbEntries) {
      final full = (entry.entryAttributes['ldoce/origin_full'] ?? '').trim();
      final century = (entry.entryAttributes['ldoce/origin_century'] ?? '')
          .trim();
      final language = (entry.entryAttributes['ldoce/origin_language'] ?? '')
          .trim();
      final resolvedFull = full.isNotEmpty
          ? full
          : [century, language].where((value) => value.isNotEmpty).join(' ');
      if (resolvedFull.isEmpty) {
        continue;
      }
      final key = '$resolvedFull|$century|$language';
      if (!dedupe.add(key)) {
        continue;
      }
      items.add(
        _EtymologyItem(
          fullText: resolvedFull,
          century: century,
          language: language,
        ),
      );
    }
    return items;
  }

  _TldDefinitionInfo? _collectTldInfo(WordDetail detail) {
    String? examTags;
    String? difficultyLevel;
    String? coca;
    String? iweb;
    String? spokenRank;
    String? senseRatioRaw;

    String? pick(String? value) {
      if (!_hasValue(value)) {
        return null;
      }
      return value!.trim();
    }

    for (final entry in detail.lexDbEntries) {
      examTags ??= pick(entry.entryAttributes['tld/exam_tags']);
      difficultyLevel ??= pick(entry.entryAttributes['tld/difficulty_level']);
      coca ??= pick(entry.entryAttributes['tld/coca']);
      iweb ??= pick(entry.entryAttributes['tld/iweb']);
      spokenRank ??= pick(entry.entryAttributes['tld/spoken_rank']);
      senseRatioRaw ??= pick(entry.entryAttributes['tld/sense_ratio_cn']);
    }

    final examTagItems = _parseTldExamTags(examTags);
    final difficultyLevelValue = _parseTldDifficultyLevel(difficultyLevel);
    final cocaItems = _parseTldCorpusItems(coca);
    final iwebItems = _parseTldCorpusItems(iweb);
    final spokenRankInfo = _parseTldSpokenRank(spokenRank);
    final senseSlices = _parseSenseRatioSlices(senseRatioRaw);
    final posSlices = _buildPosRatioSlicesFromIweb(iwebItems);
    final hasAny =
        difficultyLevelValue != null ||
        cocaItems.isNotEmpty ||
        iwebItems.isNotEmpty ||
        spokenRankInfo != null ||
        senseSlices.isNotEmpty ||
        posSlices.isNotEmpty;
    if (!hasAny) {
      return null;
    }
    return _TldDefinitionInfo(
      examTags: examTagItems,
      difficultyLevel: difficultyLevelValue,
      cocaItems: cocaItems,
      iwebItems: iwebItems,
      spokenRankInfo: spokenRankInfo,
      senseRatioSlices: senseSlices,
      posRatioSlices: posSlices,
    );
  }

  List<String> _parseTldExamTags(String? rawValue) {
    if (!_hasValue(rawValue)) {
      return const <String>[];
    }
    final raw = rawValue!.trim();
    final decoded = _tryDecodeJson(raw);
    if (decoded is List) {
      final values = <String>[];
      final dedupe = <String>{};
      for (final item in decoded) {
        final text = item is String ? item.trim() : '';
        if (text.isEmpty || !dedupe.add(text)) {
          continue;
        }
        values.add(text);
      }
      return values;
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return <String>[decoded.trim()];
    }
    return const <String>[];
  }

  int? _parseTldDifficultyLevel(String? rawValue) {
    if (!_hasValue(rawValue)) {
      return null;
    }
    final decoded = _tryDecodeJson(rawValue!.trim());
    return _parseIntValue(decoded ?? rawValue);
  }

  List<_TldCorpusItem> _parseTldCorpusItems(String? rawValue) {
    if (!_hasValue(rawValue)) {
      return const <_TldCorpusItem>[];
    }
    final decoded = _tryDecodeJson(rawValue!.trim());
    if (decoded is! List) {
      return const <_TldCorpusItem>[];
    }
    final items = <_TldCorpusItem>[];
    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }
      final pos = '${item['pos'] ?? ''}'.trim();
      final rank = _parseIntValue(item['rank']);
      final total = _parseIntValue(item['total']);
      if (pos.isEmpty ||
          rank == null ||
          total == null ||
          rank <= 0 ||
          total <= 0) {
        continue;
      }
      items.add(_TldCorpusItem(pos: pos, rank: rank, total: total));
    }
    return items;
  }

  _TldSpokenRankInfo? _parseTldSpokenRank(String? rawValue) {
    if (!_hasValue(rawValue)) {
      return null;
    }
    final decoded = _tryDecodeJson(rawValue!.trim());
    if (decoded is! Map) {
      return null;
    }
    final rank = _parseIntValue(decoded['rank']);
    final total = _parseIntValue(decoded['total']);
    if (rank == null || total == null || rank <= 0 || total <= 0) {
      return null;
    }
    final lemmas = <_TldLemmaCount>[];
    final rawLemmas = decoded['lemmas'];
    if (rawLemmas is List) {
      for (final lemma in rawLemmas) {
        if (lemma is! Map) {
          continue;
        }
        final form = '${lemma['form'] ?? ''}'.trim();
        final count = _parseIntValue(lemma['count']);
        if (form.isEmpty || count == null || count <= 0) {
          continue;
        }
        lemmas.add(_TldLemmaCount(form: form, count: count));
      }
    }
    return _TldSpokenRankInfo(rank: rank, total: total, lemmas: lemmas);
  }

  List<_SenseRatioSlice> _parseSenseRatioSlices(String? rawValue) {
    if (!_hasValue(rawValue)) {
      return const <_SenseRatioSlice>[];
    }
    final decoded = _tryDecodeJson(rawValue!.trim());
    if (decoded is! List) {
      return const <_SenseRatioSlice>[];
    }
    final entries = <(String, double)>[];

    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }
      final label = '${item['meaning'] ?? ''}'.trim();
      final value = _parseDoubleValue(item['percent']);
      if (label.isEmpty || value == null || value <= 0) {
        continue;
      }
      entries.add((label, value));
    }
    return _normalizeSenseSlices(entries);
  }

  dynamic _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } on Object {
      return null;
    }
  }

  int? _parseIntValue(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  double? _parseDoubleValue(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw.trim());
    }
    return null;
  }

  List<_SenseRatioSlice> _normalizeSenseSlices(List<(String, double)> entries) {
    if (entries.isEmpty) {
      return const <_SenseRatioSlice>[];
    }
    final sum = entries.fold<double>(0, (total, item) => total + item.$2);
    if (sum <= 0) {
      return const <_SenseRatioSlice>[];
    }
    const palette = <Color>[
      Color(0xFFF8648B),
      Color(0xFF2FA1FF),
      Color(0xFFF6C343),
      Color(0xFF35C8BE),
      Color(0xFF9B7CFF),
      Color(0xFF66C56B),
    ];
    final slices = <_SenseRatioSlice>[];
    for (var i = 0; i < entries.length; i += 1) {
      final entry = entries[i];
      slices.add(
        _SenseRatioSlice(
          label: entry.$1,
          ratio: entry.$2 / sum,
          color: palette[i % palette.length],
        ),
      );
    }
    return slices;
  }

  List<_SenseRatioSlice> _buildPosRatioSlicesFromIweb(
    List<_TldCorpusItem> iwebItems,
  ) {
    if (iwebItems.isEmpty) {
      return const <_SenseRatioSlice>[];
    }
    final weighted = <String, double>{};
    for (final item in iwebItems) {
      if (item.rank <= 0) {
        continue;
      }
      final posLabel = _translatePosToZh(item.pos);
      if (posLabel.isEmpty) {
        continue;
      }
      weighted[posLabel] = (weighted[posLabel] ?? 0) + (1 / item.rank);
    }
    final entries = weighted.entries
        .map<(String, double)>((entry) => (entry.key, entry.value))
        .toList(growable: false);
    return _normalizeSenseSlices(entries);
  }

  String _translatePosToZh(String rawPos) {
    final value = rawPos.trim().toLowerCase();
    if (value.isEmpty) {
      return '';
    }
    if (value == 'v' || value == 'verb') {
      return '动词';
    }
    if (value == 'n' || value == 'noun') {
      return '名词';
    }
    if (value == 'j' || value == 'adj' || value == 'adjective') {
      return '形容词';
    }
    if (value == 'r' || value == 'adv' || value == 'adverb') {
      return '副词';
    }
    if (value == 'prep' || value == 'preposition') {
      return '介词';
    }
    if (value == 'pron' || value == 'pronoun') {
      return '代词';
    }
    if (value == 'conj' || value == 'conjunction') {
      return '连词';
    }
    return rawPos.toUpperCase();
  }

  List<String> _collectLabelValuesByType(
    WordDetail detail,
    List<String> typeKeywords,
  ) {
    final values = <String>[];
    final dedupe = <String>{};

    bool matchesType(String type) {
      final normalized = type.trim().toLowerCase();
      return typeKeywords.any(normalized.contains);
    }

    void addLabel(LexDbLabel label) {
      if (!matchesType(label.type)) {
        return;
      }
      final text = label.value.trim();
      if (text.isEmpty || !dedupe.add(text)) {
        return;
      }
      values.add(text);
    }

    for (final entry in detail.lexDbEntries) {
      for (final label in entry.entryLabels) {
        addLabel(label);
      }
      for (final sense in entry.senses) {
        for (final label in sense.labels) {
          addLabel(label);
        }
      }
    }
    return values;
  }

  List<_DetailNavItem> _buildVisibleNavSections({
    required WordDetail detail,
    required bool hasRelatedSection,
    required List<_PhraseItem> phraseItems,
    required List<_EntryExampleItem> examples,
    required List<String> registerItems,
    required List<String> mnemonicItems,
    required List<String> grammaticalPatterns,
    required List<String> idiomItems,
    required List<String> rootAffixItems,
    required List<_EtymologyItem> etymologyItems,
    required bool hasOnlineEtymologySection,
  }) {
    final sections = <_DetailNavItem>[];
    if (detail.lexDbEntries.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.definition, '释义'));
    }
    if (hasRelatedSection) {
      sections.add(const _DetailNavItem(_DetailNavSection.related, '相关词'));
    }
    if (phraseItems.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.phrase, '短语'));
    }
    if (examples.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.example, '例句'));
    }
    if (mnemonicItems.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.mnemonic, '词汇助记'));
    }
    if (registerItems.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.register, '语域'));
    }
    if (grammaticalPatterns.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.grammar, '语法行为'));
    }
    if (idiomItems.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.idiom, '习语'));
    }
    if (rootAffixItems.isNotEmpty) {
      sections.add(const _DetailNavItem(_DetailNavSection.rootAffix, '词根词缀'));
    }
    if (etymologyItems.isNotEmpty || hasOnlineEtymologySection) {
      sections.add(const _DetailNavItem(_DetailNavSection.etymology, '词源'));
    }
    return sections;
  }

  String? _extractHyphenation(WordDetail detail) {
    for (final entry in detail.lexDbEntries) {
      final display = entry.headwordDisplay?.trim();
      if (_hasValue(display)) {
        return display;
      }
    }
    return null;
  }

  String? _extractFrequencyTag(WordDetail detail) {
    String? normalizeFrequencyValue(String? raw) {
      if (!_hasValue(raw)) {
        return null;
      }
      final trimmed = raw!.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }

    String? tryReadEntryAttributeFrequency(LexDbEntryDetail entry) {
      final dotCandidates = <String?>[
        entry.entryAttributes['ldoce/frequency-dots'],
        entry.entryAttributes['ldoce/frequency_dots'],
        entry.entryAttributes['frequency-dots'],
        entry.entryAttributes['frequency_dots'],
      ];
      for (final value in dotCandidates) {
        final normalized = normalizeFrequencyValue(value);
        if (normalized != null) {
          return normalized;
        }
      }

      final levelCandidates = <String?>[
        entry.entryAttributes['ldoce/frequency'],
        entry.entryAttributes['frequency'],
      ];
      for (final value in levelCandidates) {
        final normalized = normalizeFrequencyValue(value);
        if (normalized != null) {
          return normalized;
        }
      }
      return null;
    }

    for (final entry in detail.lexDbEntries) {
      final fromAttribute = tryReadEntryAttributeFrequency(entry);
      if (fromAttribute != null) {
        return fromAttribute;
      }
    }

    if (_hasValue(detail.basic.frequency)) {
      return detail.basic.frequency!.trim();
    }
    for (final entry in detail.lexDbEntries) {
      for (final label in entry.entryLabels) {
        final type = label.type.trim().toLowerCase();
        if (!type.contains('frequency')) {
          continue;
        }
        final value = label.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  Future<void> _scrollToSection(
    List<_DetailNavItem> sections,
    int index,
  ) async {
    if (index < 0 || index >= sections.length) {
      return;
    }
    setState(() {
      _activeTabIndex = index;
    });
    final anchor = _sectionAnchorKeys[sections[index].section];
    final targetContext = anchor?.currentContext;
    if (targetContext == null) {
      return;
    }
    final scrollableState = Scrollable.maybeOf(targetContext);
    final position = scrollableState?.position;
    final renderObject = targetContext.findRenderObject();
    final viewport = renderObject == null
        ? null
        : RenderAbstractViewport.maybeOf(renderObject);
    if (position == null || renderObject == null || viewport == null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
      return;
    }

    final revealOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
    final pinnedOffset = _showPinnedTabs
        ? MediaQuery.of(context).padding.top + 40
        : 0.0;
    final targetOffset = (revealOffset - pinnedOffset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await position.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _playPronunciation(String rawAudioPath) async {
    final source = _normalizeAudioSource(rawAudioPath);
    if (source == null) {
      _showSnackBar('当前词典未提供可播放发音');
      return;
    }
    try {
      final cachedPath = _pronunciationCache[source];
      if (_hasValue(cachedPath) && await File(cachedPath!).exists()) {
        await _soundPlayer.playSource(cachedPath);
      } else {
        await _soundPlayer.playSource(source);
      }
    } catch (_) {
      _showSnackBar('发音播放失败');
    }
  }

  String? _normalizeAudioSource(String? rawAudioPath) {
    return normalizeDictionaryAudioSource(rawAudioPath);
  }

  void _warmupPronunciations(WordDetail detail) {
    final wordKey = detail.word.trim().toLowerCase();
    if (wordKey.isEmpty || _lastPronunciationWarmupWord == wordKey) {
      return;
    }
    _lastPronunciationWarmupWord = wordKey;

    final sources = <String>{};
    final firstLexDbEntry = detail.lexDbEntries.isEmpty
        ? null
        : detail.lexDbEntries.first;
    if (firstLexDbEntry != null) {
      for (final pronunciation in firstLexDbEntry.pronunciations) {
        final source = _normalizeAudioSource(pronunciation.audioPath);
        if (source != null) {
          sources.add(source);
        }
      }
    } else {
      final uk = _normalizeAudioSource(detail.basic.audioUk);
      final us = _normalizeAudioSource(detail.basic.audioUs);
      if (uk != null) {
        sources.add(uk);
      }
      if (us != null) {
        sources.add(us);
      }
    }

    for (final source in sources) {
      if (!source.startsWith('http://') && !source.startsWith('https://')) {
        continue;
      }
      if (_pronunciationCache.containsKey(source) ||
          !_pronunciationWarmupInFlight.add(source)) {
        continue;
      }
      _downloadPronunciationToCache(source).whenComplete(() {
        _pronunciationWarmupInFlight.remove(source);
      });
    }
  }

  Future<void> _downloadPronunciationToCache(String source) async {
    try {
      final uri = Uri.tryParse(source);
      if (uri == null || !uri.hasScheme) {
        return;
      }
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        client.close();
        return;
      }
      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      client.close();
      if (bytes.isEmpty) {
        return;
      }

      final extension = () {
        final path = uri.path;
        final dot = path.lastIndexOf('.');
        if (dot < 0) {
          return '.mp3';
        }
        return path.substring(dot);
      }();
      final file = File(
        '${Directory.systemTemp.path}/pronunciation-cache-${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      _pronunciationCache[source] = file.path;
    } on Object {
      // Ignore warmup failures and fallback to direct play source.
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
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
        if (_expandedDictionaryIds.contains(panel.dictionaryId))
          SliverPersistentHeader(
            pinned: true,
            delegate: _DictionaryHeaderDelegate(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _DictionaryHeaderCard(
                  panel: panel,
                  expanded: true,
                  onTap: () {
                    setState(() {
                      _expandedDictionaryIds.remove(panel.dictionaryId);
                    });
                  },
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _DictionaryHeaderCard(
                panel: panel,
                expanded: false,
                onTap: () {
                  setState(() {
                    _expandedDictionaryIds.add(panel.dictionaryId);
                  });
                },
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Offstage(
            offstage: !_expandedDictionaryIds.contains(panel.dictionaryId),
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
                      ? KeyedSubtree(
                          key: ValueKey(
                            'dictionary-panel-${panel.dictionaryId}',
                          ),
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

  Future<void> _openOnlineDictionary(
    _OnlineDictionaryProvider provider,
    String word,
  ) async {
    final normalizedWord = word.trim();
    if (normalizedWord.isEmpty) {
      return;
    }
    final url = provider.buildUrl(normalizedWord);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showSnackBar('在线词典链接无效');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _OnlineDictionaryWebPage(title: provider.name, initialUri: uri),
      ),
    );
  }

  Future<void> _openOnlineEtymology(String word) async {
    final queryWord = word.trim();
    if (queryWord.isEmpty) {
      return;
    }
    final uri = Uri.parse(
      'https://www.etymonline.com/search?q=${Uri.encodeQueryComponent(queryWord)}',
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            _OnlineDictionaryWebPage(title: '在线词源', initialUri: uri),
      ),
    );
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

const List<_OnlineDictionaryProvider> _onlineDictionaryProviders =
    <_OnlineDictionaryProvider>[
      _OnlineDictionaryProvider(
        id: 'maimemo',
        name: '墨墨搜词',
        logoText: '墨墨',
        logoBackground: Color(0xFFF2F9FF),
        logoForeground: Color(0xFF2A78C8),
        urlBuilder: _maimemoUrl,
      ),
      _OnlineDictionaryProvider(
        id: 'iciba',
        name: '金山词典',
        logoText: '金山',
        logoBackground: Color(0xFFF7F5FF),
        logoForeground: Color(0xFF5A56D6),
        urlBuilder: _icibaUrl,
      ),
      _OnlineDictionaryProvider(
        id: 'youdao',
        name: '有道词典',
        logoText: '有道',
        logoBackground: Color(0xFFFFF3F2),
        logoForeground: Color(0xFFD63A32),
        urlBuilder: _youdaoUrl,
      ),
      _OnlineDictionaryProvider(
        id: 'haici',
        name: '海词词典',
        logoText: '海词',
        logoBackground: Color(0xFFF1F8FF),
        logoForeground: Color(0xFF1B76E3),
        urlBuilder: _haiciUrl,
      ),
      _OnlineDictionaryProvider(
        id: 'bing',
        name: '必应词典',
        logoText: 'Bing',
        logoBackground: Color(0xFFFFF6E8),
        logoForeground: Color(0xFFB57D11),
        urlBuilder: _bingDictUrl,
      ),
    ];

String _maimemoUrl(String word) =>
    'https://lookup.maimemo.com/search?word=${Uri.encodeQueryComponent(word)}';
String _icibaUrl(String word) =>
    'https://www.iciba.com/word?w=${Uri.encodeQueryComponent(word)}';
String _youdaoUrl(String word) =>
    'https://www.youdao.com/result?word=${Uri.encodeQueryComponent(word)}&lang=en';
String _haiciUrl(String word) => 'https://dict.cn/${Uri.encodeComponent(word)}';
String _bingDictUrl(String word) =>
    'https://cn.bing.com/dict/search?q=${Uri.encodeQueryComponent(word)}';

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    required this.word,
    required this.onCancel,
    required this.onOptionSelected,
  });

  final String word;
  final VoidCallback onCancel;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            key: const ValueKey('word-detail-search-shell'),
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xE6EAF8F3),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xE6EAF8F3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onCancel,
          child: const Text(
            '取消',
            style: TextStyle(
              color: Color(0xFFF5FEFA),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        PopupMenuButton<String>(
          key: const ValueKey('word-detail-options'),
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Color(0xFFF5FEFA),
            size: 22,
          ),
          onSelected: onOptionSelected,
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'markKnown', child: Text('标熟')),
            PopupMenuItem<String>(value: 'note', child: Text('笔记')),
            PopupMenuItem<String>(value: 'report', child: Text('纠错')),
          ],
        ),
      ],
    );
  }
}

class _OnlineDictionaryProvider {
  const _OnlineDictionaryProvider({
    required this.id,
    required this.name,
    required this.logoText,
    required this.logoBackground,
    required this.logoForeground,
    required this.urlBuilder,
  });

  final String id;
  final String name;
  final String logoText;
  final Color logoBackground;
  final Color logoForeground;
  final String Function(String word) urlBuilder;

  String buildUrl(String word) => urlBuilder(word);
}

class _OnlineDictionarySection extends StatelessWidget {
  const _OnlineDictionarySection({
    required this.providers,
    required this.onTapProvider,
  });

  final List<_OnlineDictionaryProvider> providers;
  final ValueChanged<_OnlineDictionaryProvider> onTapProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A1633),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '在线词典',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final provider in providers)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _OnlineDictionaryLogoTile(
                      provider: provider,
                      onTap: () => onTapProvider(provider),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineDictionaryLogoTile extends StatelessWidget {
  const _OnlineDictionaryLogoTile({
    required this.provider,
    required this.onTap,
  });

  final _OnlineDictionaryProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('online-dictionary-logo-${provider.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: provider.logoBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Text(
          provider.logoText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: provider.logoForeground,
            fontSize: provider.logoText.length > 3 ? 11 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: provider.logoText.length > 3 ? 0.1 : 0.2,
          ),
        ),
      ),
    );
  }
}

class _OnlineDictionaryWebPage extends StatefulWidget {
  const _OnlineDictionaryWebPage({
    required this.title,
    required this.initialUri,
  });

  final String title;
  final Uri initialUri;

  @override
  State<_OnlineDictionaryWebPage> createState() =>
      _OnlineDictionaryWebPageState();
}

class _OnlineDictionaryWebPageState extends State<_OnlineDictionaryWebPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(widget.initialUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class _PronunciationBadgeData {
  const _PronunciationBadgeData({
    required this.label,
    required this.phonetic,
    this.audioPath,
  });

  final String label;
  final String phonetic;
  final String? audioPath;
}

class _InitialDetailLoadingSliverBody extends StatelessWidget {
  const _InitialDetailLoadingSliverBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SizedBox(
        key: const ValueKey('word-detail-loading'),
        height: 360,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.8),
              ),
              SizedBox(height: 14),
              Text(
                '正在加载单词详情...',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PronunciationBadge extends StatelessWidget {
  const _PronunciationBadge({
    super.key,
    required this.label,
    required this.phonetic,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final String phonetic;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: enabled ? 0.58 : 0.32),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled
                        ? const Color(0xFF17785A)
                        : const Color(0xFF6DAA96),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.volume_up_rounded,
                  size: 14,
                  color: enabled
                      ? const Color(0xFF1A8E69)
                      : const Color(0xFF6DAA96),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            phonetic,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFFF2FFFA)
                  : const Color(0xD6EAF8F3),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({
    required this.activeIndex,
    required this.labels,
    required this.onSelect,
  });

  final int activeIndex;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List<Widget>.generate(labels.length, (index) {
            final selected = index == activeIndex;
            return InkWell(
              onTap: () => onSelect(index),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF10C98E)
                            : const Color(0xFF9AA1AE),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF10C98E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WordDetailTabBody extends StatelessWidget {
  const _WordDetailTabBody({
    required this.detail,
    required this.tldInfo,
    required this.selectedLexDbEntryIndex,
    required this.inflectionItems,
    required this.synonymItems,
    required this.thesaurusItems,
    required this.antonymItems,
    required this.similarSpellingItems,
    required this.similarSoundItems,
    required this.wordFamilyGroups,
    required this.wordFamilyBriefDefinitions,
    required this.onTapLinkedWord,
    required this.phraseItems,
    required this.examples,
    required this.audioExamples,
    required this.mnemonicItems,
    required this.registerItems,
    required this.grammaticalPatterns,
    required this.idiomItems,
    required this.rootAffixItems,
    required this.etymologyItems,
    required this.onlineEtymologyWord,
    required this.onTapOpenOnlineEtymology,
    required this.sectionKeys,
  });

  final WordDetail detail;
  final _TldDefinitionInfo? tldInfo;
  final int selectedLexDbEntryIndex;
  final List<_InflectionItem> inflectionItems;
  final List<String> synonymItems;
  final List<_ThesaurusItem> thesaurusItems;
  final List<String> antonymItems;
  final List<String> similarSpellingItems;
  final List<String> similarSoundItems;
  final List<_WordFamilyGroup> wordFamilyGroups;
  final Map<String, String> wordFamilyBriefDefinitions;
  final ValueChanged<String> onTapLinkedWord;
  final List<_PhraseItem> phraseItems;
  final List<_EntryExampleItem> examples;
  final List<_EntryExampleItem> audioExamples;
  final List<String> mnemonicItems;
  final List<String> registerItems;
  final List<String> grammaticalPatterns;
  final List<String> idiomItems;
  final List<String> rootAffixItems;
  final List<_EtymologyItem> etymologyItems;
  final String onlineEtymologyWord;
  final ValueChanged<String> onTapOpenOnlineEtymology;
  final Map<_DetailNavSection, GlobalKey> sectionKeys;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      if (detail.lexDbEntries.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.definition]!,
          title: '释义',
          child: _buildDefinitionSection(),
        ),
      if (synonymItems.isNotEmpty ||
          thesaurusItems.isNotEmpty ||
          antonymItems.isNotEmpty ||
          similarSpellingItems.isNotEmpty ||
          similarSoundItems.isNotEmpty ||
          inflectionItems.isNotEmpty ||
          wordFamilyGroups.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.related]!,
          title: '相关词',
          child: _buildRelatedSection(),
        ),
      if (phraseItems.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.phrase]!,
          title: '短语',
          child: _buildPhraseSection(),
        ),
      if (examples.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.example]!,
          title: '例句',
          child: _buildExampleSection(examples),
        ),
      if (mnemonicItems.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.mnemonic]!,
          title: '词汇助记',
          child: _buildTagListSection(mnemonicItems),
        ),
      if (registerItems.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.register]!,
          title: '语域',
          child: _buildTagListSection(registerItems),
        ),
      if (grammaticalPatterns.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.grammar]!,
          title: '语法行为',
          child: _buildTagListSection(grammaticalPatterns),
        ),
      if (idiomItems.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.idiom]!,
          title: '习语',
          child: _buildTagListSection(idiomItems),
        ),
      if (rootAffixItems.isNotEmpty)
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.rootAffix]!,
          title: '词根词缀',
          child: _buildTagListSection(rootAffixItems),
        ),
      if (etymologyItems.isNotEmpty || _hasValue(onlineEtymologyWord))
        _AnchoredDetailSection(
          anchorKey: sectionKeys[_DetailNavSection.etymology]!,
          title: '词源',
          child: _EtymologyTabSection(
            etymologyItems: etymologyItems,
            onlineEtymologyWord: onlineEtymologyWord,
            onTapOpenOnlineEtymology: onTapOpenOnlineEtymology,
          ),
        ),
      if (audioExamples.isNotEmpty)
        _SimpleDetailSection(
          title: '原声例句',
          showDivider: false,
          child: _buildExampleSection(audioExamples),
        ),
    ];

    if (sections.isEmpty) {
      return const _PlaceholderBody(text: '当前词典没有可解析的数据。');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildDefinitionSection() {
    if (detail.lexDbEntries.isEmpty && tldInfo == null) {
      return const _PlaceholderBody(text: '当前词典还没有提供可解析的释义。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tldInfo != null) ...[
          _TldDefinitionPanel(info: tldInfo!),
          const SizedBox(height: 12),
        ],
        if (detail.lexDbEntries.isNotEmpty)
          _LexDbEntriesSection(
            entry: detail.lexDbEntries[selectedLexDbEntryIndex],
            queryWord: detail.word,
          ),
      ],
    );
  }

  Widget _buildRelatedSection() {
    final blocks = <Widget>[];

    void addBlock(Widget child) {
      if (blocks.isNotEmpty) {
        blocks.add(const SizedBox(height: 10));
      }
      blocks.add(child);
    }

    if (synonymItems.isNotEmpty) {
      addBlock(
        _buildRelatedCard(
          title: '同义词',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinkedWordsInline(
                key: const ValueKey('related-synonyms-inline'),
                words: synonymItems,
                onTapWord: onTapLinkedWord,
              ),
              if (thesaurusItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (
                  var index = 0;
                  index < thesaurusItems.length;
                  index += 1
                ) ...[
                  _ThesaurusItemCard(
                    key: ValueKey('related-thesaurus-item-$index'),
                    item: thesaurusItems[index],
                    onTapWord: onTapLinkedWord,
                  ),
                  if (index < thesaurusItems.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      );
    }
    if (antonymItems.isNotEmpty) {
      addBlock(
        _buildRelatedCard(
          title: '反义词',
          child: _LinkedWordsInline(
            key: const ValueKey('related-antonyms-inline'),
            words: antonymItems,
            onTapWord: onTapLinkedWord,
          ),
        ),
      );
    }
    if (similarSpellingItems.isNotEmpty) {
      addBlock(
        _buildRelatedCard(
          title: '形近词',
          child: _LinkedWordsInline(
            key: const ValueKey('related-similar-spelling-inline'),
            words: similarSpellingItems,
            onTapWord: onTapLinkedWord,
          ),
        ),
      );
    }
    if (similarSoundItems.isNotEmpty) {
      addBlock(
        _buildRelatedCard(
          title: '音近词',
          child: _LinkedWordsInline(
            key: const ValueKey('related-similar-sound-inline'),
            words: similarSoundItems,
            onTapWord: onTapLinkedWord,
          ),
        ),
      );
    }
    if (inflectionItems.isNotEmpty) {
      addBlock(
        _buildRelatedCard(
          title: '词形变化',
          child: Column(
            children: [
              for (
                var index = 0;
                index < inflectionItems.length;
                index += 1
              ) ...[
                _InflectionRow(
                  item: inflectionItems[index],
                  onTapWord: onTapLinkedWord,
                ),
                if (index < inflectionItems.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    }
    if (wordFamilyGroups.isNotEmpty) {
      addBlock(
        _buildRelatedCard(
          title: '词族',
          child: _WordFamilyTreePanel(
            groups: wordFamilyGroups,
            briefDefinitions: wordFamilyBriefDefinitions,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _buildRelatedCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RelatedSubsectionTitle(title),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildPhraseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < phraseItems.length; index += 1) ...[
          _PhraseOrExampleCard(
            index: index + 1,
            english: phraseItems[index].text,
            translation: phraseItems[index].translation,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTagListSection(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD1FADF)),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildExampleSection(List<_EntryExampleItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index += 1) ...[
          _PhraseOrExampleCard(
            index: index + 1,
            english: items[index].english,
            translation: items[index].translationZh,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AnchoredDetailSection extends StatelessWidget {
  const _AnchoredDetailSection({
    required this.anchorKey,
    required this.title,
    required this.child,
  });

  final GlobalKey anchorKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: anchorKey,
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8EBF0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_TabSectionTitle(title), const SizedBox(height: 8), child],
      ),
    );
  }
}

class _SimpleDetailSection extends StatelessWidget {
  const _SimpleDetailSection({
    required this.title,
    required this.child,
    this.showDivider = true,
  });

  final String title;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE8EBF0), width: 1),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_TabSectionTitle(title), const SizedBox(height: 8), child],
      ),
    );
  }
}

class _TabSectionTitle extends StatelessWidget {
  const _TabSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E2433),
      ),
    );
  }
}

enum _InflectionCategory {
  plural('复数'),
  thirdPersonSingular('第三人称单数'),
  past('过去式'),
  pastParticiple('过去分词'),
  presentParticiple('现在分词'),
  adverb('副词'),
  possessive('所有格'),
  comparative('比较级'),
  superlative('最高级');

  const _InflectionCategory(this.label);

  final String label;
}

const List<_InflectionCategory> _inflectionOrder = <_InflectionCategory>[
  _InflectionCategory.plural,
  _InflectionCategory.thirdPersonSingular,
  _InflectionCategory.past,
  _InflectionCategory.pastParticiple,
  _InflectionCategory.presentParticiple,
  _InflectionCategory.adverb,
  _InflectionCategory.possessive,
  _InflectionCategory.comparative,
  _InflectionCategory.superlative,
];

class _InflectionItem {
  const _InflectionItem({required this.category, required this.forms});

  final _InflectionCategory category;
  final List<String> forms;
}

class _ThesaurusItem {
  const _ThesaurusItem({
    required this.word,
    required this.definition,
    required this.definitionZh,
    required this.examples,
  });

  final String word;
  final String definition;
  final String definitionZh;
  final List<_ThesaurusExampleItem> examples;
}

class _ThesaurusExampleItem {
  const _ThesaurusExampleItem({required this.text, required this.textZh});

  final String text;
  final String textZh;
}

class _EtymologyItem {
  const _EtymologyItem({
    required this.fullText,
    required this.century,
    required this.language,
  });

  final String fullText;
  final String century;
  final String language;
}

class _WordFamilyGroup {
  const _WordFamilyGroup({required this.pos, required this.words});

  final String pos;
  final List<String> words;
}

class _SenseRatioSlice {
  const _SenseRatioSlice({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double ratio;
  final Color color;
}

class _TldCorpusItem {
  const _TldCorpusItem({
    required this.pos,
    required this.rank,
    required this.total,
  });

  final String pos;
  final int rank;
  final int total;
}

class _TldLemmaCount {
  const _TldLemmaCount({required this.form, required this.count});

  final String form;
  final int count;
}

class _TldSpokenRankInfo {
  const _TldSpokenRankInfo({
    required this.rank,
    required this.total,
    required this.lemmas,
  });

  final int rank;
  final int total;
  final List<_TldLemmaCount> lemmas;
}

class _TldDefinitionInfo {
  const _TldDefinitionInfo({
    required this.examTags,
    required this.difficultyLevel,
    required this.cocaItems,
    required this.iwebItems,
    required this.spokenRankInfo,
    required this.senseRatioSlices,
    required this.posRatioSlices,
  });

  final List<String> examTags;
  final int? difficultyLevel;
  final List<_TldCorpusItem> cocaItems;
  final List<_TldCorpusItem> iwebItems;
  final _TldSpokenRankInfo? spokenRankInfo;
  final List<_SenseRatioSlice> senseRatioSlices;
  final List<_SenseRatioSlice> posRatioSlices;
}

class _RelatedSubsectionTitle extends StatelessWidget {
  const _RelatedSubsectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF344054),
      ),
    );
  }
}

class _TldDefinitionPanel extends StatefulWidget {
  const _TldDefinitionPanel({required this.info});

  final _TldDefinitionInfo info;

  @override
  State<_TldDefinitionPanel> createState() => _TldDefinitionPanelState();
}

class _TldDefinitionPanelState extends State<_TldDefinitionPanel> {
  bool _isDistributionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final bestCoca = _pickBestRank(info.cocaItems);
    final bestIweb = _pickBestRank(info.iwebItems);
    final spokenRank = info.spokenRankInfo?.rank;
    final hasDistribution =
        info.senseRatioSlices.isNotEmpty || info.posRatioSlices.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.difficultyLevel != null) ...[
            _buildLevelRow(context, info.difficultyLevel!.clamp(1, 5)),
            const SizedBox(height: 8),
          ],
          if (bestCoca != null || bestIweb != null || spokenRank != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  '词频排名',
                  style: TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (bestCoca != null) _buildInfoPill('COCA', '#$bestCoca'),
                if (bestIweb != null) _buildInfoPill('iWeb', '#$bestIweb'),
                if (spokenRank != null) _buildInfoPill('口语', '#$spokenRank'),
              ],
            ),
          ],
          if (hasDistribution) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '分布统计',
                  style: TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const ValueKey('tld-distribution-toggle'),
                  onPressed: () {
                    setState(() {
                      _isDistributionExpanded = !_isDistributionExpanded;
                    });
                  },
                  child: Text(_isDistributionExpanded ? '收起' : '展开'),
                ),
              ],
            ),
          ],
          if (hasDistribution && _isDistributionExpanded) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DistributionChartCard(
                    title: '词义分布',
                    centerText: '词义',
                    slices: info.senseRatioSlices,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DistributionChartCard(
                    title: '词性分布',
                    centerText: '词性',
                    slices: info.posRatioSlices,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelRow(BuildContext context, int level) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildInfoPill('Level', '⭐' * level),
        GestureDetector(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Level 说明'),
                content: const Text('Level 按词频进行分级。星星越多表示词频越高，通常代表这个词更常用。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('知道了'),
                  ),
                ],
              ),
            );
          },
          child: const Text(
            'Tip',
            style: TextStyle(
              color: Color(0xFF16B364),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPill(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(
          color: Color(0xFF475467),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int? _pickBestRank(List<_TldCorpusItem> items) {
    if (items.isEmpty) {
      return null;
    }
    return items
        .map((item) => item.rank)
        .reduce((left, right) => left < right ? left : right);
  }
}

class _DistributionChartCard extends StatelessWidget {
  const _DistributionChartCard({
    required this.title,
    required this.centerText,
    required this.slices,
  });

  final String title;
  final String centerText;
  final List<_SenseRatioSlice> slices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: SizedBox(
              width: 128,
              height: 128,
              child: CustomPaint(
                painter: _SenseRatioDonutPainter(
                  slices,
                  centerText: centerText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: slices
                .map(
                  (slice) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${slice.label} ${(slice.ratio * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SenseRatioDonutPainter extends CustomPainter {
  _SenseRatioDonutPainter(this.slices, {required this.centerText});

  final List<_SenseRatioSlice> slices;
  final String centerText;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeWidth = radius * 0.42;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFE9EEF5);
    canvas.drawCircle(center, radius, basePaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = 2 * math.pi * slice.ratio.clamp(0.0, 1.0);
      if (sweep <= 0) {
        continue;
      }
      arcPaint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        arcPaint,
      );
      start += sweep;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(
          color: Color(0xFF98A2B3),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SenseRatioDonutPainter oldDelegate) {
    if (oldDelegate.centerText != centerText) {
      return true;
    }
    if (oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (var index = 0; index < slices.length; index += 1) {
      final current = slices[index];
      final previous = oldDelegate.slices[index];
      if (current.label != previous.label ||
          current.ratio != previous.ratio ||
          current.color != previous.color) {
        return true;
      }
    }
    return false;
  }
}

class _WordFamilyTreePanel extends StatefulWidget {
  const _WordFamilyTreePanel({
    required this.groups,
    required this.briefDefinitions,
  });

  final List<_WordFamilyGroup> groups;
  final Map<String, String> briefDefinitions;

  @override
  State<_WordFamilyTreePanel> createState() => _WordFamilyTreePanelState();
}

class _WordFamilyTreePanelState extends State<_WordFamilyTreePanel> {
  String? _selectedNodeKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var groupIndex = 0;
          groupIndex < widget.groups.length;
          groupIndex += 1
        ) ...[
          if (groupIndex > 0) const SizedBox(height: 8),
          _buildGroup(widget.groups[groupIndex], groupIndex),
        ],
      ],
    );
  }

  Widget _buildGroup(_WordFamilyGroup group, int groupIndex) {
    final nodes = _buildNodesForGroup(group.words);
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final posText = group.pos.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (posText.isNotEmpty) ...[
          Text(
            posText,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
        ],
        for (var index = 0; index < nodes.length; index += 1) ...[
          ..._buildNodeWidgets(
            node: nodes[index],
            groupIndex: groupIndex,
            ancestorsHasNextSibling: const <bool>[],
            isLast: index == nodes.length - 1,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildNodeWidgets({
    required _WordFamilyTreeNode node,
    required int groupIndex,
    required List<bool> ancestorsHasNextSibling,
    required bool isLast,
  }) {
    final widgets = <Widget>[];
    final nodeKey = '$groupIndex:${node.wordLower}';
    final isSelected = _selectedNodeKey == nodeKey;

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ancestorsHasNextSibling.isNotEmpty)
              _WordFamilyTreeGuide(
                ancestorsHasNextSibling: ancestorsHasNextSibling,
                isLast: isLast,
              ),
            const SizedBox(width: 4),
            _WordFamilyDot(isSelected: isSelected),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                key: ValueKey('word-family-node-$nodeKey'),
                onTap: () {
                  setState(() {
                    _selectedNodeKey = isSelected ? null : nodeKey;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(
                    TextSpan(
                      children: _buildWordFamilySpans(
                        word: node.word,
                        parentWord: node.parentWord,
                      ),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isSelected) {
      final brief = widget.briefDefinitions[node.wordLower] ?? '';
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            left:
                ancestorsHasNextSibling.length * 16 +
                (ancestorsHasNextSibling.isNotEmpty ? 30 : 14),
            bottom: 6,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Text(
              _hasValue(brief) ? brief : '暂无简洁释义',
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    final nextAncestors = <bool>[...ancestorsHasNextSibling, !isLast];
    for (
      var childIndex = 0;
      childIndex < node.children.length;
      childIndex += 1
    ) {
      widgets.addAll(
        _buildNodeWidgets(
          node: node.children[childIndex],
          groupIndex: groupIndex,
          ancestorsHasNextSibling: nextAncestors,
          isLast: childIndex == node.children.length - 1,
        ),
      );
    }
    return widgets;
  }

  List<_WordFamilyTreeNode> _buildNodesForGroup(List<String> groupWords) {
    final ordered = <String>[];
    final originalByLower = <String, String>{};

    for (final word in groupWords) {
      final trimmed = word.trim();
      final lower = trimmed.toLowerCase();
      if (trimmed.isEmpty || originalByLower.containsKey(lower)) {
        continue;
      }
      originalByLower[lower] = trimmed;
      ordered.add(lower);
    }
    if (ordered.isEmpty) {
      return const <_WordFamilyTreeNode>[];
    }

    final orderIndex = <String, int>{
      for (var index = 0; index < ordered.length; index += 1)
        ordered[index]: index,
    };

    final parentByLower = <String, String?>{};
    for (final lower in ordered) {
      String? selectedParent;
      var selectedLength = -1;
      for (final candidate in ordered) {
        if (candidate == lower || candidate.length >= lower.length) {
          continue;
        }
        if (!_matchesWordFamilyDerivation(lower, candidate)) {
          continue;
        }
        if (candidate.length > selectedLength) {
          selectedParent = candidate;
          selectedLength = candidate.length;
        }
      }
      parentByLower[lower] = selectedParent;
    }

    final nodesByLower = <String, _WordFamilyTreeNode>{
      for (final lower in ordered)
        lower: _WordFamilyTreeNode(
          word: originalByLower[lower]!,
          wordLower: lower,
          parentWord: parentByLower[lower] == null
              ? null
              : originalByLower[parentByLower[lower]!],
        ),
    };

    final roots = <_WordFamilyTreeNode>[];
    for (final lower in ordered) {
      final node = nodesByLower[lower]!;
      final parentLower = parentByLower[lower];
      if (parentLower == null) {
        roots.add(node);
        continue;
      }
      nodesByLower[parentLower]?.children.add(node);
    }

    void sortNodes(List<_WordFamilyTreeNode> nodes) {
      nodes.sort(
        (left, right) => (orderIndex[left.wordLower] ?? 0).compareTo(
          orderIndex[right.wordLower] ?? 0,
        ),
      );
      for (final node in nodes) {
        sortNodes(node.children);
      }
    }

    sortNodes(roots);
    return roots;
  }

  List<InlineSpan> _buildWordFamilySpans({
    required String word,
    required String? parentWord,
  }) {
    if (!_hasValue(parentWord)) {
      return <InlineSpan>[TextSpan(text: word)];
    }

    final target = word;
    final targetLower = target.toLowerCase();
    final parentLower = parentWord!.trim().toLowerCase();
    if (parentLower.isEmpty || targetLower == parentLower) {
      return <InlineSpan>[TextSpan(text: word)];
    }

    var index = targetLower.indexOf(parentLower);
    var stemLength = parentLower.length;
    if (index < 0 && parentLower.endsWith('e') && parentLower.length > 2) {
      final stem = parentLower.substring(0, parentLower.length - 1);
      index = targetLower.indexOf(stem);
      stemLength = stem.length;
    }
    if (index >= 0 && stemLength > 0) {
      final spans = <InlineSpan>[];
      if (index > 0) {
        spans.add(
          TextSpan(
            text: target.substring(0, index),
            style: const TextStyle(
              color: Color(0xFF8AA9B4),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      spans.add(TextSpan(text: target.substring(index, index + stemLength)));
      if (index + stemLength < target.length) {
        spans.add(
          TextSpan(
            text: target.substring(index + stemLength),
            style: const TextStyle(
              color: Color(0xFF8AA9B4),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      return spans;
    }

    final sharedPrefixLength = _sharedPrefixLength(targetLower, parentLower);
    if (sharedPrefixLength >= 2 && sharedPrefixLength < target.length) {
      return <InlineSpan>[
        TextSpan(text: target.substring(0, sharedPrefixLength)),
        TextSpan(
          text: target.substring(sharedPrefixLength),
          style: const TextStyle(
            color: Color(0xFF8AA9B4),
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
    }

    return <InlineSpan>[TextSpan(text: word)];
  }

  bool _matchesWordFamilyDerivation(String wordLower, String candidateLower) {
    if (wordLower.contains(candidateLower)) {
      return true;
    }
    if (candidateLower.endsWith('e') && candidateLower.length > 2) {
      final stem = candidateLower.substring(0, candidateLower.length - 1);
      return stem.length >= 3 && wordLower.contains(stem);
    }
    return false;
  }
}

class _WordFamilyTreeNode {
  _WordFamilyTreeNode({
    required this.word,
    required this.wordLower,
    required this.parentWord,
  });

  final String word;
  final String wordLower;
  final String? parentWord;
  final List<_WordFamilyTreeNode> children = <_WordFamilyTreeNode>[];
}

class _WordFamilyDot extends StatelessWidget {
  const _WordFamilyDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0AA174) : const Color(0xFFB8C2D2),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WordFamilyTreeGuide extends StatelessWidget {
  const _WordFamilyTreeGuide({
    required this.ancestorsHasNextSibling,
    required this.isLast,
  });

  final List<bool> ancestorsHasNextSibling;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final hasNext in ancestorsHasNextSibling)
          SizedBox(
            width: 16,
            height: 24,
            child: hasNext
                ? Align(
                    alignment: Alignment.center,
                    child: Container(width: 1, color: const Color(0xFFD0D5DD)),
                  )
                : const SizedBox.shrink(),
          ),
        SizedBox(
          width: 16,
          height: 24,
          child: CustomPaint(painter: _WordFamilyBranchPainter(isLast: isLast)),
        ),
      ],
    );
  }
}

class _WordFamilyBranchPainter extends CustomPainter {
  _WordFamilyBranchPainter({required this.isLast});

  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D5DD)
      ..strokeWidth = 1;

    final centerY = size.height * 0.55;
    final centerX = size.width * 0.5;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, isLast ? centerY : size.height),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WordFamilyBranchPainter oldDelegate) {
    return oldDelegate.isLast != isLast;
  }
}

class _EtymologyCard extends StatelessWidget {
  const _EtymologyCard({required this.item});

  final _EtymologyItem item;

  @override
  Widget build(BuildContext context) {
    final highlights = <String>[
      if (_hasValue(item.century)) item.century,
      if (_hasValue(item.language)) item.language,
    ];
    final patternText = highlights
        .map((value) => _escapeRegExp(value))
        .where((value) => value.isNotEmpty)
        .join('|');

    final spans = <TextSpan>[];
    if (patternText.isEmpty) {
      spans.add(
        TextSpan(
          text: item.fullText,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
            height: 1.6,
          ),
        ),
      );
    } else {
      final matcher = RegExp(patternText, caseSensitive: false);
      var cursor = 0;
      for (final match in matcher.allMatches(item.fullText)) {
        if (match.start > cursor) {
          spans.add(
            TextSpan(
              text: item.fullText.substring(cursor, match.start),
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          );
        }
        spans.add(
          TextSpan(
            text: item.fullText.substring(match.start, match.end),
            style: const TextStyle(
              color: Color(0xFF0AA174),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        cursor = match.end;
      }
      if (cursor < item.fullText.length) {
        spans.add(
          TextSpan(
            text: item.fullText.substring(cursor),
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasValue(item.century) || _hasValue(item.language))
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_hasValue(item.century)) _buildMetaTag('年代', item.century),
                if (_hasValue(item.language))
                  _buildMetaTag('语源', item.language),
              ],
            ),
          if (_hasValue(item.century) || _hasValue(item.language))
            const SizedBox(height: 6),
          RichText(text: TextSpan(children: spans)),
        ],
      ),
    );
  }

  Widget _buildMetaTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD5E3FF)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EtymologyTabSection extends StatefulWidget {
  const _EtymologyTabSection({
    required this.etymologyItems,
    required this.onlineEtymologyWord,
    required this.onTapOpenOnlineEtymology,
  });

  final List<_EtymologyItem> etymologyItems;
  final String onlineEtymologyWord;
  final ValueChanged<String> onTapOpenOnlineEtymology;

  @override
  State<_EtymologyTabSection> createState() => _EtymologyTabSectionState();
}

class _EtymologyTabSectionState extends State<_EtymologyTabSection> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final queryWord = widget.onlineEtymologyWord.trim();
    final tabs = <String>['本地词源', if (queryWord.isNotEmpty) '在线词源'];
    final selected = _activeTabIndex.clamp(0, tabs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List<Widget>.generate(tabs.length, (index) {
            final isSelected = selected == index;
            return Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  setState(() {
                    _activeTabIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE9FFF5)
                        : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFB5F2D8)
                          : const Color(0xFFE4E7EC),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF067647)
                          : const Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        if (selected == 0) _buildLocal() else _buildOnline(queryWord),
      ],
    );
  }

  Widget _buildLocal() {
    if (widget.etymologyItems.isEmpty) {
      return const _PlaceholderBody(text: '当前词典暂无本地词源数据。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var index = 0;
          index < widget.etymologyItems.length;
          index += 1
        ) ...[
          _EtymologyCard(item: widget.etymologyItems[index]),
          if (index < widget.etymologyItems.length - 1)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildOnline(String queryWord) {
    if (queryWord.isEmpty) {
      return const _PlaceholderBody(text: '当前单词无法打开在线词源。');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '在 Etymonline 查看词源',
              style: TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('open-etymonline-button'),
            onPressed: () => widget.onTapOpenOnlineEtymology(queryWord),
            child: const Text('打开'),
          ),
        ],
      ),
    );
  }
}

class _LinkedWordsInline extends StatelessWidget {
  const _LinkedWordsInline({
    super.key,
    required this.words,
    required this.onTapWord,
  });

  final List<String> words;
  final ValueChanged<String> onTapWord;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < words.length; index += 1) ...[
            GestureDetector(
              onTap: () => onTapWord(words[index]),
              child: Text(
                words[index],
                style: const TextStyle(
                  color: Color(0xFF0AA174),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0x550AA174),
                ),
              ),
            ),
            if (index < words.length - 1)
              const Text(
                ', ',
                style: TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ThesaurusItemCard extends StatelessWidget {
  const _ThesaurusItemCard({
    super.key,
    required this.item,
    required this.onTapWord,
  });

  final _ThesaurusItem item;
  final ValueChanged<String> onTapWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onTapWord(item.word),
            child: Text(
              item.word,
              style: const TextStyle(
                color: Color(0xFF0AA174),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0x550AA174),
              ),
            ),
          ),
          if (_hasValue(item.definition)) ...[
            const SizedBox(height: 3),
            Text(
              item.definition,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          if (_hasValue(item.definitionZh)) ...[
            const SizedBox(height: 2),
            Text(
              item.definitionZh,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (item.examples.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final example in item.examples) ...[
              if (_hasValue(example.text))
                Text(
                  example.text,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              if (_hasValue(example.textZh))
                Text(
                  example.textZh,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}

class _InflectionRow extends StatelessWidget {
  const _InflectionRow({required this.item, required this.onTapWord});

  final _InflectionItem item;
  final ValueChanged<String> onTapWord;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            item.category.label,
            style: const TextStyle(color: Color(0xFF98A1B2), fontSize: 14),
          ),
        ),
        Expanded(
          child: Wrap(
            runSpacing: 4,
            children: [
              for (var index = 0; index < item.forms.length; index += 1) ...[
                GestureDetector(
                  key: ValueKey(
                    'inflection-${item.category.name}-${item.forms[index]}',
                  ),
                  onTap: () => onTapWord(item.forms[index]),
                  child: Text(
                    item.forms[index],
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 15,
                      height: 1.65,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0x5510B981),
                    ),
                  ),
                ),
                if (index < item.forms.length - 1)
                  const Text(
                    ', ',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 15,
                      height: 1.65,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PhraseOrExampleCard extends StatelessWidget {
  const _PhraseOrExampleCard({
    required this.index,
    required this.english,
    required this.translation,
  });

  final int index;
  final String english;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$index. ',
                style: const TextStyle(color: Color(0xFF99A0AE)),
              ),
              TextSpan(
                text: english,
                style: const TextStyle(
                  color: Color(0xFF212738),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 16, height: 1.42),
        ),
        if (_hasValue(translation))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              translation,
              style: const TextStyle(
                color: Color(0xFF252C3C),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _ActionPill(icon: Icons.volume_up_rounded, text: '发音'),
            SizedBox(width: 10),
            _ActionPill(icon: Icons.star_outline_rounded, text: '收藏'),
          ],
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECF0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFA0A7B5)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF9BA2B1), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EntryExampleItem {
  const _EntryExampleItem({
    required this.english,
    required this.translationZh,
    required this.audioPath,
  });

  final String english;
  final String translationZh;
  final String? audioPath;
}

class _PhraseItem {
  const _PhraseItem({required this.text, required this.translation});

  final String text;
  final String translation;
}

class _LexDbEntriesSection extends StatelessWidget {
  const _LexDbEntriesSection({required this.entry, required this.queryWord});

  final LexDbEntryDetail entry;
  final String queryWord;

  @override
  Widget build(BuildContext context) {
    return _LexDbEntryCard(entry: entry, queryWord: queryWord);
  }
}

class _EntrySwitcherBar extends StatelessWidget {
  const _EntrySwitcherBar({
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<LexDbEntryDetail> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF8E96A3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(entries.length, (index) {
            final selected = index == selectedIndex;
            final posTag = _extractEntryPosTag(entries[index], index: index);
            return Padding(
              padding: EdgeInsets.only(
                right: index == entries.length - 1 ? 0 : 4,
              ),
              child: InkWell(
                key: ValueKey('lexdb-entry-tab-$index'),
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  constraints: const BoxConstraints(minWidth: 66),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    posTag,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF0B1220)
                          : const Color(0xFFF8FAFC),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _LexDbEntryCard extends StatelessWidget {
  const _LexDbEntryCard({required this.entry, required this.queryWord});

  final LexDbEntryDetail entry;
  final String queryWord;

  @override
  Widget build(BuildContext context) {
    final senseAnchorKeys = List<GlobalKey>.generate(
      entry.senses.length,
      (_) => GlobalKey(),
    );
    final highlightWord = _hasValue(entry.headword)
        ? entry.headword
        : queryWord;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.senses.isNotEmpty) ...[
          for (var index = 0; index < entry.senses.length; index += 1) ...[
            _LexDbSenseCard(
              sense: entry.senses[index],
              inheritedLabels: entry.entryLabels,
              anchorKey: senseAnchorKeys[index],
              index: index,
              highlightWord: highlightWord,
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (entry.collocations.isNotEmpty) ...[
          if (entry.senses.isNotEmpty) const SizedBox(height: 8),
          const Text(
            '搭配',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final collocation in entry.collocations) ...[
            _LexDbCollocationCard(
              collocation: collocation,
              highlightWord: highlightWord,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _LexDbSenseCard extends StatelessWidget {
  const _LexDbSenseCard({
    required this.sense,
    required this.inheritedLabels,
    required this.anchorKey,
    required this.index,
    required this.highlightWord,
  });

  final LexDbSense sense;
  final List<LexDbLabel> inheritedLabels;
  final GlobalKey anchorKey;
  final int index;
  final String highlightWord;

  @override
  Widget build(BuildContext context) {
    final titleParts = <String>[
      if (_hasValue(sense.number)) sense.number!.trim(),
      if (_hasValue(sense.signpost)) sense.signpost!.trim(),
    ];
    final senseMetaItems = _buildSenseMetaItems(<LexDbLabel>[
      ...inheritedLabels,
      ...sense.labels,
    ]);
    final senseIndexLabel = _hasValue(sense.number)
        ? sense.number!.trim()
        : '${index + 1}';

    return Container(
      key: anchorKey,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FADF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '义项 $senseIndexLabel',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF067647),
                  ),
                ),
              ),
              if (titleParts.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titleParts.join(' '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475467),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_hasValue(sense.definition)) ...[
            const SizedBox(height: 6),
            Text(
              sense.definition,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF101828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_hasValue(sense.definitionZh)) ...[
            const SizedBox(height: 4),
            Text(
              sense.definitionZh!,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          if (senseMetaItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: senseMetaItems
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD5E3FF)),
                      ),
                      child: Text(
                        '${item.label} ${item.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (sense.examplesBeforePatterns.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final example in sense.examplesBeforePatterns) ...[
              _LexDbExampleBlock(
                example: example,
                highlightWord: highlightWord,
              ),
              const SizedBox(height: 6),
            ],
          ],
          if (sense.grammarPatterns.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final pattern in sense.grammarPatterns) ...[
              _LexDbGrammarPatternBlock(
                pattern: pattern,
                highlightWord: highlightWord,
              ),
              const SizedBox(height: 6),
            ],
          ],
          if (sense.examplesAfterPatterns.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final example in sense.examplesAfterPatterns) ...[
              _LexDbExampleBlock(
                example: example,
                highlightWord: highlightWord,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _SenseMetaItem {
  const _SenseMetaItem({required this.label, required this.value});

  final String label;
  final String value;
}

List<_SenseMetaItem> _buildSenseMetaItems(List<LexDbLabel> labels) {
  final posValues = <String>[];
  final registerValues = <String>[];
  final geoValues = <String>[];
  final domainValues = <String>[];
  final posDedupe = <String>{};
  final registerDedupe = <String>{};
  final geoDedupe = <String>{};
  final domainDedupe = <String>{};

  String normalizeType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    final slashIndex = normalized.lastIndexOf('/');
    if (slashIndex >= 0 && slashIndex + 1 < normalized.length) {
      return normalized.substring(slashIndex + 1);
    }
    return normalized;
  }

  void addValue(String value, List<String> target, Set<String> dedupe) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !dedupe.add(trimmed)) {
      return;
    }
    target.add(trimmed);
  }

  for (final label in labels) {
    final type = normalizeType(label.type);
    if (type == 'pos') {
      addValue(label.value, posValues, posDedupe);
      continue;
    }
    if (type == 'register') {
      addValue(label.value, registerValues, registerDedupe);
      continue;
    }
    if (type == 'geo') {
      addValue(label.value, geoValues, geoDedupe);
      continue;
    }
    if (type == 'domain') {
      addValue(label.value, domainValues, domainDedupe);
      continue;
    }
  }

  final items = <_SenseMetaItem>[];
  for (final value in posValues) {
    items.add(_SenseMetaItem(label: '词性', value: value));
  }
  for (final value in registerValues) {
    items.add(_SenseMetaItem(label: '语域', value: value));
  }
  for (final value in geoValues) {
    items.add(_SenseMetaItem(label: '地域', value: value));
  }
  for (final value in domainValues) {
    items.add(_SenseMetaItem(label: '领域', value: value));
  }
  return items;
}

class _LexDbExampleBlock extends StatelessWidget {
  const _LexDbExampleBlock({
    required this.example,
    required this.highlightWord,
    this.tag = '例句',
  });

  final LexDbExample example;
  final String highlightWord;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6EE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A8E69),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    ..._buildHighlightedSentenceSpans(
                      text: example.text,
                      keyword: highlightWord,
                      baseStyle: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF101828),
                      ),
                      highlightStyle: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF101828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_hasValue(example.textZh))
                      TextSpan(
                        text: '  ${example.textZh!.trim()}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LexDbGrammarPatternBlock extends StatelessWidget {
  const _LexDbGrammarPatternBlock({
    required this.pattern,
    required this.highlightWord,
  });

  final LexDbGrammarPattern pattern;
  final String highlightWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pattern.pattern,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (_hasValue(pattern.gloss)) ...[
            const SizedBox(height: 3),
            Text(
              pattern.gloss!,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (pattern.examples.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final example in pattern.examples) ...[
              _LexDbExampleBlock(
                example: example,
                tag: '语法例句',
                highlightWord: highlightWord,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}

class _LexDbCollocationCard extends StatelessWidget {
  const _LexDbCollocationCard({
    required this.collocation,
    required this.highlightWord,
  });

  final LexDbCollocation collocation;
  final String highlightWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            collocation.collocate,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          if (_hasValue(collocation.grammar)) ...[
            const SizedBox(height: 4),
            Text(
              collocation.grammar!,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
          if (_hasValue(collocation.definition)) ...[
            const SizedBox(height: 4),
            Text(
              collocation.definition!,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
          if (collocation.examples.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final example in collocation.examples) ...[
              _LexDbExampleBlock(
                example: example,
                tag: '搭配例句',
                highlightWord: highlightWord,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  panel.dictionaryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
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
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF3F5FA),
      padding: const EdgeInsets.only(top: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _DictionaryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

String _extractEntryPosTag(LexDbEntryDetail entry, {required int index}) {
  String normalize(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return '';
    }
    if (value == 'det' || value == 'determiner') {
      return 'det.';
    }
    if (value == 'adv' || value == 'adverb' || value == 'r') {
      return 'adv.';
    }
    if (value == 'noun' || value == 'n') {
      return 'noun';
    }
    if (value == 'verb' || value == 'v') {
      return 'verb';
    }
    if (value == 'adj' || value == 'adjective' || value == 'j') {
      return 'adj.';
    }
    if (value == 'prep' || value == 'preposition') {
      return 'prep.';
    }
    if (value == 'pron' || value == 'pronoun') {
      return 'pron.';
    }
    if (value == 'conj' || value == 'conjunction') {
      return 'conj.';
    }
    return value;
  }

  String? readPosFromLabels(Iterable<LexDbLabel> labels) {
    for (final label in labels) {
      if (label.type.trim().toLowerCase() != 'pos') {
        continue;
      }
      final normalized = normalize(label.value);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  final fromEntry = readPosFromLabels(entry.entryLabels);
  if (fromEntry != null) {
    return fromEntry;
  }
  for (final sense in entry.senses) {
    final fromSense = readPosFromLabels(sense.labels);
    if (fromSense != null) {
      return fromSense;
    }
  }
  return 'entry${index + 1}';
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

List<InlineSpan> _buildHighlightedSentenceSpans({
  required String text,
  required String keyword,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  final normalizedKeyword = keyword.trim();
  if (normalizedKeyword.isEmpty || text.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }

  final lowerText = text.toLowerCase();
  final lowerKeyword = normalizedKeyword.toLowerCase();
  final spans = <InlineSpan>[];
  var cursor = 0;

  while (cursor < text.length) {
    final matchedIndex = lowerText.indexOf(lowerKeyword, cursor);
    if (matchedIndex < 0) {
      if (cursor < text.length) {
        spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
      }
      break;
    }
    if (matchedIndex > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, matchedIndex), style: baseStyle),
      );
    }
    spans.add(
      TextSpan(
        text: text.substring(matchedIndex, matchedIndex + lowerKeyword.length),
        style: highlightStyle,
      ),
    );
    cursor = matchedIndex + lowerKeyword.length;
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: baseStyle));
  }

  return spans;
}

int _sharedPrefixLength(String left, String right) {
  final limit = math.min(left.length, right.length);
  var index = 0;
  while (index < limit && left.codeUnitAt(index) == right.codeUnitAt(index)) {
    index += 1;
  }
  return index;
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

String _escapeRegExp(String value) {
  return value.replaceAllMapped(
    RegExp(r'[\\^$.*+?()[\]{}|]'),
    (match) => '\\${match.group(0)!}',
  );
}
