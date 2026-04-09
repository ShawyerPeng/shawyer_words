import 'package:flutter/material.dart';
import 'package:shawyer_words/features/study_plan/domain/study_task_source.dart';

class StudySessionHeader extends StatelessWidget {
  const StudySessionHeader({
    super.key,
    required this.progressText,
    required this.progressValue,
    required this.progressPercent,
    required this.remainingCount,
    required this.onBack,
    required this.onMarkMastered,
    this.compact = false,
  });

  final String progressText;
  final double progressValue;
  final int progressPercent;
  final int remainingCount;
  final VoidCallback onBack;
  final VoidCallback? onMarkMastered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        compact ? 12 : 14,
        14,
        compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0C1730),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              StudySessionIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习中',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1E2430),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '已学 $progressText · 还剩 $remainingCount 个',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8C95A5),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onMarkMastered,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('标记熟悉'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2F80ED),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 8 : 10,
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Text(
                progressText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF697386),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: const ValueKey('study-session-progress-bar'),
                    value: progressValue.clamp(0, 1),
                    minHeight: compact ? 8 : 9,
                    backgroundColor: const Color(0xFFE9EEF5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10C28E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$progressPercent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF0B8B63),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudySessionTaskSourceBanner extends StatelessWidget {
  const StudySessionTaskSourceBanner({
    super.key,
    required this.source,
    this.compact = false,
  });

  final StudyTaskSource source;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = switch (source) {
      StudyTaskSource.newWord => (
        shortLabel: '新学',
        longLabel: '新学任务',
        hint: '先建立第一印象，再决定是否需要重复巩固',
        icon: Icons.auto_stories_rounded,
        background: const Color(0xFFEAF2FF),
        foreground: const Color(0xFF2F80ED),
      ),
      StudyTaskSource.probeWord => (
        shortLabel: '抽查',
        longLabel: '熟词抽查',
        hint: '确认熟词是否仍然稳定掌握，判断可以更严格',
        icon: Icons.bolt_rounded,
        background: const Color(0xFFF3E8FF),
        foreground: const Color(0xFF8E44AD),
      ),
      StudyTaskSource.mustReview || StudyTaskSource.normalReview => (
        shortLabel: '复习',
        longLabel: '复习任务',
        hint: '根据遗忘节奏回顾旧词，尽量按真实记忆作答',
        icon: Icons.history_rounded,
        background: const Color(0xFFFFF1E6),
        foreground: const Color(0xFFFF8A00),
      ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 11 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0C1730),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(style.icon, size: 20, color: style.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: style.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        style.shortLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: style.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      style.longLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1D2430),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  style.hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8A93A4),
                    height: 1.35,
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

class StudySessionDecisionButton extends StatelessWidget {
  const StudySessionDecisionButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = Color.lerp(Colors.white, accentColor, 0.08)!;
    final borderColor = Color.lerp(Colors.white, accentColor, 0.22)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: onTap == null ? Colors.white : backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: SizedBox(
            height: compact ? 78 : 92,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                compact ? 10 : 14,
                14,
                compact ? 10 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF171D2D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7F8899),
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudySessionCompletedView extends StatelessWidget {
  const StudySessionCompletedView({
    super.key,
    required this.forgotCount,
    required this.fuzzyCount,
    required this.knownCount,
    required this.masteredCount,
  });

  final int forgotCount;
  final int fuzzyCount;
  final int knownCount;
  final int masteredCount;

  @override
  Widget build(BuildContext context) {
    final totalCount = forgotCount + fuzzyCount + knownCount + masteredCount;
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120C1730),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 30,
                color: Color(0xFF10C28E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '学习完成',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171A20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本轮掌握情况',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF8A93A4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共完成 $totalCount 个单词判断',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF99A2B2),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StudySessionSummaryTile(
                  label: '已掌握',
                  count: masteredCount,
                  color: const Color(0xFF2F80ED),
                ),
                StudySessionSummaryTile(
                  label: '认识',
                  count: knownCount,
                  color: const Color(0xFF10C28E),
                ),
                StudySessionSummaryTile(
                  label: '模糊',
                  count: fuzzyCount,
                  color: const Color(0xFFFFA63D),
                ),
                StudySessionSummaryTile(
                  label: '忘记',
                  count: forgotCount,
                  color: const Color(0xFFF05A55),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10C28E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudySessionIconButton extends StatelessWidget {
  const StudySessionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F6FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: const Color(0xFF202632)),
        ),
      ),
    );
  }
}

class StudySessionInfoPill extends StatelessWidget {
  const StudySessionInfoPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF596173),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StudySessionSummaryTile extends StatelessWidget {
  const StudySessionSummaryTile({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 76) / 2;
    final softBackground = Color.lerp(Colors.white, color, 0.1)!;

    return Container(
      width: width.clamp(120, 220).toDouble(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: softBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF171A20),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$label $count 个',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF697386)),
          ),
        ],
      ),
    );
  }
}
