import type { HTMLAttributes } from "react";
import { cn } from "@/lib/cn";

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "rounded-[var(--radius-card)] border border-border bg-surface p-4 transition-shadow duration-150 ease-out hover:shadow-[inset_0_1px_0_0_var(--surface-2)]",
        className,
      )}
      {...props}
    />
  );
}
