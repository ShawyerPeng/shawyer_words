import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/study_statistics.dart';

class StudyStatisticsPage extends StatelessWidget {
  const StudyStatisticsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: SafeArea(
        child: FutureBuilder<StudyStatistics>(
          future: controller.loadStatistics(),
          builder: (context, snapshot) {
            final stats =
                snapshot.data ??
                const StudyStatistics(
                  heatmapDays: <HeatmapDay>[],
                  vocabularyGrowth: <MonthlyVocabularyPoint>[],
                  everydayTrend: <DailyTrendPoint>[],
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
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
                      '数据统计',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '跟踪每日学习记录，每一点努力都算数',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _ChartCard(
                  title: 'Heatmap',
                  icon: Icons.grid_view_rounded,
                  child: _HeatmapGrid(days: stats.heatmapDays),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Vocabulary Growth Trend',
                  icon: Icons.show_chart_rounded,
                  child: _MonthlyGrowthChart(points: stats.vocabularyGrowth),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Everyday Trend',
                  icon: Icons.multiline_chart_rounded,
                  child: _DailyTrendChart(points: stats.everydayTrend),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0BB58A)),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days});

  final List<HeatmapDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox(height: 76);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final day in days)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: switch (day.count) {
                0 => const Color(0xFFE7F5EE),
                1 => const Color(0xFFC8ECD8),
                2 || 3 => const Color(0xFF73CF9B),
                _ => const Color(0xFF1EAD69),
              },
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _MonthlyGrowthChart extends StatelessWidget {
  const _MonthlyGrowthChart({required this.points});

  final List<MonthlyVocabularyPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxValue = points.fold<int>(
      1,
      (max, point) => point.totalWords > max ? point.totalWords : max,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final point in points) ...[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 120 * point.totalWords / maxValue,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF0BB58A), Color(0xFF7CE3BF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(point.label),
              ],
            ),
          ),
          if (point != points.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _DailyTrendChart extends StatelessWidget {
  const _DailyTrendChart({required this.points});

  final List<DailyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxValue = points.fold<int>(1, (max, point) {
      final candidate = point.newWords > point.reviewWords
          ? point.newWords
          : point.reviewWords;
      return candidate > max ? candidate : max;
    });

    return Column(
      children: [
        Row(
          children: const [
            _LegendDot(color: Color(0xFFE2554C), label: '学习新词数'),
            SizedBox(width: 16),
            _LegendDot(color: Color(0xFF27B268), label: '复习词数'),
          ],
        ),
        const SizedBox(height: 14),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text(point.label)),
                Expanded(
                  child: Row(
                    children: [
                      _ValueBar(
                        color: const Color(0xFFE2554C),
                        width: point.newWords == 0
                            ? 8
                            : 120 * point.newWords / maxValue,
                      ),
                      const SizedBox(width: 8),
                      _ValueBar(
                        color: const Color(0xFF27B268),
                        width: point.reviewWords == 0
                            ? 8
                            : 120 * point.reviewWords / maxValue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _ValueBar extends StatelessWidget {
  const _ValueBar({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
