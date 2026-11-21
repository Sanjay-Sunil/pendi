"use client";

import { X } from "lucide-react";
import { useEffect, useRef, type ReactNode } from "react";

/** Bottom sheet on mobile, centered panel on desktop. Built on native <dialog>. */
export function Sheet({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      onClose={onClose}
      onClick={(e) => e.target === ref.current && onClose()}
      aria-label={title}
      className="m-0 mt-auto w-full max-w-none rounded-t-[var(--radius-card)] border border-border bg-surface p-0 text-text backdrop:bg-black/50 md:m-auto md:max-w-lg md:rounded-[var(--radius-card)]"
    >
      <div className="flex items-center justify-between border-b border-border px-5 py-3">
        <h2 className="font-medium">{title}</h2>
        <button
          type="button"
          onClick={onClose}
          aria-label="Close"
          className="inline-flex size-11 items-center justify-center text-muted hover:text-text"
        >
          <X size={18} />
        </button>
      </div>
      <div className="max-h-[75dvh] overflow-y-auto px-5 py-4 pb-[max(1rem,env(safe-area-inset-bottom))]">
        {children}
      </div>
    </dialog>
  );
}
