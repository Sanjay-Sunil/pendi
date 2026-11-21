import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";
import { supabaseEnv } from "@/lib/supabase/env";
import { updateSession } from "@/lib/supabase/middleware";

export async function middleware(request: NextRequest) {
  const env = supabaseEnv();
  if (!env) return NextResponse.next(); // demo mode: no auth
  return updateSession(request, env);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|manifest.webmanifest|sw.js|icons/).*)"],
};
