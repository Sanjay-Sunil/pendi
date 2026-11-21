import { Button } from "./button";

export function EmptyState({
  message,
  actionLabel,
  onAction,
}: {
  message: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  return (
    <div className="flex flex-col items-start gap-2 py-6">
      <p className="text-muted">{message}</p>
      {actionLabel && onAction ? (
        <Button variant="ghost" size="sm" onClick={onAction}>
          {actionLabel}
        </Button>
      ) : null}
    </div>
  );
}
