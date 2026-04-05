import 'package:flutter/material.dart';
import 'package:shawyer_words/features/learning/presentation/grammar_page.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 124),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学习',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择一个模块，进入你的专项练习。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF7E869B),
              ),
            ),
            const SizedBox(height: 20),
            _FeaturedLearningCard(
              key: const ValueKey<String>('open-grammar-page'),
              title: '语法',
              subtitle: 'Idioms, phrases, proverbs and more',
              badge: 'Featured',
              color: const Color(0xFFDCCDEE),
              accentColor: const Color(0xFF5C2F8C),
              icon: Icons.auto_stories_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const GrammarPage()),
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MiniLearningCard(
                    title: '口语',
                    subtitle: 'Daily speaking drills',
                    color: const Color(0xFFC6F0E5),
                    icon: Icons.graphic_eq_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MiniLearningCard(
                    title: '词汇',
                    subtitle: 'Theme word packs',
                    color: const Color(0xFFFFE6A8),
                    icon: Icons.local_library_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              '继续探索',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            const _LearningListTile(
              title: '短语训练营',
              subtitle: 'Collocations and common expressions',
              color: Color(0xFFF7D8E6),
              icon: Icons.text_snippet_outlined,
            ),
            const SizedBox(height: 14),
            const _LearningListTile(
              title: '阅读拆解',
              subtitle: 'Long sentences and structure notes',
              color: Color(0xFFD9E4FF),
              icon: Icons.chrome_reader_mode_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedLearningCard extends StatelessWidget {
  const _FeaturedLearningCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140D1730),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF464A59),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 86,
                  width: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 42, color: accentColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniLearningCard extends StatelessWidget {
  const _MiniLearningCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF21263A)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF646B7D),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningListTile extends StatelessWidget {
  const _LearningListTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A1633),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF20263A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7D8698),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A0B3)),
        ],
      ),
    );
  }
}
