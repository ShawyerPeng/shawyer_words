import 'package:flutter/material.dart';

class SearchEntryBar extends StatelessWidget {
  const SearchEntryBar({
    super.key,
    this.shellKey,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.hintText = '查单词或搜索文章',
    this.trailing,
  });

  final Key? shellKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final String hintText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final shellTapHandler = readOnly ? onTap : null;
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFFC5CAD6),
      fontWeight: FontWeight.w600,
    );
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF252938),
      fontWeight: FontWeight.w600,
    );

    return Container(
      key: shellKey,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: shellTapHandler,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: Color(0xFF252938),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: readOnly
                      ? Text(
                          hintText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: hintStyle,
                        )
                      : TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          autofocus: autofocus,
                          onTap: onTap,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: hintText,
                            hintStyle: hintStyle,
                          ),
                          style: textStyle,
                        ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
