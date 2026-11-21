import { NextRequest } from "next/server";
import { describe, expect, it } from "vitest";
import { isPublicPath, updateSession } from "./middleware";

const env = { url: "https://example.supabase.co", anonKey: "anon" };

describe("route protection", () => {
  it("treats login, auth, and cron routes as public", () => {
    expect(isPublicPath("/login")).toBe(true);
    expect(isPublicPath("/auth/callback")).toBe(true);
    expect(isPublicPath("/api/cron/gcal")).toBe(true);
    expect(isPublicPath("/today")).toBe(false);
    expect(isPublicPath("/loginx")).toBe(false);
  });

  it("redirects signed-out users to /login when keys are set", async () => {
    const res = await updateSession(new NextRequest("http://localhost/today"), env);
    expect(res.status).toBe(307);
    expect(res.headers.get("location")).toBe("http://localhost/login");
  });

  it("lets signed-out users reach /login", async () => {
    const res = await updateSession(new NextRequest("http://localhost/login"), env);
    expect(res.status).toBe(200);
  });
});
