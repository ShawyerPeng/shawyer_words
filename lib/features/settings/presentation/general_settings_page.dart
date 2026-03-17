import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';

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
          backgroundColor: const Color(0xFFF3F5FA),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              children: [
                SettingsHeader(
                  title: '通用设置',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: '显示与语言',
                  children: [
                    SettingsActionTile(
                      title: '我的语言',
                      value: settings.myLanguage,
                      onTap: () => showSingleChoiceSheet<String>(
                        context,
                        title: '我的语言',
                        currentValue: settings.myLanguage,
                        options: const <SettingsOption<String>>[
                          SettingsOption(value: '中文', label: '中文'),
                          SettingsOption(value: 'English', label: 'English'),
                        ],
                        onSelected: controller.updateMyLanguage,
                      ),
                    ),
                    SettingsActionTile(
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
                    SettingsActionTile(
                      title: '主题',
                      value: settings.themeName == 'default'
                          ? '默认'
                          : settings.themeName,
                      onTap: () => showSingleChoiceSheet<String>(
                        context,
                        title: '主题',
                        currentValue: settings.themeName,
                        options: const <SettingsOption<String>>[
                          SettingsOption(value: 'default', label: '默认'),
                          SettingsOption(value: 'forest', label: 'Forest'),
                          SettingsOption(value: 'sunrise', label: 'Sunrise'),
                        ],
                        onSelected: controller.updateThemeName,
                      ),
                    ),
                    SettingsActionTile(
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
                      title: '恢复默认大小',
                      onTap: controller.restoreDefaultFontScale,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '系统',
                  children: [
                    SettingsActionTile(
                      title: '语言',
                      value: '跳转到系统设置',
                      onTap: controller.openSystemLanguageSettings,
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

class SettingsOption<T> {
  const SettingsOption({required this.value, required this.label});

  final T value;
  final String label;
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onBack,
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
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.title,
    this.value,
    this.onTap,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: value == null ? null : Text(value!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
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
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(title)),
            for (final option in options)
              ListTile(
                title: Text(option.label),
                trailing: option.value == currentValue
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () async {
                  await onSelected(option.value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
      );
    },
  );
}
