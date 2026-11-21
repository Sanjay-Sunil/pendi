import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const navItems = [
  NavItem('/today', 'Today', LucideIcons.sun),
  NavItem('/reading', 'Reading', LucideIcons.bookOpen),
  NavItem('/cp', 'CP', LucideIcons.code),
  NavItem('/work', 'Work', LucideIcons.briefcase),
  NavItem('/college', 'College', LucideIcons.graduationCap),
];
