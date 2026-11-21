"use server";

import { z } from "zod";
import { fail, ok, parseInput, type ActionResult } from "@/lib/action-result";
import { extractPages, type ExtractedPage } from "@/lib/integrations/sitemap";

export async function extractPagesAction(input: unknown): Promise<ActionResult<ExtractedPage[]>> {
  const parsed = parseInput(z.object({ url: z.url() }), input);
  if (!parsed.ok) return parsed;
  try {
    return ok(await extractPages(parsed.data.url));
  } catch (e) {
    return fail(e);
  }
}
