import { Card } from "@/components/ui/card";
import { ProgressBar } from "@/components/ui/progress-bar";
import type { SourceOverview } from "../queries";
import { ArchiveButton } from "./archive-button";
import { ReadingItemRow } from "./reading-item-row";

export function SourceCard({ overview }: { overview: SourceOverview }) {
  const { source, plan, total, done } = overview;
  return (
    <Card className="flex flex-col gap-3">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="truncate font-medium">{source.title}</h2>
          <p className="font-mono text-xs text-muted">
            {done}/{total} read · {plan.daysLeft} {plan.daysLeft === 1 ? "day" : "days"} left
          </p>
        </div>
        <ArchiveButton id={source.id} title={source.title} />
      </div>
      <ProgressBar value={done} max={total} label={`${source.title} progress`} />
      {plan.items.length > 0 ? (
        <div>
          <p className="mb-1 font-mono text-[11px] tracking-[0.08em] text-muted uppercase">
            Today · {plan.quota} {plan.quota === 1 ? "page" : "pages"}
          </p>
          <ul>
            {plan.items.map((i) => (
              <ReadingItemRow
                key={i.id}
                item={{
                  id: i.id,
                  title: i.title,
                  url: i.url,
                  done: i.status === "done",
                  note: i.note,
                  carriedOver: i.carriedOver,
                }}
              />
            ))}
          </ul>
        </div>
      ) : (
        <p className="text-sm text-muted">All caught up. Nothing due today.</p>
      )}
    </Card>
  );
}
