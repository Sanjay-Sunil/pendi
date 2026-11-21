import { PageHeader } from "@/components/shell/page-header";

export const metadata = { title: "Today · Daybook" };

export default function TodayPage() {
  return (
    <div className="mx-auto max-w-[720px]">
      <PageHeader label="Daily" title="Today" />
      <p className="text-muted">Coming soon.</p>
    </div>
  );
}
