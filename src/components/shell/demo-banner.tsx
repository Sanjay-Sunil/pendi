import { isDemoMode } from "@/lib/supabase/env";

export function DemoBanner() {
  if (!isDemoMode()) return null;
  return (
    <div
      role="status"
      className="border-b border-border bg-surface px-5 py-2 text-center font-mono text-[11px] tracking-[0.08em] text-muted uppercase"
    >
      Demo mode · data resets when the server restarts
    </div>
  );
}
