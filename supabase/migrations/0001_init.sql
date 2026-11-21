-- 0001_init.sql — Daybook schema. Forward-only; every table is user-owned and RLS-protected.

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade unique,
  created_at timestamptz not null default now(),
  timezone text not null default 'Asia/Kolkata',
  cf_handle text,
  gcal_calendar_id text
);
alter table public.profiles enable row level security;
create policy "profiles_owner" on public.profiles for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index profiles_user_idx on public.profiles (user_id);

create table public.reading_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  title text not null,
  url text not null,
  kind text not null default 'course' check (kind in ('course','blog')),
  start_date date not null,
  target_days int not null check (target_days > 0),
  status text not null default 'active' check (status in ('active','archived','done'))
);
alter table public.reading_sources enable row level security;
create policy "reading_sources_owner" on public.reading_sources for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index reading_sources_user_idx on public.reading_sources (user_id);

create table public.reading_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  source_id uuid not null references public.reading_sources(id) on delete cascade,
  title text not null,
  url text not null,
  position int not null,
  status text not null default 'todo' check (status in ('todo','done','skipped')),
  done_at timestamptz,
  note text,
  unique (source_id, url)
);
alter table public.reading_items enable row level security;
create policy "reading_items_owner" on public.reading_items for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index reading_items_user_idx on public.reading_items (user_id);

create table public.cp_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  name text not null,
  source text,
  active boolean not null default false
);
alter table public.cp_lists enable row level security;
create policy "cp_lists_owner" on public.cp_lists for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index cp_lists_user_idx on public.cp_lists (user_id);

create table public.cp_problems (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  list_id uuid not null references public.cp_lists(id) on delete cascade,
  contest_id int not null,
  idx text not null,
  name text,
  rating int,
  position int not null,
  status text not null default 'todo' check (status in ('todo','solved','review','skipped')),
  solved_at timestamptz,
  note text,
  unique (list_id, contest_id, idx)
);
alter table public.cp_problems enable row level security;
create policy "cp_problems_owner" on public.cp_problems for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index cp_problems_user_idx on public.cp_problems (user_id);

create table public.cp_daily (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  day date not null,
  problem_id uuid not null references public.cp_problems(id) on delete cascade,
  unique (user_id, day, problem_id)
);
alter table public.cp_daily enable row level security;
create policy "cp_daily_owner" on public.cp_daily for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index cp_daily_user_idx on public.cp_daily (user_id);

create table public.hackathons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  name text not null,
  url text,
  status text not null default 'active' check (status in ('active','submitted','done','dropped')),
  theme text,
  team text,
  notes text
);
alter table public.hackathons enable row level security;
create policy "hackathons_owner" on public.hackathons for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index hackathons_user_idx on public.hackathons (user_id);

create table public.hackathon_milestones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  hackathon_id uuid not null references public.hackathons(id) on delete cascade,
  title text not null,
  due_at timestamptz,
  done boolean not null default false,
  kind text,
  gcal_event_id text
);
alter table public.hackathon_milestones enable row level security;
create policy "hackathon_milestones_owner" on public.hackathon_milestones for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index hackathon_milestones_user_idx on public.hackathon_milestones (user_id);

create table public.hackathon_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  hackathon_id uuid not null references public.hackathons(id) on delete cascade,
  title text not null,
  due_at timestamptz,
  done boolean not null default false
);
alter table public.hackathon_tasks enable row level security;
create policy "hackathon_tasks_owner" on public.hackathon_tasks for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index hackathon_tasks_user_idx on public.hackathon_tasks (user_id);

create table public.research_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  name text not null,
  org text,
  mentor text,
  active boolean not null default true
);
alter table public.research_projects enable row level security;
create policy "research_projects_owner" on public.research_projects for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index research_projects_user_idx on public.research_projects (user_id);

create table public.research_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  project_id uuid not null references public.research_projects(id) on delete cascade,
  day date not null,
  body text not null default '',
  unique (project_id, day)
);
alter table public.research_logs enable row level security;
create policy "research_logs_owner" on public.research_logs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index research_logs_user_idx on public.research_logs (user_id);

create table public.research_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  project_id uuid not null references public.research_projects(id) on delete cascade,
  title text not null,
  assigned_by text,
  due_at timestamptz,
  status text not null default 'todo' check (status in ('todo','doing','done')),
  priority int not null default 2 check (priority between 1 and 3),
  done_at timestamptz
);
alter table public.research_tasks enable row level security;
create policy "research_tasks_owner" on public.research_tasks for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index research_tasks_user_idx on public.research_tasks (user_id);

create table public.research_papers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  project_id uuid not null references public.research_projects(id) on delete cascade,
  title text not null,
  url text,
  status text not null default 'to_read' check (status in ('to_read','reading','done')),
  summary text,
  done_at timestamptz
);
alter table public.research_papers enable row level security;
create policy "research_papers_owner" on public.research_papers for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index research_papers_user_idx on public.research_papers (user_id);

create table public.research_ideas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  project_id uuid not null references public.research_projects(id) on delete cascade,
  body text not null,
  status text not null default 'parked'
);
alter table public.research_ideas enable row level security;
create policy "research_ideas_owner" on public.research_ideas for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index research_ideas_user_idx on public.research_ideas (user_id);

create table public.research_experiments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  project_id uuid not null references public.research_projects(id) on delete cascade,
  title text not null,
  hypothesis text,
  result text,
  day date not null
);
alter table public.research_experiments enable row level security;
create policy "research_experiments_owner" on public.research_experiments for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index research_experiments_user_idx on public.research_experiments (user_id);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  name text not null,
  code text,
  attendance_attended int not null default 0 check (attendance_attended >= 0),
  attendance_total int not null default 0 check (attendance_total >= 0),
  min_pct int not null default 75 check (min_pct between 0 and 100)
);
alter table public.courses enable row level security;
create policy "courses_owner" on public.courses for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index courses_user_idx on public.courses (user_id);

create table public.college_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  title text not null,
  course_id uuid references public.courses(id) on delete set null,
  kind text not null default 'other' check (kind in ('assignment','exam','club','other')),
  due_at timestamptz,
  done boolean not null default false,
  done_at timestamptz,
  gcal_event_id text
);
alter table public.college_tasks enable row level security;
create policy "college_tasks_owner" on public.college_tasks for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index college_tasks_user_idx on public.college_tasks (user_id);

create table public.gcal_events_cache (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  gcal_event_id text not null,
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  all_day boolean not null default false,
  unique (user_id, gcal_event_id)
);
alter table public.gcal_events_cache enable row level security;
create policy "gcal_events_cache_owner" on public.gcal_events_cache for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index gcal_events_cache_user_idx on public.gcal_events_cache (user_id);

create table public.inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  body text not null,
  resolved boolean not null default false
);
alter table public.inbox enable row level security;
create policy "inbox_owner" on public.inbox for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index inbox_user_idx on public.inbox (user_id);

create table public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  name text not null,
  target_per_week int not null default 7 check (target_per_week between 1 and 7)
);
alter table public.habits enable row level security;
create policy "habits_owner" on public.habits for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index habits_user_idx on public.habits (user_id);

create table public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  day date not null,
  unique (habit_id, day)
);
alter table public.habit_logs enable row level security;
create policy "habit_logs_owner" on public.habit_logs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index habit_logs_user_idx on public.habit_logs (user_id);

create table public.daily_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  day date not null,
  reflection text not null default '',
  top3 text[] not null default '{}',
  unique (user_id, day)
);
alter table public.daily_notes enable row level security;
create policy "daily_notes_owner" on public.daily_notes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create index daily_notes_user_idx on public.daily_notes (user_id);
