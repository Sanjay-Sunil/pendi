import type { Row, TableName } from "./schema";

/** Runtime copy of the SQL column defaults, used by the demo adapter. */
export const COLUMN_DEFAULTS: { [T in TableName]: Partial<Row<T>> } = {
  profiles: { timezone: "Asia/Kolkata", cf_handle: null, gcal_calendar_id: null },
  reading_sources: { kind: "course", status: "active" },
  reading_items: { status: "todo", done_at: null, note: null },
  cp_lists: { source: null, active: false },
  cp_problems: { name: null, rating: null, status: "todo", solved_at: null, note: null },
  cp_daily: {},
  hackathons: { url: null, status: "active", theme: null, team: null, notes: null },
  hackathon_milestones: { due_at: null, done: false, kind: null, gcal_event_id: null },
  hackathon_tasks: { due_at: null, done: false },
  research_projects: { org: null, mentor: null, active: true },
  research_logs: { body: "" },
  research_tasks: { assigned_by: null, due_at: null, status: "todo", priority: 2, done_at: null },
  research_papers: { url: null, status: "to_read", summary: null, done_at: null },
  research_ideas: { status: "parked" },
  research_experiments: { hypothesis: null, result: null },
  courses: { code: null, attendance_attended: 0, attendance_total: 0, min_pct: 75 },
  college_tasks: {
    course_id: null,
    kind: "other",
    due_at: null,
    done: false,
    done_at: null,
    gcal_event_id: null,
  },
  gcal_events_cache: { ends_at: null, all_day: false },
  inbox: { resolved: false },
  habits: { target_per_week: 7 },
  habit_logs: {},
  daily_notes: { reflection: "", top3: [] },
};

/** Mirrors the SQL unique constraints (user scope is implicit in demo mode). */
export const UNIQUE_KEYS: { [T in TableName]?: Array<keyof Row<T>>[] } = {
  profiles: [["user_id"]],
  reading_items: [["source_id", "url"]],
  cp_problems: [["list_id", "contest_id", "idx"]],
  cp_daily: [["day", "problem_id"]],
  research_logs: [["project_id", "day"]],
  gcal_events_cache: [["gcal_event_id"]],
  habit_logs: [["habit_id", "day"]],
  daily_notes: [["day"]],
};

/** Mirrors `on delete cascade` foreign keys: parent table -> [child table, fk column]. */
export const CASCADES: { [T in TableName]?: Array<[TableName, string]> } = {
  reading_sources: [["reading_items", "source_id"]],
  cp_lists: [["cp_problems", "list_id"]],
  cp_problems: [["cp_daily", "problem_id"]],
  hackathons: [
    ["hackathon_milestones", "hackathon_id"],
    ["hackathon_tasks", "hackathon_id"],
  ],
  research_projects: [
    ["research_logs", "project_id"],
    ["research_tasks", "project_id"],
    ["research_papers", "project_id"],
    ["research_ideas", "project_id"],
    ["research_experiments", "project_id"],
  ],
  habits: [["habit_logs", "habit_id"]],
};
