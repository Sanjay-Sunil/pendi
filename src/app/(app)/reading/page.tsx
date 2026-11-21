import { PageHeader } from "@/components/shell/page-header";
import { Card } from "@/components/ui/card";
import { getDb } from "@/lib/db";
import { todayLocal } from "@/lib/domain/dates";
import { AddSourceSheet } from "@/modules/reading/components/add-source-sheet";
import { getReadingOverview } from "@/modules/reading/queries";

export const metadata = { title: "Reading · Daybook" };
export const dynamic = "force-dynamic";

export default async function ReadingPage() {
  const overview = await getReadingOverview(await getDb(), todayLocal());
  return (
    <div className="mx-auto max-w-[960px]">
      <PageHeader label="Planner" title="Reading" actions={<AddSourceSheet />} />
      <div className="flex flex-col gap-3">
        {overview.map(({ source, plan }) => (
          <Card key={source.id}>
            <h2 className="font-medium">{source.title}</h2>
            <p className="font-mono text-sm text-muted">
              {plan.quota} {plan.quota === 1 ? "page" : "pages"} today
            </p>
          </Card>
        ))}
      </div>
    </div>
  );
}
