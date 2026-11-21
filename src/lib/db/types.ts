import type { Row, TableName } from "./schema";

type Base = "id" | "user_id" | "created_at";

/** Columns with SQL defaults; optional on insert. */
type Defaults = {
  profiles: "timezone" | "cf_handle" | "gcal_calendar_id";
  reading_sources: "kind" | "status";
  reading_items: "status" | "done_at" | "note";
  cp_lists: "source" | "active";
  cp_problems: "name" | "rating" | "status" | "solved_at" | "note";
  cp_daily: never;
  hackathons: "url" | "status" | "theme" | "team" | "notes";
  hackathon_milestones: "due_at" | "done" | "kind" | "gcal_event_id";
  hackathon_tasks: "due_at" | "done";
  research_projects: "org" | "mentor" | "active";
  research_logs: "body";
  research_tasks: "assigned_by" | "due_at" | "status" | "priority" | "done_at";
  research_papers: "url" | "status" | "summary" | "done_at";
  research_ideas: "status";
  research_experiments: "hypothesis" | "result";
  courses: "code" | "attendance_attended" | "attendance_total" | "min_pct";
  college_tasks: "course_id" | "kind" | "due_at" | "done" | "done_at" | "gcal_event_id";
  gcal_events_cache: "ends_at" | "all_day";
  inbox: "resolved";
  habits: "target_per_week";
  habit_logs: never;
  daily_notes: "reflection" | "top3";
};

export type Insert<T extends TableName> = Omit<Row<T>, Base | Defaults[T]> &
  Partial<Pick<Row<T>, Defaults[T] & keyof Row<T>>> & { id?: string };

export type Patch<T extends TableName> = Partial<Omit<Row<T>, Base>>;

export type ListOptions<T extends TableName> = {
  where?: Partial<Row<T>>;
  orderBy?: keyof Row<T> & string;
  ascending?: boolean;
};

/** The only way UI and actions touch data. Implemented by the Supabase and demo adapters. */
export interface Db {
  readonly mode: "supabase" | "demo";
  list<T extends TableName>(table: T, opts?: ListOptions<T>): Promise<Row<T>[]>;
  get<T extends TableName>(table: T, id: string): Promise<Row<T> | null>;
  insert<T extends TableName>(table: T, values: Insert<T>[]): Promise<Row<T>[]>;
  update<T extends TableName>(table: T, id: string, patch: Patch<T>): Promise<Row<T>>;
  remove<T extends TableName>(table: T, id: string): Promise<void>;
}

export class DbError extends Error {
  constructor(
    message: string,
    readonly code: "not_found" | "conflict" | "invalid" | "backend",
  ) {
    super(message);
    this.name = "DbError";
  }
}
