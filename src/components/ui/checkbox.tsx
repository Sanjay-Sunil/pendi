import { Check } from "lucide-react";
import type { InputHTMLAttributes } from "react";
import { cn } from "@/lib/cn";

export type CheckboxProps = Omit<InputHTMLAttributes<HTMLInputElement>, "type"> & {
  label: string;
  hideLabel?: boolean;
};

export function Checkbox({ label, hideLabel, className, ...props }: CheckboxProps) {
  return (
    <label className={cn("inline-flex min-h-11 cursor-pointer items-center gap-3", className)}>
      <span className="relative inline-flex size-5 shrink-0">
        <input
          type="checkbox"
          className="peer size-5 cursor-pointer appearance-none rounded-[6px] border border-border bg-surface transition-colors duration-150 ease-out checked:border-accent checked:bg-accent"
          {...props}
        />
        <Check
          size={14}
          strokeWidth={3}
          aria-hidden
          className="pointer-events-none absolute inset-0 m-auto text-accent-fg opacity-0 peer-checked:opacity-100"
        />
      </span>
      <span className={cn(hideLabel && "sr-only")}>{label}</span>
    </label>
  );
}
