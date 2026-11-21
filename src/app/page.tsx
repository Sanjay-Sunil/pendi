import { ThemeToggle } from "@/components/theme/theme-toggle";

export default function Home() {
  return (
    <main className="mx-auto max-w-[720px] px-5 py-10 md:px-10">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Daybook</h1>
        <ThemeToggle />
      </div>
      <p className="mt-2 font-mono text-[11px] tracking-[0.08em] text-muted uppercase">
        Design tokens
      </p>
      <button
        type="button"
        className="mt-6 h-11 rounded-[var(--radius-control)] bg-accent px-4 font-medium text-accent-fg"
      >
        Demo button
      </button>
    </main>
  );
}
