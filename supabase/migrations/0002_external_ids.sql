-- 0002_external_ids.sql — remember where imported rows came from (e.g. a Moodle
-- event id) so repeated syncs update instead of duplicating. Additive only.

alter table public.college_tasks add column if not exists external_id text;
create unique index if not exists college_tasks_user_external_idx
  on public.college_tasks (user_id, external_id) where external_id is not null;
