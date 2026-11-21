"use client";

import { useId, useState, type KeyboardEvent, type ReactNode } from "react";
import { cn } from "@/lib/cn";

export type TabItem = { id: string; label: string; content: ReactNode };

export function Tabs({
  items,
  defaultId,
  onChange,
}: {
  items: TabItem[];
  defaultId?: string;
  onChange?: (id: string) => void;
}) {
  const base = useId();
  const [active, setActive] = useState(defaultId ?? items[0]?.id);

  const select = (id: string) => {
    setActive(id);
    onChange?.(id);
  };

  const onKey = (e: KeyboardEvent, i: number) => {
    const d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
    if (!d) return;
    const next = items[(i + d + items.length) % items.length];
    select(next.id);
    document.getElementById(`${base}-tab-${next.id}`)?.focus();
  };

  return (
    <div>
      <div role="tablist" className="flex gap-1 border-b border-border">
        {items.map((t, i) => (
          <button
            key={t.id}
            id={`${base}-tab-${t.id}`}
            role="tab"
            type="button"
            aria-selected={active === t.id}
            aria-controls={`${base}-panel-${t.id}`}
            tabIndex={active === t.id ? 0 : -1}
            onClick={() => select(t.id)}
            onKeyDown={(e) => onKey(e, i)}
            className={cn(
              "-mb-px min-h-11 border-b-2 px-3 text-sm transition-colors duration-150 ease-out",
              active === t.id
                ? "border-accent text-text"
                : "border-transparent text-muted hover:text-text",
            )}
          >
            {t.label}
          </button>
        ))}
      </div>
      {items.map((t) => (
        <div
          key={t.id}
          id={`${base}-panel-${t.id}`}
          role="tabpanel"
          aria-labelledby={`${base}-tab-${t.id}`}
          hidden={active !== t.id}
          className="pt-4"
        >
          {t.content}
        </div>
      ))}
    </div>
  );
}
