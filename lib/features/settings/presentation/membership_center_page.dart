import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF3F5FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
