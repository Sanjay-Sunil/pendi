import Link from "next/link";
import { buttonClass } from "@/components/ui/button";
import { isDemoMode } from "@/lib/supabase/env";
import { GoogleButton } from "./google-button";

export const metadata = { title: "Sign in · Daybook" };

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  const demo = isDemoMode();
  return (
    <main className="mx-auto flex min-h-dvh max-w-sm flex-col justify-center gap-8 px-5">
      <div>
        <p className="font-mono text-[11px] tracking-[0.08em] text-muted uppercase">Daybook</p>
        <h1 className="mt-1 text-2xl font-semibold tracking-tight">A calm start to every day.</h1>
        <p className="mt-2 text-muted">Reading, practice, work, and classes in one quiet place.</p>
      </div>
      {demo ? (
        <div className="flex flex-col gap-2">
          <Link href="/today" className={buttonClass()}>
            Continue in demo mode
          </Link>
          <p className="text-sm text-muted">No backend configured. Data lives in memory.</p>
        </div>
      ) : (
        <GoogleButton />
      )}
      {error ? (
        <p role="alert" className="text-sm text-danger">
          Sign-in failed. Please try again.
        </p>
      ) : null}
    </main>
  );
}
