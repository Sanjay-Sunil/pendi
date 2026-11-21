"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import { cn } from "@/lib/cn";
import { NAV_ITEMS, isActive } from "./nav-items";

export function SideRail() {
  const pathname = usePathname();
  return (
    <nav
      aria-label="Primary"
      className="sticky top-0 hidden h-dvh w-20 shrink-0 flex-col items-center gap-1 border-r border-border py-6 md:flex"
    >
      <Link
        href="/today"
        aria-label="Daybook home"
        className="mb-6 font-mono text-lg font-semibold text-accent"
      >
        D
      </Link>
      {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
        const active = isActive(pathname, href);
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? "page" : undefined}
            className={cn(
              "relative flex w-16 flex-col items-center gap-1 rounded-[var(--radius-control)] py-2 text-[11px] transition-colors duration-150 ease-out",
              active ? "text-accent" : "text-muted hover:text-text",
            )}
          >
            {active ? (
              <span aria-hidden className="absolute top-2 -left-2 h-6 w-0.5 rounded-full bg-accent" />
            ) : null}
            <Icon size={20} aria-hidden />
            {label}
          </Link>
        );
      })}
      <div className="mt-auto">
        <ThemeToggle />
      </div>
    </nav>
  );
}
