import type { Db } from "./types";

/** Demo-mode seed data. Each module appends its own seed step here as it lands. */
export async function seedDemo(db: Db): Promise<void> {
  await db.insert("profiles", [{ timezone: "Asia/Kolkata" }]);
}
