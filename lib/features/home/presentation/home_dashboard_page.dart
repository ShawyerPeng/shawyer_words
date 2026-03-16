import 'package:flutter/material.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    super.key,
    required this.onOpenMe,
    required this.onOpenSearch,
  });

  final VoidCallback onOpenMe;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 124),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CircleActionButton(
                  key: const ValueKey('open-me-page'),
                  icon: Icons.menu_rounded,
                  onTap: onOpenMe,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SearchHeroButton(
                    key: const ValueKey('open-search-page'),
                    onTap: onOpenSearch,
                  ),
                ),
                const SizedBox(width: 8),
                const _CircleActionButton(
                  icon: Icons.card_giftcard_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              key: const ValueKey('home-coach-card'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140D1730),
                    blurRadius: 34,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FBF5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      size: 28,
                      color: Color(0xFF08B886),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hi，我是你的AI\n口语教练。',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '现在就开始你的口语\n练习吧！',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF60697D),
                            height: 1.22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0BC58C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 40),
                      fixedSize: const Size(64, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('聊一聊'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  '我的学习库',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFADB3C0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习广场',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 4,
                      width: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0BC58C),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8D95A9)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 206,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _CourseCard(
                    title: '地道口语1000句',
                    subtitle: '13 文章',
                    colors: [Color(0xFFD39B7B), Color(0xFF7B4C40)],
                    accent: 'Warm-up',
                  ),
                  SizedBox(width: 12),
                  _CourseCard(
                    title: '雅思阅读高频话题30篇',
                    subtitle: '30 文章',
                    colors: [Color(0xFFFFF089), Color(0xFFF6C312)],
                    accent: 'IELTS',
                    darkText: true,
                  ),
                  SizedBox(width: 12),
                  _CourseCard(
                    title: '美式口语 · 场景表达',
                    subtitle: '20 文章',
                    colors: [Color(0xFF67606D), Color(0xFF2B2D3A)],
                    accent: 'Speak',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  '全部',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded),
                const Spacer(),
                const Icon(Icons.tune_rounded, color: Color(0xFF9AA2B4)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                  Text(
                    '【使用说明】创建你的英语学习资料',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'How to create your own English learning material',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF99A0B3),
                      height: 1.24,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        '今天',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF99A0B3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFFD0D5E0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 50,
          width: 50,
          child: Icon(icon, color: const Color(0xFF252938), size: 24),
        ),
      ),
    );
  }
}

class _SearchHeroButton extends StatelessWidget {
  const _SearchHeroButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                '查单词或搜索文章',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC5CAD6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.accent,
    this.darkText = false,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final String accent;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = darkText ? const Color(0xFF1D2333) : Colors.white;

    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110D1730),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: darkText ? Colors.white.withValues(alpha: 0.5) : Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        accent,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -18,
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        height: 1.14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E95A8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
