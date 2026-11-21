import { PageHeader } from "@/components/shell/page-header";

export const metadata = { title: "College · Daybook" };

export default function CollegePage() {
  return (
    <div className="mx-auto max-w-[960px]">
      <PageHeader label="Classes · Tasks" title="College" />
      <p className="text-muted">Coming soon.</p>
    </div>
  );
}
