"use client";

import { Plus } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import { createSourceAction } from "../actions";
import { extractPagesAction } from "../extract-action";
import { PagePicker, type PickablePage } from "./page-picker";

function hostTitle(url: string) {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return "";
  }
}

export function AddSourceSheet() {
  const [open, setOpen] = useState(false);
  const [url, setUrl] = useState("");
  const [title, setTitle] = useState("");
  const [days, setDays] = useState("30");
  const [pages, setPages] = useState<PickablePage[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const reset = () => {
    setUrl("");
    setTitle("");
    setDays("30");
    setPages(null);
    setError(null);
  };

  const fetchPages = () =>
    start(async () => {
      setError(null);
      const res = await extractPagesAction({ url });
      if (!res.ok) {
        // A page with no section list becomes a single item.
        setPages([{ title: hostTitle(url) || url, url, selected: true }]);
        setError(`${res.error}. Added the link as a single page.`);
      } else {
        setPages(res.data.map((p) => ({ ...p, selected: true })));
      }
      if (!title) setTitle(hostTitle(url));
    });

  const create = () =>
    start(async () => {
      const picked = (pages ?? []).filter((p) => p.selected);
      const res = await createSourceAction({
        title: title || hostTitle(url),
        url,
        kind: picked.length > 1 ? "course" : "blog",
        targetDays: days,
        pages: picked.map(({ title, url }) => ({ title, url })),
      });
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success(`Added ${picked.length} page${picked.length === 1 ? "" : "s"}`);
      setOpen(false);
      reset();
    });

  const picked = pages?.filter((p) => p.selected).length ?? 0;

  return (
    <>
      <Button onClick={() => setOpen(true)} size="sm">
        <Plus size={16} aria-hidden /> Add
      </Button>
      <Sheet open={open} onClose={() => setOpen(false)} title="Add reading">
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            if (pages) create();
            else fetchPages();
          }}
        >
          <label className="flex flex-col gap-1 text-sm">
            Link
            <Input
              type="url"
              required
              placeholder="https://course.dev/"
              value={url}
              onChange={(e) => {
                setUrl(e.target.value);
                setPages(null);
              }}
            />
          </label>
          <div className="grid grid-cols-[1fr_7rem] gap-3">
            <label className="flex flex-col gap-1 text-sm">
              Title
              <Input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Optional"
              />
            </label>
            <label className="flex flex-col gap-1 text-sm">
              Days
              <Input
                type="number"
                inputMode="numeric"
                min={1}
                max={365}
                required
                value={days}
                onChange={(e) => setDays(e.target.value)}
              />
            </label>
          </div>
          {error ? (
            <p role="alert" className="text-sm text-muted">
              {error}
            </p>
          ) : null}
          {pages ? <PagePicker pages={pages} onChange={setPages} /> : null}
          <Button type="submit" disabled={pending || (pages !== null && picked === 0)}>
            {pending ? "Working…" : pages ? `Add ${picked} pages` : "Find pages"}
          </Button>
        </form>
      </Sheet>
    </>
  );
}
