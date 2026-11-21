import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppTab {
  const AppTab(this.label, this.child);
  final String label;
  final Widget child;
}

/// Underlined text tabs; content is laid out inline (no fixed height).
class AppTabs extends StatefulWidget {
  const AppTabs({super.key, required this.tabs, this.onChanged});

  final List<AppTab> tabs;
  final ValueChanged<int>? onChanged;

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++)
                  Semantics(
                    selected: i == _index,
                    button: true,
                    child: InkWell(
                      onTap: () {
                        setState(() => _index = i);
                        widget.onChanged?.call(i);
                      },
                      child: AnimatedContainer(
                        duration: Tokens.motion,
                        constraints: const BoxConstraints(
                          minHeight: Tokens.tapTarget,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2,
                              color: i == _index
                                  ? c.accent
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.tabs[i].label,
                          style: TextStyle(
                            fontSize: 14,
                            color: i == _index ? c.text : c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: widget.tabs[_index].child,
        ),
      ],
    );
  }
}
