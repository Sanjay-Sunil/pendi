import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'section_label.dart';

/// Scrollable page body with the standard header, padding and max width.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.label,
    this.actions = const [],
    this.maxWidth = Tokens.maxPage,
    this.onRefresh,
  });

  final String title;
  final String? label;
  final List<Widget> actions;
  final List<Widget> children;
  final double maxWidth;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Tokens.wideBreakpoint;
    final pad = wide ? Tokens.pagePadWide : Tokens.pagePadPhone;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null) SectionLabel(label!),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
    return SafeArea(
      bottom: false,
      child: onRefresh == null
          ? list
          : RefreshIndicator(onRefresh: onRefresh!, child: list),
    );
  }
}
