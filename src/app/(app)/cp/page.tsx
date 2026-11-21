import { PageHeader } from "@/components/shell/page-header";

export const metadata = { title: "CP · Daybook" };

export default function CPPage() {
  return (
    <div className="mx-auto max-w-[960px]">
      <PageHeader label="Practice" title="CP" />
      <p className="text-muted">Coming soon.</p>
    </div>
  );
}
