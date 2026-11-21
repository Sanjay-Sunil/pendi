"use client";

import { ArrowDown, ArrowUp } from "lucide-react";
import { Checkbox } from "@/components/ui/checkbox";

export type PickablePage = { title: string; url: string; selected: boolean };

export function PagePicker({
  pages,
  onChange,
}: {
  pages: PickablePage[];
  onChange: (pages: PickablePage[]) => void;
}) {
  const selected = pages.filter((p) => p.selected).length;
  const all = selected === pages.length;

  const move = (i: number, d: -1 | 1) => {
    const j = i + d;
    if (j < 0 || j >= pages.length) return;
    const next = [...pages];
    [next[i], next[j]] = [next[j], next[i]];
    onChange(next);
  };

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <Checkbox
          label={`Select all (${selected}/${pages.length})`}
          checked={all}
          onChange={() => onChange(pages.map((p) => ({ ...p, selected: !all })))}
        />
      </div>
      <ul className="flex flex-col divide-y divide-border rounded-[var(--radius-control)] border border-border">
        {pages.map((p, i) => (
          <li key={p.url} className="flex items-center gap-2 pr-1 pl-3">
            <Checkbox
              className="min-w-0 flex-1"
              label={p.title}
              checked={p.selected}
              onChange={() =>
                onChange(pages.map((q, k) => (k === i ? { ...q, selected: !q.selected } : q)))
              }
            />
            <button
              type="button"
              aria-label={`Move ${p.title} up`}
              onClick={() => move(i, -1)}
              disabled={i === 0}
              className="inline-flex size-9 items-center justify-center text-muted hover:text-text disabled:opacity-30"
            >
              <ArrowUp size={16} />
            </button>
            <button
              type="button"
              aria-label={`Move ${p.title} down`}
              onClick={() => move(i, 1)}
              disabled={i === pages.length - 1}
              className="inline-flex size-9 items-center justify-center text-muted hover:text-text disabled:opacity-30"
            >
              <ArrowDown size={16} />
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
