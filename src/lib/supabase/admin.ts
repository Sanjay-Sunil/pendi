import "server-only";
import { createClient } from "@supabase/supabase-js";
import { supabaseEnv } from "./env";

/** Service-role client for cron and sync routes only. Bypasses RLS: always filter by user_id. */
export function createSupabaseAdminClient() {
  const env = supabaseEnv();
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!env || !key) throw new Error("Supabase service role key is not set");
  return createClient(env.url, key, { auth: { persistSession: false } });
}
