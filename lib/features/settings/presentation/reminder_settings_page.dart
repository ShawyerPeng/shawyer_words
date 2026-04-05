import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';

class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({
    super.key,
    required this.controller,
    this.pickTime = _showReminderTimePicker,
  });

  final SettingsController controller;
  final Future<TimeOfDay?> Function(BuildContext, TimeOfDay initialTime)
  pickTime;

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
                  title: '学习提醒',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      _CompactReminderSwitchTile(
                        title: 'App提醒',
                        value: settings.reminderEnabled,
                        onChanged: (value) => value
                            ? controller
                                  .enableReminderAndOpenNotificationSettings()
                            : controller.updateReminderEnabled(false),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 0.9,
                          color: Color(0xFFF1ECE6),
                        ),
                      ),
                      SettingsActionTile(
                        title: '提醒时间',
                        value:
                            '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}',
                        onTap: () => _pickReminderTime(context, settings),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    AppSettings settings,
  ) async {
    final selected = await pickTime(
      context,
      TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute),
    );
    if (selected == null) {
      return;
    }

    await controller.updateReminder(
      enabled: settings.reminderEnabled,
      hour: selected.hour,
      minute: selected.minute,
    );
  }
}

Future<TimeOfDay?> _showReminderTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
) {
  return showTimePicker(context: context, initialTime: initialTime);
}

class _CompactReminderSwitchTile extends StatelessWidget {
  const _CompactReminderSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2B1912),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
