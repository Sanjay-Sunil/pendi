import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { PGlite } from "@electric-sql/pglite";
import { describe, expect, it } from "vitest";
import { TABLE_NAMES } from "@/lib/db/schema";

const dir = join(process.cwd(), "supabase/migrations");

// Minimal stand-in for Supabase's auth schema so migrations run on plain Postgres.
const authStub = `
  create schema auth;
  create table auth.users (id uuid primary key);
  create function auth.uid() returns uuid language sql stable
    as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
`;

describe("migrations", () => {
  it("apply cleanly and create every table with RLS enabled", async () => {
    const pg = new PGlite();
    await pg.exec(authStub);
    for (const file of readdirSync(dir).sort()) {
      await pg.exec(readFileSync(join(dir, file), "utf8"));
    }
    const { rows } = await pg.query<{ relname: string; relrowsecurity: boolean }>(
      `select relname, relrowsecurity from pg_class
       where relnamespace = 'public'::regnamespace and relkind = 'r'`,
    );
    const tables = new Map(rows.map((r) => [r.relname, r.relrowsecurity]));
    for (const name of TABLE_NAMES) {
      expect(tables.get(name), name).toBe(true);
    }

    // RLS: a non-superuser only sees its own rows.
    const a = "00000000-0000-4000-8000-00000000000a";
    const b = "00000000-0000-4000-8000-00000000000b";
    await pg.exec(`
      insert into auth.users values ('${a}'), ('${b}');
      create role app_user;
      grant usage on schema public, auth to app_user;
      grant all on all tables in schema public to app_user;
      grant execute on function auth.uid() to app_user;
      set role app_user;
      set request.jwt.claim.sub = '${a}';
      insert into public.habits (name) values ('A habit');
      set request.jwt.claim.sub = '${b}';
    `);
    const seenByB = await pg.query("select * from public.habits");
    expect(seenByB.rows).toHaveLength(0);
    await pg.close();
  }, 30_000);
});
