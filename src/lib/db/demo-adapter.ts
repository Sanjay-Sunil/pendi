import { CASCADES, COLUMN_DEFAULTS, UNIQUE_KEYS } from "./defaults";
import type { Row, TableName } from "./schema";
import { DbError, type Db, type Insert, type ListOptions, type Patch } from "./types";

export const DEMO_USER_ID = "00000000-0000-4000-8000-000000000001";

type Store = { [T in TableName]?: Row<T>[] };

function compare(a: unknown, b: unknown): number {
  if (a === b) return 0;
  if (a === null || a === undefined) return 1;
  if (b === null || b === undefined) return -1;
  return a < b ? -1 : 1;
}

/** In-memory adapter used when Supabase env keys are absent. */
export class DemoDb implements Db {
  readonly mode = "demo" as const;

  constructor(
    private store: Store = {},
    private now: () => Date = () => new Date(),
  ) {}

  private rows<T extends TableName>(table: T): Row<T>[] {
    const existing = this.store[table] as Row<T>[] | undefined;
    if (existing) return existing;
    const created: Row<T>[] = [];
    (this.store as Record<string, unknown>)[table] = created;
    return created;
  }

  private assertUnique<T extends TableName>(table: T, row: Row<T>, ignoreId?: string) {
    for (const key of UNIQUE_KEYS[table] ?? []) {
      const clash = this.rows(table).some(
        (r) => r.id !== ignoreId && key.every((k) => r[k] === row[k]),
      );
      if (clash) throw new DbError(`${table}: duplicate ${key.join(", ")}`, "conflict");
    }
  }

  async list<T extends TableName>(table: T, opts: ListOptions<T> = {}): Promise<Row<T>[]> {
    const where = Object.entries(opts.where ?? {});
    let out = this.rows(table).filter((r) =>
      where.every(([k, v]) => (r as Record<string, unknown>)[k] === v),
    );
    if (opts.orderBy) {
      const key = opts.orderBy;
      const dir = opts.ascending === false ? -1 : 1;
      out = [...out].sort((a, b) => dir * compare(a[key], b[key]));
    }
    return out.map((r) => structuredClone(r));
  }

  async get<T extends TableName>(table: T, id: string): Promise<Row<T> | null> {
    const row = this.rows(table).find((r) => r.id === id);
    return row ? structuredClone(row) : null;
  }

  async insert<T extends TableName>(table: T, values: Insert<T>[]): Promise<Row<T>[]> {
    const created: Row<T>[] = [];
    for (const v of values) {
      const row = {
        ...COLUMN_DEFAULTS[table],
        ...v,
        id: v.id ?? crypto.randomUUID(),
        user_id: DEMO_USER_ID,
        created_at: this.now().toISOString(),
      } as Row<T>;
      this.assertUnique(table, row);
      this.rows(table).push(row);
      created.push(structuredClone(row));
    }
    return created;
  }

  async update<T extends TableName>(table: T, id: string, patch: Patch<T>): Promise<Row<T>> {
    const rows = this.rows(table);
    const i = rows.findIndex((r) => r.id === id);
    if (i < 0) throw new DbError(`${table}: ${id} not found`, "not_found");
    const next = { ...rows[i], ...patch, id, user_id: rows[i].user_id } as Row<T>;
    this.assertUnique(table, next, id);
    rows[i] = next;
    return structuredClone(next);
  }

  async remove<T extends TableName>(table: T, id: string): Promise<void> {
    const rows = this.rows(table);
    const i = rows.findIndex((r) => r.id === id);
    if (i < 0) return;
    rows.splice(i, 1);
    for (const [child, fk] of CASCADES[table] ?? []) {
      const orphans = this.rows(child).filter((r) => (r as Record<string, unknown>)[fk] === id);
      for (const o of orphans) await this.remove(child, o.id);
    }
  }
}
