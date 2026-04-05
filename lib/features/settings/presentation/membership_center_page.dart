import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';

class MembershipCenterPage extends StatelessWidget {
  const MembershipCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleSettingsInfoPage(
      title: '会员中心',
      message: '订阅、权益和兑换码能力会在这里统一管理。',
      icon: Icons.workspace_premium_outlined,
    );
  }
}

class SimpleSettingsInfoPage extends StatelessWidget {
  const SimpleSettingsInfoPage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsHeader(
                title: title,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 48, color: const Color(0xFF0BB58A)),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
