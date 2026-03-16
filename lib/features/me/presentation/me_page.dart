import 'package:flutter/material.dart';

class MePage extends StatelessWidget {
  const MePage({
    super.key,
    this.dictionaryLibraryManagementPageBuilder,
  });

  final WidgetBuilder? dictionaryLibraryManagementPageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    key: const ValueKey('close-me-page'),
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(
                      height: 56,
                      width: 56,
                      child: Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '我的',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140A1633),
                    blurRadius: 26,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0BC58C), Color(0xFF7BE7C0)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '登录',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '同步学习进度、收藏和搜索历史',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF7E8799),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '通用设置',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF7B8497),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _MenuTile(
              icon: Icons.menu_book_outlined,
              title: '词典库管理',
              subtitle: '显示顺序、隐藏词库、词典详情',
              onTap: dictionaryLibraryManagementPageBuilder == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: dictionaryLibraryManagementPageBuilder!,
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            const _MenuTile(
              icon: Icons.settings_outlined,
              title: '通知与外观',
              subtitle: '通知、外观、学习提醒',
            ),
            const SizedBox(height: 14),
            const _MenuTile(
              icon: Icons.workspace_premium_outlined,
              title: '会员中心',
              subtitle: '订阅、权益、兑换码',
            ),
            const SizedBox(height: 14),
            const _MenuTile(
              icon: Icons.help_outline_rounded,
              title: '帮助与反馈',
              subtitle: '常见问题、意见反馈',
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF0BC58C)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8790A2),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF949CAD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
