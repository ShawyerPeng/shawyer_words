import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/presentation/membership_center_page.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleSettingsInfoPage(
      title: '帮助与反馈',
      message: '常见问题、使用帮助和反馈入口会在这里统一呈现。',
      icon: Icons.help_outline_rounded,
    );
  }
}
