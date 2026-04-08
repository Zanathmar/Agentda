-- Recreate tasks table with correct column names
create table if not exists public.tasks (
  id               text primary key,
  user_id          uuid references auth.users(id) on delete cascade not null,
  title            text not null,
  description      text,
  deadline         timestamptz not null,
  duration_minutes integer not null default 60,
  priority         text not null default 'medium',
  preferred_time   text,
  completed        boolean not null default false,
  created_at       timestamptz default now()
);

-- Enable RLS
alter table public.tasks enable row level security;

-- Drop old policies if any
drop policy if exists "Users can manage own tasks" on public.tasks;

-- Users can only see and edit their own tasks
create policy "Users can manage own tasks"
  on public.tasks
  for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);