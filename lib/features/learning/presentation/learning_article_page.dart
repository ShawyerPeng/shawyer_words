import 'package:flutter/material.dart';
import 'package:shawyer_words/features/learning/domain/learning_article.dart';

class LearningArticlePage extends StatefulWidget {
  const LearningArticlePage({super.key, required this.article});

  final LearningArticle article;

  @override
  State<LearningArticlePage> createState() => _LearningArticlePageState();
}

class _LearningArticlePageState extends State<LearningArticlePage> {
  late String _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.article.difficultyLevels.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final article = widget.article;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x140A1633),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: [
                _ArticleHero(
                  article: article,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LevelSwitcher(
                          levels: article.difficultyLevels,
                          selectedLevel: _selectedLevel,
                          onSelected: (level) {
                            setState(() => _selectedLevel = level);
                          },
                        ),
                        const SizedBox(height: 18),
                        _AudioPanel(durationLabel: article.durationLabel),
                        const SizedBox(height: 24),
                        Text(
                          article.content,
                          key: ValueKey<String>('article-body-${article.id}'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.72,
                            color: const Color(0xFF2E3138),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

class _ArticleHero extends StatelessWidget {
  const _ArticleHero({required this.article, required this.onBack});

  final LearningArticle article;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 334,
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: article.heroGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 26,
            right: 26,
            top: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverlayCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const _OverlayCircleButton(icon: Icons.bookmark_border_rounded),
              ],
            ),
          ),
          Positioned(
            right: -10,
            top: 58,
            child: Opacity(
              opacity: 0.18,
              child: Icon(article.heroIcon, size: 220, color: Colors.white),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Color(0xE6FFFFFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.publishedAtLabel,
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCircleButton extends StatelessWidget {
  const _OverlayCircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x6B2B2F3A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _LevelSwitcher extends StatelessWidget {
  const _LevelSwitcher({
    required this.levels,
    required this.selectedLevel,
    required this.onSelected,
  });

  final List<String> levels;
  final String selectedLevel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: levels.map((level) {
          final isSelected = level == selectedLevel;
          return Expanded(
            child: GestureDetector(
              key: ValueKey<String>('difficulty-$level'),
              onTap: () => onSelected(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF18191D)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  level,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF7B808B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AudioPanel extends StatelessWidget {
  const _AudioPanel({required this.durationLabel});

  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF15171C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E4E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18191D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  durationLabel,
                  style: const TextStyle(
                    color: Color(0xFF363A43),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '1.0x',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
