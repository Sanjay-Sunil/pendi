import type { HTMLAttributes } from "react";
import { cn } from "@/lib/cn";

type Tone = "neutral" | "accent" | "success" | "danger";

const tones: Record<Tone, string> = {
  neutral: "border-border text-muted",
  accent: "border-accent/40 bg-accent-soft text-accent",
  success: "border-border text-success",
  danger: "border-border text-danger",
};

export function Badge({
  tone = "neutral",
  className,
  ...props
}: HTMLAttributes<HTMLSpanElement> & { tone?: Tone }) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-mono text-[11px] tracking-wide",
        tones[tone],
        className,
      )}
      {...props}
    />
  );
}
