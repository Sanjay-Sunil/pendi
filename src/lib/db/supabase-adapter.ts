import type { SupabaseClient } from "@supabase/supabase-js";
import { tableSchemas, type Row, type TableName } from "./schema";
import { DbError, type Db, type Insert, type ListOptions, type Patch } from "./types";

function fail(table: string, error: { message: string; code?: string }): never {
  const code =
    error.code === "23505" ? "conflict" : error.code === "PGRST116" ? "not_found" : "backend";
  throw new DbError(`${table}: ${error.message}`, code);
}

/** Supabase adapter. RLS scopes every query to auth.uid(); user_id defaults server-side. */
export class SupabaseDb implements Db {
  readonly mode = "supabase" as const;

  constructor(private client: SupabaseClient) {}

  private parse<T extends TableName>(table: T, data: unknown[]): Row<T>[] {
    const schema = tableSchemas[table];
    return data.map((d) => schema.parse(d) as Row<T>);
  }

  async list<T extends TableName>(table: T, opts: ListOptions<T> = {}): Promise<Row<T>[]> {
    let q = this.client.from(table).select("*");
    for (const [k, v] of Object.entries(opts.where ?? {})) {
      q = v === null ? q.is(k, null) : q.eq(k, v as string | number | boolean);
    }
    if (opts.orderBy) q = q.order(opts.orderBy, { ascending: opts.ascending !== false });
    const { data, error } = await q;
    if (error) fail(table, error);
    return this.parse(table, data ?? []);
  }

  async get<T extends TableName>(table: T, id: string): Promise<Row<T> | null> {
    const { data, error } = await this.client.from(table).select("*").eq("id", id).maybeSingle();
    if (error) fail(table, error);
    return data ? this.parse(table, [data])[0] : null;
  }

  async insert<T extends TableName>(table: T, values: Insert<T>[]): Promise<Row<T>[]> {
    if (values.length === 0) return [];
    const { data, error } = await this.client
      .from(table)
      .insert(values as Record<string, unknown>[])
      .select("*");
    if (error) fail(table, error);
    return this.parse(table, data ?? []);
  }

  async update<T extends TableName>(table: T, id: string, patch: Patch<T>): Promise<Row<T>> {
    const { data, error } = await this.client
      .from(table)
      .update(patch as Record<string, unknown>)
      .eq("id", id)
      .select("*")
      .single();
    if (error) fail(table, error);
    return this.parse(table, [data])[0];
  }

  async remove<T extends TableName>(table: T, id: string): Promise<void> {
    const { error } = await this.client.from(table).delete().eq("id", id);
    if (error) fail(table, error);
  }
}
