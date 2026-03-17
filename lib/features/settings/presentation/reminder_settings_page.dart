import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';

class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key, required this.controller});

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
                      '学习提醒',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('App提醒'),
                        value: settings.reminderEnabled,
                        onChanged: (value) => controller.updateReminder(
                          enabled: value,
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                        ),
                      ),
                      ListTile(
                        title: const Text('提醒时间'),
                        subtitle: Text(
                          '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}',
                        ),
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
}
