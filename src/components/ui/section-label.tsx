import type { HTMLAttributes } from "react";
import { cn } from "@/lib/cn";

export function SectionLabel({ className, ...props }: HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h2
      className={cn("font-mono text-[11px] tracking-[0.08em] text-muted uppercase", className)}
      {...props}
    />
  );
}
