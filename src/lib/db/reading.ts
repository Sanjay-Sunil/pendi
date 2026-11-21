import type { Row } from "./schema";
import type { Db } from "./types";

export type ReadingSource = Row<"reading_sources">;
export type ReadingItem = Row<"reading_items">;
export type NewPage = { title: string; url: string };

export async function listSources(db: Db, status: ReadingSource["status"] = "active") {
  return db.list("reading_sources", { where: { status }, orderBy: "created_at" });
}

export async function listItems(db: Db, sourceId?: string) {
  return db.list("reading_items", {
    where: sourceId ? { source_id: sourceId } : {},
    orderBy: "position",
  });
}

/** Appends pages after the source's last position, skipping URLs it already has. */
export async function addItems(db: Db, sourceId: string, pages: NewPage[]) {
  const existing = await listItems(db, sourceId);
  const seen = new Set(existing.map((i) => i.url));
  let position = existing.reduce((max, i) => Math.max(max, i.position), -1);
  const fresh = pages.filter((p) => {
    if (seen.has(p.url)) return false;
    seen.add(p.url);
    return true;
  });
  return db.insert(
    "reading_items",
    fresh.map((p) => ({ source_id: sourceId, title: p.title, url: p.url, position: ++position })),
  );
}

export async function createSource(
  db: Db,
  input: Pick<ReadingSource, "title" | "url" | "kind" | "start_date" | "target_days">,
  pages: NewPage[],
) {
  const [source] = await db.insert("reading_sources", [input]);
  const items = await addItems(db, source.id, pages);
  return { source, items };
}

export async function setItemDone(
  db: Db,
  id: string,
  done: boolean,
  now: Date = new Date(),
  note?: string,
) {
  return db.update("reading_items", id, {
    status: done ? "done" : "todo",
    done_at: done ? now.toISOString() : null,
    ...(note !== undefined ? { note: note || null } : {}),
  });
}

export async function setItemNote(db: Db, id: string, note: string) {
  return db.update("reading_items", id, { note: note.trim() || null });
}

export async function archiveSource(db: Db, id: string) {
  return db.update("reading_sources", id, { status: "archived" });
}
