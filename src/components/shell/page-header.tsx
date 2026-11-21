import type { ReactNode } from "react";

export function PageHeader({
  label,
  title,
  actions,
}: {
  label?: string;
  title: string;
  actions?: ReactNode;
}) {
  return (
    <header className="mb-8 flex items-end justify-between gap-4">
      <div>
        {label ? (
          <p className="font-mono text-[11px] tracking-[0.08em] text-muted uppercase">{label}</p>
        ) : null}
        <h1 className="mt-1 text-2xl font-semibold tracking-tight">{title}</h1>
      </div>
      {actions}
    </header>
  );
}
