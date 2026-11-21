import { PageHeader } from "@/components/shell/page-header";
import { getDb } from "@/lib/db";
import { todayLocal } from "@/lib/domain/dates";
import { AddSourceSheet } from "@/modules/reading/components/add-source-sheet";
import { SourceCard } from "@/modules/reading/components/source-card";
import { getReadingOverview } from "@/modules/reading/queries";

export const metadata = { title: "Reading · Daybook" };
export const dynamic = "force-dynamic";

export default async function ReadingPage() {
  const overview = await getReadingOverview(await getDb(), todayLocal());
  const pagesToday = overview.reduce((n, o) => n + o.plan.items.length, 0);
  return (
    <div className="mx-auto max-w-[960px]">
      <PageHeader
        label={`Planner · ${pagesToday} ${pagesToday === 1 ? "page" : "pages"} today`}
        title="Reading"
        actions={<AddSourceSheet />}
      />
      {overview.length === 0 ? (
        <p className="text-muted">No reading yet. Add a course or blog link to start.</p>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {overview.map((o) => (
            <SourceCard key={o.source.id} overview={o} />
          ))}
        </div>
      )}
    </div>
  );
}
