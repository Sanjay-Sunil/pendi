"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { GOOGLE_QUERY_PARAMS, GOOGLE_SCOPES } from "@/lib/supabase/oauth";

export function GoogleButton() {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function signIn() {
    setPending(true);
    setError(null);
    // Loaded on click so the Supabase SDK stays out of the initial bundle.
    const { createSupabaseBrowserClient } = await import("@/lib/supabase/client");
    const { error } = await createSupabaseBrowserClient().auth.signInWithOAuth({
      provider: "google",
      options: {
        scopes: GOOGLE_SCOPES,
        queryParams: GOOGLE_QUERY_PARAMS,
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });
    if (error) {
      setError(error.message);
      setPending(false);
    }
  }

  return (
    <div className="flex flex-col gap-2">
      <Button onClick={signIn} disabled={pending} className="w-full">
        {pending ? "Redirecting…" : "Continue with Google"}
      </Button>
      {error ? (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      ) : null}
    </div>
  );
}
