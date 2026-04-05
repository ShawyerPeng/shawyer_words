import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';
import 'package:shawyer_words/features/settings/presentation/help_feedback_page.dart';
import 'package:shawyer_words/features/settings/presentation/learning_settings_page.dart';
import 'package:shawyer_words/features/settings/presentation/membership_center_page.dart';
import 'package:shawyer_words/features/settings/presentation/study_statistics_page.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class MePage extends StatelessWidget {
  const MePage({
    super.key,
    required this.settingsController,
    this.studyPlanController,
    this.studyRepository,
    this.wordKnowledgeRepository,
    this.fsrsRepository,
    this.wordDetailPageBuilder,
    this.dictionaryLibraryManagementPageBuilder,
    this.showCloseButton = true,
  });

  final SettingsController settingsController;
  final StudyPlanController? studyPlanController;
  final StudyRepository? studyRepository;
  final WordKnowledgeRepository? wordKnowledgeRepository;
  final FsrsRepository? fsrsRepository;
  final WordDetailPageBuilder? wordDetailPageBuilder;
  final WidgetBuilder? dictionaryLibraryManagementPageBuilder;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = showCloseButton
        ? 26.0
        : mediaQuery.padding.bottom + 132;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            showCloseButton ? 12 : 24,
            20,
            bottomInset,
          ),
          children: [
            if (showCloseButton) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    key: const ValueKey('close-me-page'),
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            const _ProfileHeader(),
            const SizedBox(height: 22),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ShowcaseCard(
                    title: '收藏',
                    eyebrow: '暂无收藏',
                    description: '收藏的对话、图片、文件等会展示在这',
                    countLabel: '0',
                    tone: _ShowcaseTone.favorite,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ShowcaseCard(
                    title: '录音',
                    eyebrow: '暂无录音',
                    description: '使用录音笔记录的内容会展示在这',
                    countLabel: '0',
                    tone: _ShowcaseTone.recording,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ShowcaseCard(
                    title: '文件',
                    eyebrow: '暂无文件',
                    description: '发送或保存的文件附件会展示在这',
                    countLabel: '0',
                    tone: _ShowcaseTone.file,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BenefitSettingsBlock(
              onMembershipTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MembershipCenterPage(),
                ),
              ),
              settingRows: [
                _ActionRow(
                  key: const ValueKey('me-entry-account-settings'),
                  icon: Icons.person_outline_rounded,
                  title: '账号设置',
                  subtitle: null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PlaceholderSectionScaffold(
                        title: '账号设置',
                        description: '管理账号信息、登录方式与同步相关设置。',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                  ),
                ),
                _ActionRow(
                  key: const ValueKey('me-entry-general-settings'),
                  icon: Icons.palette_outlined,
                  title: '通用设置',
                  subtitle: null,
                  trailingText: '',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          GeneralSettingsPage(controller: settingsController),
                    ),
                  ),
                ),
                _ActionRow(
                  key: const ValueKey('me-entry-learning-settings'),
                  icon: Icons.graphic_eq_rounded,
                  title: '学习设置',
                  subtitle: null,
                  trailingText: '',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LearningSettingsPage(
                        controller: settingsController,
                        studyPlanController: studyPlanController,
                        wordKnowledgeRepository: wordKnowledgeRepository,
                        fsrsRepository: fsrsRepository,
                        wordDetailPageBuilder: wordDetailPageBuilder,
                      ),
                    ),
                  ),
                ),
                _ActionRow(
                  key: const ValueKey('me-entry-dictionary-management'),
                  icon: Icons.menu_book_outlined,
                  title: '词典库管理',
                  subtitle: null,
                  onTap: dictionaryLibraryManagementPageBuilder == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: dictionaryLibraryManagementPageBuilder!,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ActionGroup(
              children: [
                _ActionRow(
                  key: const ValueKey('me-entry-study-statistics'),
                  icon: Icons.query_stats_rounded,
                  title: '数据统计',
                  subtitle: null,
                  onTap:
                      studyPlanController == null ||
                          studyRepository == null ||
                          wordKnowledgeRepository == null ||
                          fsrsRepository == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StudyStatisticsPage(
                              controller: settingsController,
                              studyPlanController: studyPlanController!,
                              studyRepository: studyRepository!,
                              wordKnowledgeRepository: wordKnowledgeRepository!,
                              fsrsRepository: fsrsRepository!,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ActionGroup(
              children: [
                _ActionRow(
                  key: const ValueKey('me-entry-help-feedback'),
                  icon: Icons.person_add_alt_1_rounded,
                  title: '邀请好友',
                  subtitle: null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpFeedbackPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.15, -0.25),
                    radius: 0.95,
                    colors: [
                      Color(0xFF34D1C6),
                      Color(0xFF1182BF),
                      Color(0xFF0E355E),
                    ],
                    stops: [0.08, 0.42, 1],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8DFD7),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 27,
                      color: Color(0xFF28211C),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D6D4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF7F3EE),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: Color(0xFF9A928C),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: [
              Text(
                '登录',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF2D1810),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB3A69E),
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ShowcaseTone { favorite, recording, file }

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.countLabel,
    required this.tone,
  });

  final String title;
  final String eyebrow;
  final String description;
  final String countLabel;
  final _ShowcaseTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      _ShowcaseTone.favorite => const _ShowcasePalette(
        background: Color(0xFFFFF2C6),
        border: Color(0xFFEACF7A),
        eyebrow: Color(0xFFC4B6A0),
        body: Color(0xFFAC9F90),
      ),
      _ShowcaseTone.recording => const _ShowcasePalette(
        background: Color(0xFFF8F0E2),
        border: Color(0xFFE8DCCD),
        eyebrow: Color(0xFFC4B5A4),
        body: Color(0xFFACA08F),
      ),
      _ShowcaseTone.file => const _ShowcasePalette(
        background: Color(0xFFF9FAFD),
        border: Color(0xFFEAE8EC),
        eyebrow: Color(0xFFC2BCC2),
        body: Color(0xFFA7A3AA),
      ),
    };

    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08A48A74),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (tone == _ShowcaseTone.recording)
            const Positioned.fill(child: _PaperNoise()),
          if (tone == _ShowcaseTone.recording)
            const Positioned(
              left: 18,
              right: 18,
              bottom: 38,
              child: _WaveDecoration(),
            ),
          if (tone == _ShowcaseTone.file)
            const Positioned(top: 0, right: 0, child: _FoldedCorner()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: palette.eyebrow,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.body,
                  fontSize: 10.5,
                  height: 1.28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E120D),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Text(
                    countLabel,
                    style: const TextStyle(
                      color: Color(0xFFA89F98),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowcasePalette {
  const _ShowcasePalette({
    required this.background,
    required this.border,
    required this.eyebrow,
    required this.body,
  });

  final Color background;
  final Color border;
  final Color eyebrow;
  final Color body;
}

class _PaperNoise extends StatelessWidget {
  const _PaperNoise();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _NoisePainter()));
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA38C6A).withValues(alpha: 0.05);
    for (var x = 0; x < size.width; x += 4) {
      for (var y = 0; y < size.height; y += 4) {
        final seed = (x * 37 + y * 17) % 11;
        if (seed < 3) {
          canvas.drawCircle(
            Offset(x.toDouble(), y.toDouble()),
            0.5 + (seed * 0.2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveDecoration extends StatelessWidget {
  const _WaveDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List<Widget>.generate(19, (index) {
          final height = 4 + math.sin(index / 2) * 6 + (index.isEven ? 3 : 0);
          return Container(
            width: 2,
            height: height.abs(),
            decoration: BoxDecoration(
              color: const Color(0xFFD9CAB6),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}

class _FoldedCorner extends StatelessWidget {
  const _FoldedCorner();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _FoldedCornerClipper(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.98),
              const Color(0xFFF2F2F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFE7E4E9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitSettingsBlock extends StatelessWidget {
  const _BenefitSettingsBlock({
    required this.onMembershipTap,
    required this.settingRows,
  });

  final VoidCallback onMembershipTap;
  final List<Widget> settingRows;

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      color: Colors.white,
      shadowColor: const Color(0x1A0A1633),
      elevation: 4,
      clipper: const _BenefitTicketClipper(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF14C877),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 10,
                        top: 6,
                        child: Container(
                          width: 20,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(16, 24),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 6,
                        child: Container(
                          width: 13,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF14C877),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(14, 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '会员中心',
                        style: TextStyle(
                          color: Color(0xFF2A1912),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '同步学习进度、收藏和搜索历史',
                        style: TextStyle(
                          color: Color(0xFFA7A09A),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: const Color(0xFF6D584D),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: onMembershipTap,
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      child: Text(
                        '福利中心',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _CouponDivider(),
          ...settingRows,
        ],
      ),
    );
  }
}

class _CouponDivider extends StatelessWidget {
  const _CouponDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _ticketDividerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Align(alignment: Alignment.center, child: _DottedDivider()),
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 7).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              count,
              (_) => Container(
                width: 2.5,
                height: 2.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7E0DA),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0A1633),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: Icon(icon, size: 22, color: const Color(0xFF695448)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2B1912),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFFA49C95),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: Color(0xFFB8AEA7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFAEA39C),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoldedCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.64, 0);
    path.lineTo(size.width, size.height * 0.36);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

const double _ticketCornerRadius = 22;
const double _ticketDividerHeight = 14;
const double _ticketNotchWidth = 12;
const double _ticketHeaderHeight = 58;

class _BenefitTicketClipper extends CustomClipper<Path> {
  const _BenefitTicketClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = _ticketCornerRadius;
    final notchHalfHeight = _ticketDividerHeight / 2;
    final notchCenterY = _ticketHeaderHeight + notchHalfHeight;

    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, notchCenterY - notchHalfHeight);
    path.lineTo(size.width - _ticketNotchWidth, notchCenterY);
    path.lineTo(size.width, notchCenterY + notchHalfHeight);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, notchCenterY + notchHalfHeight);
    path.lineTo(_ticketNotchWidth, notchCenterY);
    path.lineTo(0, notchCenterY - notchHalfHeight);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BenefitTicketClipper oldClipper) => false;
}
