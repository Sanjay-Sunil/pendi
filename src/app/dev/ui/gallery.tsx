"use client";

import { useState } from "react";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { EmptyState } from "@/components/ui/empty-state";
import { Input, Textarea } from "@/components/ui/input";
import { ProgressBar } from "@/components/ui/progress-bar";
import { SectionLabel } from "@/components/ui/section-label";
import { Sheet } from "@/components/ui/sheet";
import { Tabs } from "@/components/ui/tabs";

export function Gallery() {
  const [open, setOpen] = useState(false);
  return (
    <main className="mx-auto flex max-w-[720px] flex-col gap-8 px-5 py-10 md:px-10">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">UI gallery</h1>
        <ThemeToggle />
      </div>

      <section className="flex flex-col gap-3">
        <SectionLabel>Buttons</SectionLabel>
        <div className="flex flex-wrap gap-2">
          <Button>Primary</Button>
          <Button variant="secondary">Secondary</Button>
          <Button variant="ghost">Ghost</Button>
          <Button variant="danger">Danger</Button>
          <Button disabled>Disabled</Button>
        </div>
      </section>

      <section className="flex flex-col gap-3">
        <SectionLabel>Fields</SectionLabel>
        <label className="flex flex-col gap-1 text-sm">
          Link
          <Input placeholder="https://…" />
        </label>
        <label className="flex flex-col gap-1 text-sm">
          Note
          <Textarea placeholder="Two lines on what you learned" />
        </label>
        <Checkbox label="Read chapter 3" />
        <Checkbox label="Already done" defaultChecked />
      </section>

      <section className="flex flex-col gap-3">
        <SectionLabel>Card, badge, progress</SectionLabel>
        <Card className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <span className="font-medium">Designed to Scale</span>
            <Badge tone="accent">carried over</Badge>
          </div>
          <ProgressBar value={12} max={30} label="Reading progress" />
          <div className="flex gap-2">
            <Badge>12 / 30</Badge>
            <Badge tone="success">done</Badge>
            <Badge tone="danger">overdue</Badge>
          </div>
        </Card>
      </section>

      <section className="flex flex-col gap-3">
        <SectionLabel>Tabs</SectionLabel>
        <Tabs
          items={[
            { id: "a", label: "Papers", content: <p className="text-muted">Papers panel</p> },
            { id: "b", label: "Ideas", content: <p className="text-muted">Ideas panel</p> },
            { id: "c", label: "Experiments", content: <p className="text-muted">Experiments</p> },
          ]}
        />
      </section>

      <section className="flex flex-col gap-3">
        <SectionLabel>Sheet and empty state</SectionLabel>
        <Button variant="secondary" onClick={() => setOpen(true)}>
          Open sheet
        </Button>
        <Sheet open={open} onClose={() => setOpen(false)} title="Add source">
          <p className="text-muted">Sheet content goes here.</p>
        </Sheet>
        <EmptyState message="Nothing here yet." actionLabel="Add one" onAction={() => setOpen(true)} />
      </section>
    </main>
  );
}
