import { z } from "zod";

const publicEnv = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
});

export type SupabasePublicEnv = { url: string; anonKey: string };

/** Returns Supabase public config, or null when keys are absent (demo mode). */
export function supabaseEnv(): SupabasePublicEnv | null {
  const parsed = publicEnv.safeParse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  });
  if (!parsed.success) return null;
  return {
    url: parsed.data.NEXT_PUBLIC_SUPABASE_URL,
    anonKey: parsed.data.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  };
}

export function isDemoMode(): boolean {
  return supabaseEnv() === null;
}
