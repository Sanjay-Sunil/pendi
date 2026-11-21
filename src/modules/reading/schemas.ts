import { z } from "zod";

export const pageSchema = z.object({
  title: z.string().trim().min(1).max(300),
  url: z.url(),
});

export const createSourceSchema = z.object({
  title: z.string().trim().min(1).max(200),
  url: z.url(),
  kind: z.enum(["course", "blog"]),
  targetDays: z.coerce.number().int().min(1).max(365),
  pages: z.array(pageSchema).min(1, "Pick at least one page").max(1000),
});

export const addItemsSchema = z.object({
  sourceId: z.string().min(1),
  pages: z.array(pageSchema).min(1).max(1000),
});

export const toggleItemSchema = z.object({
  id: z.string().min(1),
  done: z.boolean(),
  note: z.string().max(280).optional(),
});

export const noteSchema = z.object({ id: z.string().min(1), note: z.string().max(280) });

export const idSchema = z.object({ id: z.string().min(1) });

export type CreateSourceInput = z.input<typeof createSourceSchema>;
