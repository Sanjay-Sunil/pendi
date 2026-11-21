import "server-only";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { supabaseEnv } from "./env";

/** Request-scoped client that acts as the signed-in user (RLS applies). */
export async function createSupabaseServerClient() {
  const env = supabaseEnv();
  if (!env) throw new Error("Supabase env keys are not set");
  const store = await cookies();
  return createServerClient(env.url, env.anonKey, {
    cookies: {
      getAll: () => store.getAll(),
      setAll: (list) => {
        try {
          for (const { name, value, options } of list) store.set(name, value, options);
        } catch {
          // Called from a Server Component; middleware refreshes the session instead.
        }
      },
    },
  });
}
