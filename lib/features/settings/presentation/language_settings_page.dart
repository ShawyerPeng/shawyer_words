import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_language_option.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = appLanguageOptionFromStoredValue(
          controller.state.settings.myLanguage,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: SettingsHeader(
                    title: '语言设置',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFEAE3DB),
                ),
                const _LanguageSupportHint(),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: AppLanguageOption.values.length,
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: Divider(
                          height: 1,
                          thickness: 0.8,
                          color: Color(0xFFF0E9E1),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final option = AppLanguageOption.values[index];
                        return _LanguageOptionTile(
                          option: option,
                          selected: option == selected,
                          onTap: () => controller.updateMyLanguage(option),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppLanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('language-option-${option.name}'),
        onTap: onTap,
        splashColor: const Color(0x0D2B1912),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    appLanguageLabel(option),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2B1912),
                    ),
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF5D9A63),
                      size: 22,
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

class _LanguageSupportHint extends StatelessWidget {
  const _LanguageSupportHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            appLanguageSubtitle(AppLanguageOption.system) ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFA8A09A),
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
