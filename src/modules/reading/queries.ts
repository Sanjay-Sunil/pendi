import "server-only";
import type { Db } from "@/lib/db";
import { listItems, listSources, type ReadingItem, type ReadingSource } from "@/lib/db/reading";
import { todaysItems, type TodayPlan } from "@/lib/domain/planner";

export type SourceOverview = {
  source: ReadingSource;
  plan: TodayPlan<ReadingItem>;
  total: number;
  done: number;
};

export async function getReadingOverview(db: Db, today: string): Promise<SourceOverview[]> {
  const [sources, items] = await Promise.all([listSources(db), listItems(db)]);
  return sources.map((source) => {
    const mine = items.filter((i) => i.source_id === source.id && i.status !== "skipped");
    return {
      source,
      plan: todaysItems(mine, source, today),
      total: mine.length,
      done: mine.filter((i) => i.status === "done").length,
    };
  });
}
