"use client";

import { ExternalLink } from "lucide-react";
import { useOptimistic, useState, useTransition } from "react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Textarea } from "@/components/ui/input";
import { saveNoteAction, toggleItemAction } from "../actions";

export type RowItem = {
  id: string;
  title: string;
  url: string;
  done: boolean;
  note: string | null;
  carriedOver: boolean;
};

export function ReadingItemRow({ item }: { item: RowItem }) {
  const [done, setDone] = useOptimistic(item.done);
  const [noteOpen, setNoteOpen] = useState(false);
  const [note, setNote] = useState(item.note ?? "");
  const [, start] = useTransition();

  const toggle = () =>
    start(async () => {
      const next = !done;
      setDone(next);
      const res = await toggleItemAction({ id: item.id, done: next });
      if (!res.ok) toast.error(res.error);
      else if (next && !item.note) setNoteOpen(true);
    });

  const save = () =>
    start(async () => {
      const res = await saveNoteAction({ id: item.id, note });
      if (!res.ok) toast.error(res.error);
      setNoteOpen(false);
    });

  return (
    <li className="py-1">
      <div className="flex items-center gap-3">
        <Checkbox label={item.title} hideLabel checked={done} onChange={toggle} />
        <a
          href={item.url}
          target="_blank"
          rel="noreferrer"
          className={`group flex min-h-11 min-w-0 flex-1 items-center gap-2 ${done ? "text-muted line-through" : ""}`}
        >
          <span className="truncate">{item.title}</span>
          <ExternalLink
            size={14}
            aria-hidden
            className="shrink-0 text-muted opacity-0 group-hover:opacity-100"
          />
        </a>
        {item.carriedOver && !done ? <Badge tone="accent">carried over</Badge> : null}
      </div>
      {item.note && !noteOpen ? (
        <button
          type="button"
          onClick={() => setNoteOpen(true)}
          className="ml-8 line-clamp-2 text-left text-sm text-muted"
        >
          {item.note}
        </button>
      ) : null}
      {noteOpen ? (
        <div className="ml-8 flex flex-col gap-2 pb-2">
          <Textarea
            aria-label={`Note for ${item.title}`}
            rows={2}
            maxLength={280}
            className="min-h-0"
            placeholder="Two lines on what stuck (optional)"
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
          <div className="flex gap-2">
            <Button size="sm" onClick={save}>
              Save note
            </Button>
            <Button size="sm" variant="secondary" onClick={() => setNoteOpen(false)}>
              Skip
            </Button>
          </div>
        </div>
      ) : null}
    </li>
  );
}
