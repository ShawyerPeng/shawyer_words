import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final Set<int> _expandedIndexes = <int>{};

  static const List<_FaqItem> _faqItems = <_FaqItem>[
    _FaqItem(
      question: '一个账号可支持几台设备同时使用？',
      answer: '一个账号支持同时在多台移动端设备（手机、平板电脑等）上登录，还支持在网页端同时使用。',
    ),
    _FaqItem(question: '我想要退货退款怎么办？'),
    _FaqItem(question: '如何获取牛津初阶词典使用权益？'),
    _FaqItem(question: '如何获取牛津中阶词典使用权益？'),
    _FaqItem(question: '如何获取树冠英语·精读计划使用权益？'),
    _FaqItem(question: '订阅的万邦会员权益到期如何续费（或取消续费）？'),
    _FaqItem(question: '网页版地址是什么？'),
    _FaqItem(question: '实体书上的防伪溯源码损坏/无效怎么办？'),
    _FaqItem(question: '购买或使用出现问题如何联系解决？'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            _buildHeader(context),
            const SizedBox(height: 26),
            const Text(
              '常见问题',
              style: TextStyle(
                color: Color(0xFF121826),
                fontSize: 40 / 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List<Widget>.generate(_faqItems.length, (index) {
                  final item = _faqItems[index];
                  final expanded = _expandedIndexes.contains(index);
                  return _FaqRow(
                    item: item,
                    expanded: expanded,
                    isLast: index == _faqItems.length - 1,
                    onTap: () {
                      setState(() {
                        if (expanded) {
                          _expandedIndexes.remove(index);
                        } else {
                          _expandedIndexes.add(index);
                        }
                      });
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('help-center-back'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 24),
                ),
              ),
            ),
          ),
          const Text(
            '帮助中心',
            style: TextStyle(
              color: Color(0xFF121826),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, this.answer});

  final String question;
  final String? answer;
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.item,
    required this.expanded,
    required this.isLast,
    required this.onTap,
  });

  final _FaqItem item;
  final bool expanded;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: const TextStyle(
                        color: Color(0xFF121826),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.chevron_right_rounded,
                    color: const Color(0xFF9AA0AA),
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded && item.answer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.answer!,
              style: const TextStyle(
                color: Color(0xFF757D8C),
                fontSize: 17,
                height: 1.45,
              ),
            ),
          ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF0F2F5),
            ),
          ),
      ],
    );
  }
}
