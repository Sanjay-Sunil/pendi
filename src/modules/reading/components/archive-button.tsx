"use client";

import { useTransition } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { archiveSourceAction } from "../actions";

export function ArchiveButton({ id, title }: { id: string; title: string }) {
  const [pending, start] = useTransition();
  return (
    <Button
      size="sm"
      variant="secondary"
      disabled={pending}
      aria-label={`Archive ${title}`}
      onClick={() =>
        start(async () => {
          const res = await archiveSourceAction({ id });
          if (res.ok) toast.success(`Archived ${title}`);
          else toast.error(res.error);
        })
      }
    >
      Archive
    </Button>
  );
}
