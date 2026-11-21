import { describe, expect, it } from "vitest";
import { createSourceSchema } from "./schemas";

describe("reading schemas", () => {
  it("requires at least one picked page and a sane day count", () => {
    const base = { title: "T", url: "https://x.dev", kind: "blog", targetDays: "14" };
    expect(createSourceSchema.safeParse({ ...base, pages: [] }).success).toBe(false);
    const ok = createSourceSchema.parse({
      ...base,
      pages: [{ title: "p", url: "https://x.dev/p" }],
    });
    expect(ok.targetDays).toBe(14);
    expect(createSourceSchema.safeParse({ ...base, targetDays: 0, pages: ok.pages }).success).toBe(
      false,
    );
  });
});
