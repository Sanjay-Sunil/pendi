import "server-only";
import { isDemoMode } from "@/lib/supabase/env";
import { DemoDb } from "./demo-adapter";
import { seedDemo } from "./seed";
import type { Db } from "./types";

export type { Db } from "./types";

type DemoState = { db: DemoDb; ready: Promise<void> };
const g = globalThis as typeof globalThis & { __daybookDemo?: DemoState };

/** Demo store lives on globalThis so it survives dev hot reloads within one server process. */
function demoDb(): DemoState {
  if (!g.__daybookDemo) {
    const db = new DemoDb();
    g.__daybookDemo = { db, ready: seedDemo(db) };
  }
  return g.__daybookDemo;
}

export async function getDb(): Promise<Db> {
  if (isDemoMode()) {
    const state = demoDb();
    await state.ready;
    return state.db;
  }
  const { createSupabaseServerClient } = await import("@/lib/supabase/server");
  const { SupabaseDb } = await import("./supabase-adapter");
  return new SupabaseDb(await createSupabaseServerClient());
}
