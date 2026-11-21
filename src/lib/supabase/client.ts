"use client";

import { createBrowserClient } from "@supabase/ssr";
import { supabaseEnv } from "./env";

export function createSupabaseBrowserClient() {
  const env = supabaseEnv();
  if (!env) throw new Error("Supabase env keys are not set");
  return createBrowserClient(env.url, env.anonKey);
}
