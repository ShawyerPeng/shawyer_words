import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_language_option.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/domain/app_theme_palette.dart';
import 'package:shawyer_words/features/settings/presentation/help_feedback_page.dart';
import 'package:shawyer_words/features/settings/presentation/language_settings_page.dart';
import 'package:shawyer_words/features/shared/presentation/placeholder_section_page.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.state.settings;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                SettingsHeader(
                  title: '通用设置',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 14),
                SettingsGroup(
                  title: '外观与显示',
                  children: [
                    SettingsActionTile(
                      icon: Icons.contrast_rounded,
                      title: '外观',
                      value: switch (settings.appearanceMode) {
                        AppAppearanceMode.system => '自动',
                        AppAppearanceMode.light => '浅色',
                        AppAppearanceMode.dark => '深色',
                      },
                      onTap: () => showSingleChoiceSheet<AppAppearanceMode>(
                        context,
                        title: '外观',
                        currentValue: settings.appearanceMode,
                        options: const <SettingsOption<AppAppearanceMode>>[
                          SettingsOption(
                            value: AppAppearanceMode.system,
                            label: '自动',
                          ),
                          SettingsOption(
                            value: AppAppearanceMode.light,
                            label: '浅色',
                          ),
                          SettingsOption(
                            value: AppAppearanceMode.dark,
                            label: '深色',
                          ),
                        ],
                        onSelected: controller.updateAppearance,
                      ),
                    ),
                    Builder(
                      builder: (tileContext) => SettingsActionTile(
                        key: const ValueKey('general-settings-theme-tile'),
                        icon: Icons.palette_outlined,
                        title: '主题',
                        trailing: _ThemeValueIndicator(
                          palette: appThemePaletteFor(settings.themeName),
                        ),
                        onTap: () => showThemeChoicePopup(
                          tileContext,
                          currentThemeName: settings.themeName,
                          onSelected: controller.updateThemeName,
                        ),
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.text_fields_rounded,
                      title: '字体大小',
                      value: switch (settings.fontScale) {
                        AppFontScale.normal => '普通',
                        AppFontScale.medium => '中等',
                        AppFontScale.large => '加大',
                      },
                      onTap: () => showSingleChoiceSheet<AppFontScale>(
                        context,
                        title: '字体大小',
                        currentValue: settings.fontScale,
                        options: const <SettingsOption<AppFontScale>>[
                          SettingsOption(
                            value: AppFontScale.normal,
                            label: '普通',
                          ),
                          SettingsOption(
                            value: AppFontScale.medium,
                            label: '中等',
                          ),
                          SettingsOption(
                            value: AppFontScale.large,
                            label: '加大',
                          ),
                        ],
                        onSelected: controller.updateFontScale,
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.restart_alt_rounded,
                      title: '恢复默认大小',
                      onTap: controller.restoreDefaultFontScale,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SettingsGroup(
                  title: '语言与音色',
                  children: [
                    SettingsActionTile(
                      key: const ValueKey('general-settings-language-tile'),
                      icon: Icons.translate_rounded,
                      title: '语言设置',
                      value: appLanguageLabel(
                        appLanguageOptionFromStoredValue(settings.myLanguage),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              LanguageSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SettingsGroup(
                  title: '系统',
                  children: [
                    SettingsActionTile(
                      icon: Icons.language_rounded,
                      title: '系统语言',
                      value: '系统设置',
                      onTap: controller.openSystemLanguageSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SettingsGroup(
                  title: '其他设置',
                  children: [
                    SettingsActionTile(
                      icon: Icons.tune_rounded,
                      title: '个性化',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlaceholderSectionScaffold(
                            title: '个性化',
                            description: '管理推荐内容、展示偏好和个性化体验设置。',
                            icon: Icons.tune_rounded,
                          ),
                        ),
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.notifications_none_rounded,
                      title: '消息通知',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlaceholderSectionScaffold(
                            title: '消息通知',
                            description: '管理系统通知、学习提醒与消息触达方式。',
                            icon: Icons.notifications_none_rounded,
                          ),
                        ),
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.shield_outlined,
                      title: '数据与隐私',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlaceholderSectionScaffold(
                            title: '数据与隐私',
                            description: '查看数据使用说明、隐私策略和权限管理选项。',
                            icon: Icons.shield_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SettingsGroup(
                  title: '帮助与关于',
                  children: [
                    SettingsActionTile(
                      icon: Icons.help_outline_rounded,
                      title: '帮助与反馈',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpFeedbackPage(),
                        ),
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.info_outline_rounded,
                      title: '关于应用',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlaceholderSectionScaffold(
                            title: '关于应用',
                            description: '查看应用版本、功能说明和产品相关信息。',
                            icon: Icons.info_outline_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlaceholderSectionScaffold extends StatelessWidget {
  const PlaceholderSectionScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: SettingsHeader(
                title: title,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: PlaceholderSectionPage(
                title: title,
                description: description,
                icon: icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsOption<T> {
  const SettingsOption({required this.value, required this.label});

  final T value;
  final String label;
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.backButtonKey,
  });

  final String title;
  final VoidCallback onBack;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: backButtonKey,
                onTap: onBack,
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  height: 40,
                  width: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2A1912),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFACA39C),
          ),
        ),
        const SizedBox(height: 6),
        Container(
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
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 60, right: 16),
                    child: Divider(
                      height: 1,
                      thickness: 0.9,
                      color: Color(0xFFF1ECE6),
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

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final titleColor = enabled
        ? const Color(0xFF2B1912)
        : const Color(0xFFBDB4AE);
    final valueColor = enabled
        ? const Color(0xFFB2AAA4)
        : const Color(0xFFD1C9C2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: subtitle == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: Icon(icon, size: 22, color: const Color(0xFF695448)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFA49C95),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (value != null) ...[
                  Text(
                    value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: valueColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: valueColor,
                    size: 22,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeValueIndicator extends StatelessWidget {
  const _ThemeValueIndicator({required this.palette});

  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: palette.indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          palette.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFB8AEA7),
          ),
        ),
        const SizedBox(width: 6),
        const _ThemePickerChevron(),
      ],
    );
  }
}

class _ThemePickerChevron extends StatelessWidget {
  const _ThemePickerChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.unfold_more_rounded,
      size: 18,
      color: Color(0xFFAEA39C),
    );
  }
}

Future<void> showThemeChoicePopup(
  BuildContext tileContext, {
  required String currentThemeName,
  required Future<void> Function(String themeName) onSelected,
}) async {
  final tileBox = tileContext.findRenderObject() as RenderBox?;
  final overlayBox =
      Navigator.of(tileContext).overlay?.context.findRenderObject()
          as RenderBox?;
  if (tileBox == null || overlayBox == null) {
    return;
  }

  final anchorRect =
      tileBox.localToGlobal(Offset.zero, ancestor: overlayBox) & tileBox.size;

  await showGeneralDialog<void>(
    context: tileContext,
    barrierDismissible: true,
    barrierLabel: '关闭主题选择',
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ThemeChoicePopup(
        anchorRect: anchorRect,
        currentThemeName: normalizeAppThemeName(currentThemeName),
        onSelected: onSelected,
      );
    },
  );
}

class _ThemeChoicePopup extends StatelessWidget {
  const _ThemeChoicePopup({
    required this.anchorRect,
    required this.currentThemeName,
    required this.onSelected,
  });

  final Rect anchorRect;
  final String currentThemeName;
  final Future<void> Function(String themeName) onSelected;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const popupWidth = 208.0;
    const itemHeight = 42.0;
    const popupTopOffset = 6.0;
    final popupHeight = appThemePalettes.length * itemHeight;
    final left = (anchorRect.right - popupWidth - 10).clamp(
      16.0,
      screenSize.width - popupWidth - 16.0,
    );
    final top = (anchorRect.bottom + popupTopOffset).clamp(
      16.0,
      screenSize.height - popupHeight - 16.0,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: popupWidth,
          child: Material(
            key: const ValueKey('theme-choice-popup'),
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x160A1633),
            borderRadius: BorderRadius.circular(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    var index = 0;
                    index < appThemePalettes.length;
                    index++
                  ) ...[
                    _ThemeChoiceRow(
                      palette: appThemePalettes[index],
                      selected: appThemePalettes[index].id == currentThemeName,
                      onTap: () async {
                        await onSelected(appThemePalettes[index].id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    if (index != appThemePalettes.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 0.9,
                        color: Color(0xFFF0ECE7),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeChoiceRow extends StatelessWidget {
  const _ThemeChoiceRow({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('theme-option-${palette.id}'),
      onTap: onTap,
      child: SizedBox(
        height: 42,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: palette.indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  palette.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2C1A13),
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF2C1A13),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showSingleChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T currentValue,
  required List<SettingsOption<T>> options,
  required Future<void> Function(T value) onSelected,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _SingleChoiceSheet<T>(
            title: title,
            currentValue: currentValue,
            options: options,
            onSelected: onSelected,
          ),
        ),
      );
    },
  );
}

class _SingleChoiceSheet<T> extends StatelessWidget {
  const _SingleChoiceSheet({
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final T currentValue;
  final List<SettingsOption<T>> options;
  final Future<void> Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE7DED5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2B1912),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < options.length; index++) ...[
            _SingleChoiceRow<T>(
              option: options[index],
              selected: options[index].value == currentValue,
              onTap: () async {
                await onSelected(options[index].value);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            if (index != options.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.9,
                  color: Color(0xFFF1ECE6),
                ),
              ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SingleChoiceRow<T> extends StatelessWidget {
  const _SingleChoiceRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SettingsOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2B1912),
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF2B1912),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
