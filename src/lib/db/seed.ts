import { todayLocal } from "@/lib/domain/dates";
import { createSource } from "./reading";
import designedToScale from "./seed-data/designed-to-scale.json";
import saadho from "./seed-data/saadho.json";
import type { Db } from "./types";

/** Demo-mode seed data. Each module appends its own seed step here as it lands. */
export async function seedDemo(db: Db, now: Date = new Date()): Promise<void> {
  const today = todayLocal(now);
  await db.insert("profiles", [{ timezone: "Asia/Kolkata" }]);

  await createSource(
    db,
    {
      title: "Designed to Scale",
      url: "https://designed-to-scale.vercel.app/",
      kind: "course",
      start_date: today,
      target_days: 30,
    },
    designedToScale,
  );
  await createSource(
    db,
    {
      title: "Saadho",
      url: "https://saadho.arushk.tech/",
      kind: "course",
      start_date: today,
      target_days: 30,
    },
    saadho,
  );
}
