import { z } from "zod";

/** Row schemas mirror supabase/migrations. Used to validate input and exports. */

const id = z.string().min(1);
const ts = z.string(); // timestamptz as ISO string
const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "expected YYYY-MM-DD");
const base = { id, user_id: id, created_at: ts };

export const profileRow = z.object({
  ...base,
  timezone: z.string(),
  cf_handle: z.string().nullable(),
  gcal_calendar_id: z.string().nullable(),
});

export const readingSourceRow = z.object({
  ...base,
  title: z.string().min(1),
  url: z.url(),
  kind: z.enum(["course", "blog"]),
  start_date: day,
  target_days: z.number().int().positive(),
  status: z.enum(["active", "archived", "done"]),
});

export const readingItemRow = z.object({
  ...base,
  source_id: id,
  title: z.string().min(1),
  url: z.url(),
  position: z.number().int(),
  status: z.enum(["todo", "done", "skipped"]),
  done_at: ts.nullable(),
  note: z.string().nullable(),
});

export const cpListRow = z.object({
  ...base,
  name: z.string().min(1),
  source: z.string().nullable(),
  active: z.boolean(),
});

export const cpProblemRow = z.object({
  ...base,
  list_id: id,
  contest_id: z.number().int().positive(),
  idx: z.string().min(1),
  name: z.string().nullable(),
  rating: z.number().int().nullable(),
  position: z.number().int(),
  status: z.enum(["todo", "solved", "review", "skipped"]),
  solved_at: ts.nullable(),
  note: z.string().nullable(),
});

export const cpDailyRow = z.object({ ...base, day, problem_id: id });

export const hackathonRow = z.object({
  ...base,
  name: z.string().min(1),
  url: z.string().nullable(),
  status: z.enum(["active", "submitted", "done", "dropped"]),
  theme: z.string().nullable(),
  team: z.string().nullable(),
  notes: z.string().nullable(),
});

export const hackathonMilestoneRow = z.object({
  ...base,
  hackathon_id: id,
  title: z.string().min(1),
  due_at: ts.nullable(),
  done: z.boolean(),
  kind: z.string().nullable(),
  gcal_event_id: z.string().nullable(),
});

export const hackathonTaskRow = z.object({
  ...base,
  hackathon_id: id,
  title: z.string().min(1),
  due_at: ts.nullable(),
  done: z.boolean(),
});

export const researchProjectRow = z.object({
  ...base,
  name: z.string().min(1),
  org: z.string().nullable(),
  mentor: z.string().nullable(),
  active: z.boolean(),
});

export const researchLogRow = z.object({ ...base, project_id: id, day, body: z.string() });

export const researchTaskRow = z.object({
  ...base,
  project_id: id,
  title: z.string().min(1),
  assigned_by: z.string().nullable(),
  due_at: ts.nullable(),
  status: z.enum(["todo", "doing", "done"]),
  priority: z.number().int().min(1).max(3),
  done_at: ts.nullable(),
});

export const researchPaperRow = z.object({
  ...base,
  project_id: id,
  title: z.string().min(1),
  url: z.string().nullable(),
  status: z.enum(["to_read", "reading", "done"]),
  summary: z.string().nullable(),
  done_at: ts.nullable(),
});

export const researchIdeaRow = z.object({
  ...base,
  project_id: id,
  body: z.string().min(1),
  status: z.string(),
});

export const researchExperimentRow = z.object({
  ...base,
  project_id: id,
  title: z.string().min(1),
  hypothesis: z.string().nullable(),
  result: z.string().nullable(),
  day,
});

export const courseRow = z.object({
  ...base,
  name: z.string().min(1),
  code: z.string().nullable(),
  attendance_attended: z.number().int().min(0),
  attendance_total: z.number().int().min(0),
  min_pct: z.number().int().min(0).max(100),
});

export const collegeTaskRow = z.object({
  ...base,
  title: z.string().min(1),
  course_id: id.nullable(),
  kind: z.enum(["assignment", "exam", "club", "other"]),
  due_at: ts.nullable(),
  done: z.boolean(),
  done_at: ts.nullable(),
  gcal_event_id: z.string().nullable(),
});

export const gcalEventRow = z.object({
  ...base,
  gcal_event_id: z.string(),
  title: z.string(),
  starts_at: ts,
  ends_at: ts.nullable(),
  all_day: z.boolean(),
});

export const inboxRow = z.object({ ...base, body: z.string().min(1), resolved: z.boolean() });

export const habitRow = z.object({
  ...base,
  name: z.string().min(1),
  target_per_week: z.number().int().min(1).max(7),
});

export const habitLogRow = z.object({ ...base, habit_id: id, day });

export const dailyNoteRow = z.object({
  ...base,
  day,
  reflection: z.string(),
  top3: z.array(z.string()),
});

export const tableSchemas = {
  profiles: profileRow,
  reading_sources: readingSourceRow,
  reading_items: readingItemRow,
  cp_lists: cpListRow,
  cp_problems: cpProblemRow,
  cp_daily: cpDailyRow,
  hackathons: hackathonRow,
  hackathon_milestones: hackathonMilestoneRow,
  hackathon_tasks: hackathonTaskRow,
  research_projects: researchProjectRow,
  research_logs: researchLogRow,
  research_tasks: researchTaskRow,
  research_papers: researchPaperRow,
  research_ideas: researchIdeaRow,
  research_experiments: researchExperimentRow,
  courses: courseRow,
  college_tasks: collegeTaskRow,
  gcal_events_cache: gcalEventRow,
  inbox: inboxRow,
  habits: habitRow,
  habit_logs: habitLogRow,
  daily_notes: dailyNoteRow,
} as const;

export type TableName = keyof typeof tableSchemas;
export type Row<T extends TableName> = z.infer<(typeof tableSchemas)[T]>;
export const TABLE_NAMES = Object.keys(tableSchemas) as TableName[];
