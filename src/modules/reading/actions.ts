"use server";

import { revalidatePath } from "next/cache";
import { fail, ok, parseInput, type ActionResult } from "@/lib/action-result";
import { getDb } from "@/lib/db";
import * as reading from "@/lib/db/reading";
import { todayLocal } from "@/lib/domain/dates";
import {
  addItemsSchema,
  createSourceSchema,
  idSchema,
  noteSchema,
  toggleItemSchema,
} from "./schemas";

function refresh() {
  revalidatePath("/reading");
  revalidatePath("/today");
}

export async function createSourceAction(input: unknown): Promise<ActionResult<{ id: string }>> {
  const parsed = parseInput(createSourceSchema, input);
  if (!parsed.ok) return parsed;
  const { title, url, kind, targetDays, pages } = parsed.data;
  try {
    const { source } = await reading.createSource(
      await getDb(),
      { title, url, kind, target_days: targetDays, start_date: todayLocal() },
      pages,
    );
    refresh();
    return ok({ id: source.id });
  } catch (e) {
    return fail(e);
  }
}

export async function addItemsAction(input: unknown): Promise<ActionResult<{ added: number }>> {
  const parsed = parseInput(addItemsSchema, input);
  if (!parsed.ok) return parsed;
  try {
    const added = await reading.addItems(await getDb(), parsed.data.sourceId, parsed.data.pages);
    refresh();
    return ok({ added: added.length });
  } catch (e) {
    return fail(e);
  }
}

export async function toggleItemAction(input: unknown): Promise<ActionResult> {
  const parsed = parseInput(toggleItemSchema, input);
  if (!parsed.ok) return parsed;
  try {
    const { id, done, note } = parsed.data;
    await reading.setItemDone(await getDb(), id, done, new Date(), note);
    refresh();
    return ok(undefined);
  } catch (e) {
    return fail(e);
  }
}

export async function saveNoteAction(input: unknown): Promise<ActionResult> {
  const parsed = parseInput(noteSchema, input);
  if (!parsed.ok) return parsed;
  try {
    await reading.setItemNote(await getDb(), parsed.data.id, parsed.data.note);
    refresh();
    return ok(undefined);
  } catch (e) {
    return fail(e);
  }
}

export async function archiveSourceAction(input: unknown): Promise<ActionResult> {
  const parsed = parseInput(idSchema, input);
  if (!parsed.ok) return parsed;
  try {
    await reading.archiveSource(await getDb(), parsed.data.id);
    refresh();
    return ok(undefined);
  } catch (e) {
    return fail(e);
  }
}
