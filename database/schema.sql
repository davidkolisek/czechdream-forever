create table if not exists characters (id uuid primary key default gen_random_uuid(), name text not null, realm text, class text, level integer, updated_at timestamptz default now());
create table if not exists events (id uuid primary key default gen_random_uuid(), character_id uuid references characters(id), type text not null, payload jsonb not null default '{}', occurred_at timestamptz default now());
create index if not exists events_occurred_at_idx on events(occurred_at desc);
