import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shawyer_words/features/dictionary/domain/word_entry.dart';
import 'package:shawyer_words/features/study/application/study_session_controller.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study/presentation/study_session_widgets.dart';
import 'package:shawyer_words/features/study/presentation/word_card_view.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_audio_source_resolver.dart';
import 'package:shawyer_words/features/word_detail/data/dictionary_sound_player.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class StudySessionPage extends StatefulWidget {
  const StudySessionPage({
    super.key,
    required this.controller,
    required this.wordDetailPageBuilder,
  });

  factory StudySessionPage.forBook({
    Key? key,
    required List<WordEntry> entries,
    required StudyRepository studyRepository,
    required FsrsRepository fsrsRepository,
    required WordKnowledgeRepository wordKnowledgeRepository,
    required WordDetailPageBuilder wordDetailPageBuilder,
    Map<String, StudyTaskSource> entrySourcesByWord =
        const <String, StudyTaskSource>{},
  }) {
    return StudySessionPage(
      key: key,
      controller: StudySessionController(
        entries: entries,
        studyRepository: studyRepository,
        fsrsRepository: fsrsRepository,
        wordKnowledgeRepository: wordKnowledgeRepository,
        entrySourcesByWord: entrySourcesByWord,
      ),
      wordDetailPageBuilder: wordDetailPageBuilder,
    );
  }

  final StudySessionController controller;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  State<StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends State<StudySessionPage> {
  bool _isSubmitting = false;
  late final DictionarySoundPlayer _soundPlayer;

  @override
  void initState() {
    super.initState();
    _soundPlayer = DictionarySoundPlayer();
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final entry = state.currentEntry;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          body: SafeArea(
            child: entry == null
                ? StudySessionCompletedView(
                    forgotCount: state.forgotCount,
                    fuzzyCount: state.fuzzyCount,
                    knownCount: state.knownCount,
                    masteredCount: state.masteredCount,
                  )
                : _buildActiveSession(
                    context: context,
                    entry: entry,
                    state: state,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSession({
    required BuildContext context,
    required WordEntry entry,
    required StudySessionState state,
  }) {
    final totalCount = state.entries.length;
    final currentStep = state.currentIndex + 1;
    final progressValue = totalCount == 0 ? 0.0 : currentStep / totalCount;
    final remainingCount = (totalCount - currentStep).clamp(0, totalCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 640;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            isCompact ? 8 : 10,
            18,
            isCompact ? 14 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudySessionHeader(
                progressText: '$currentStep / $totalCount',
                progressValue: progressValue,
                progressPercent: (progressValue * 100).round(),
                remainingCount: remainingCount,
                compact: isCompact,
                onBack: () => Navigator.of(context).pop(),
                onMarkMastered: _isSubmitting
                    ? null
                    : () => _handleDecision(
                        action: widget.controller.markMastered,
                      ),
              ),
              SizedBox(height: isCompact ? 10 : 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _SwipeableWordHeroCard(
                  key: ValueKey<String>('study-session-hero-${entry.id}'),
                  entry: entry,
                  definitionRevealed: state.definitionRevealed,
                  compact: isCompact,
                  enabled: !_isSubmitting,
                  onSwipeForgot: () => _handleDecision(
                    action: widget.controller.markForgot,
                  ),
                  onSwipeKnown: () => _handleDecision(
                    action: widget.controller.markKnown,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 14 : 18),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: SingleChildScrollView(
                    key: ValueKey<String>(
                      '${entry.id}-${state.definitionRevealed}',
                    ),
                    child: WordCardView(
                      entry: entry,
                      onOpenDetail: () => _openWordDetail(context, entry),
                      onPlayExampleAudio: _buildPlayExampleAudio(entry),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 8 : 12),
              if (!isCompact)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    '根据当前回忆状态选择判断，系统会据此安排下一次出现时间。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8A93A4),
                      height: 1.35,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: StudySessionDecisionButton(
                      label: '忘记',
                      subtitle: '完全想不起来',
                      compact: isCompact,
                      accentColor: const Color(0xFFF05A55),
                      onTap: _isSubmitting
                          ? null
                          : () => _handleDecision(
                              action: widget.controller.markForgot,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StudySessionDecisionButton(
                      label: '模糊',
                      subtitle: '有印象但不稳定',
                      compact: isCompact,
                      accentColor: const Color(0xFFFFA63D),
                      onTap: _isSubmitting
                          ? null
                          : () => _handleDecision(
                              action: widget.controller.markFuzzy,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StudySessionDecisionButton(
                      label: '认识',
                      subtitle: '能正确回忆出来',
                      compact: isCompact,
                      accentColor: const Color(0xFF18B984),
                      onTap: _isSubmitting
                          ? null
                          : () => _handleDecision(
                              action: widget.controller.markKnown,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDecision({
    required Future<void> Function() action,
  }) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    HapticFeedback.selectionClick();
    await action();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _openWordDetail(BuildContext context, WordEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.wordDetailPageBuilder(entry.word, entry),
      ),
    );
  }

  VoidCallback? _buildPlayExampleAudio(WordEntry entry) {
    final source = normalizeDictionaryAudioSource(entry.exampleAudioPath);
    if (source == null) {
      return null;
    }
    return () => _playExampleAudio(source);
  }

  Future<void> _playExampleAudio(String source) async {
    try {
      await _soundPlayer.playSource(source);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('例句音频播放失败')));
    }
  }
}

class _SwipeableWordHeroCard extends StatefulWidget {
  const _SwipeableWordHeroCard({
    super.key,
    required this.entry,
    required this.definitionRevealed,
    required this.compact,
    required this.enabled,
    required this.onSwipeForgot,
    required this.onSwipeKnown,
  });

  final bool enabled;
  final WordEntry entry;
  final bool definitionRevealed;
  final bool compact;
  final Future<void> Function() onSwipeForgot;
  final Future<void> Function() onSwipeKnown;

  @override
  State<_SwipeableWordHeroCard> createState() => _SwipeableWordHeroCardState();
}

class _SwipeableWordHeroCardState extends State<_SwipeableWordHeroCard> {
  static const double _swipeThreshold = 120;
  static const Duration _settleDuration = Duration(milliseconds: 220);
  static const Duration _flyOutDuration = Duration(milliseconds: 180);

  double _dragDx = 0;
  Duration _animationDuration = Duration.zero;
  bool _isAnimatingOut = false;

  @override
  void didUpdateWidget(covariant _SwipeableWordHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _dragDx = 0;
      _animationDuration = Duration.zero;
      _isAnimatingOut = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction = _directionForOffset(_dragDx);
    final progress = (_dragDx.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final angle = (_dragDx / 560).clamp(-0.24, 0.24);

    return GestureDetector(
      key: const ValueKey('study-session-word-card'),
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: widget.enabled && !_isAnimatingOut
          ? _handleDragUpdate
          : null,
      onHorizontalDragEnd: widget.enabled && !_isAnimatingOut
          ? _handleDragEnd
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    _SwipeHintBadge(
                      label: '忘记',
                      active: direction == _SwipeDirection.left,
                      alignment: Alignment.centerLeft,
                      color: const Color(0xFFF05A55),
                      progress: direction == _SwipeDirection.left
                          ? progress
                          : 0,
                    ),
                    const Spacer(),
                    _SwipeHintBadge(
                      label: '认识',
                      active: direction == _SwipeDirection.right,
                      alignment: Alignment.centerRight,
                      color: const Color(0xFF18B984),
                      progress: direction == _SwipeDirection.right
                          ? progress
                          : 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translateByDouble(_dragDx, 0, 0, 1)
              ..rotateZ(angle),
            child: _WordHeroCard(
              entry: widget.entry,
              definitionRevealed: widget.definitionRevealed,
              compact: widget.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _animationDuration = Duration.zero;
      _dragDx += details.delta.dx;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final direction = _directionForOffset(_dragDx);
    if (direction == null) {
      setState(() {
        _dragDx = 0;
        _animationDuration = _settleDuration;
      });
      return;
    }

    _animateOut(direction);
  }

  _SwipeDirection? _directionForOffset(double dx) {
    if (dx <= -_swipeThreshold) {
      return _SwipeDirection.left;
    }
    if (dx >= _swipeThreshold) {
      return _SwipeDirection.right;
    }
    return null;
  }

  Future<void> _animateOut(_SwipeDirection direction) async {
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      _isAnimatingOut = true;
      _animationDuration = _flyOutDuration;
      _dragDx = direction == _SwipeDirection.left ? -width : width;
    });
    await Future<void>.delayed(_flyOutDuration);
    if (!mounted) {
      return;
    }
    if (direction == _SwipeDirection.left) {
      await widget.onSwipeForgot();
    } else {
      await widget.onSwipeKnown();
    }
  }
}

enum _SwipeDirection { left, right }

class _SwipeHintBadge extends StatelessWidget {
  const _SwipeHintBadge({
    required this.label,
    required this.active,
    required this.alignment,
    required this.color,
    required this.progress,
  });

  final String label;
  final bool active;
  final Alignment alignment;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: active ? (0.24 + clampedProgress * 0.76).clamp(0.24, 1.0) : 0,
      child: Align(
        alignment: alignment,
        child: Transform.scale(
          scale: 0.92 + clampedProgress * 0.08,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordHeroCard extends StatelessWidget {
  const _WordHeroCard({
    required this.entry,
    required this.definitionRevealed,
    required this.compact,
  });

  final WordEntry entry;
  final bool definitionRevealed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideText = definitionRevealed
        ? '释义已经展开，可以继续结合例句判断是否真正记住。'
        : '先尝试独立回忆释义，再点击下方释义卡查看答案。';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, compact ? 6 : 10, 8, compact ? 2 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: definitionRevealed
                    ? const Color(0xFFEAF8F2)
                    : const Color(0xFFF1F4F7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                definitionRevealed ? '已揭晓释义' : '先回忆释义',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: definitionRevealed
                      ? const Color(0xFF0B8B63)
                      : const Color(0xFF7A8598),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          Center(
            child: Text(
              entry.word,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171A20),
                letterSpacing: 0.2,
                height: 1.05,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((entry.pronunciation ?? '').trim().isNotEmpty)
                  StudySessionInfoPill(
                    label: '美 ${entry.pronunciation}'.trim(),
                  ),
                if ((entry.partOfSpeech ?? '').trim().isNotEmpty)
                  StudySessionInfoPill(label: entry.partOfSpeech!.trim()),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  definitionRevealed
                      ? Icons.lightbulb_rounded
                      : Icons.visibility_outlined,
                  size: 18,
                  color: definitionRevealed
                      ? const Color(0xFF10C28E)
                      : const Color(0xFF7A8598),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guideText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7D8797),
                      height: 1.35,
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
}
