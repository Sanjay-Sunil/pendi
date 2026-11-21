import { BookOpen, Briefcase, Code2, GraduationCap, Sun, type LucideIcon } from "lucide-react";

export type NavItem = { href: string; label: string; icon: LucideIcon };

export const NAV_ITEMS: NavItem[] = [
  { href: "/today", label: "Today", icon: Sun },
  { href: "/reading", label: "Reading", icon: BookOpen },
  { href: "/cp", label: "CP", icon: Code2 },
  { href: "/work", label: "Work", icon: Briefcase },
  { href: "/college", label: "College", icon: GraduationCap },
];

export function isActive(pathname: string, href: string) {
  return pathname === href || pathname.startsWith(`${href}/`);
}
