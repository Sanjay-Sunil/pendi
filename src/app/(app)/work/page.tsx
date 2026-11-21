import { PageHeader } from "@/components/shell/page-header";

export const metadata = { title: "Work · Daybook" };

export default function WorkPage() {
  return (
    <div className="mx-auto max-w-[960px]">
      <PageHeader label="Hackathons · Research" title="Work" />
      <p className="text-muted">Coming soon.</p>
    </div>
  );
}
