import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_toggle.dart';
import '../theme/tokens.dart';
import '../ui/wordmark.dart';
import 'nav_items.dart';

/// Bottom navigation under 600dp, slim navigation rail above.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, this.banner, this.fab});

  final StatefulNavigationShell shell;
  final Widget? banner;
  final Widget? fab;

  void _go(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = MediaQuery.sizeOf(context).width >= Tokens.wideBreakpoint;
    final body = Column(
      children: [
        ?banner,
        Expanded(child: shell),
      ],
    );
    if (!wide) {
      return Scaffold(
        body: body,
        floatingActionButton: fab,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _go,
            destinations: [
              for (final n in navItems)
                NavigationDestination(icon: Icon(n.icon), label: n.label),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      floatingActionButton: fab,
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: c.border)),
            ),
            child: NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Wordmark(height: 20),
              ),
              trailing: const Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ThemeToggle(),
                  ),
                ),
              ),
              destinations: [
                for (final n in navItems)
                  NavigationRailDestination(
                    icon: Icon(n.icon),
                    label: Text(n.label),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
