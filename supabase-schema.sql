-- Run this file in the Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 email text unique not null,
 display_name text,
 role text not null default 'user' check(role in ('user','support','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.reports(
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(char_length(title) between 3 and 100),
 category text not null, community text not null,
 description text not null check(char_length(description) between 5 and 1500),
 latitude double precision check(latitude is null or latitude between -90 and 90),
 longitude double precision check(longitude is null or longitude between -180 and 180),
 status text not null default 'Submitted' check(status in ('Submitted','Under review','Verified','Resolved','Rejected')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists reports_reporter_created_idx on public.reports(reporter_id,created_at desc);
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role in ('admin','support'));
$$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;
alter table public.profiles enable row level security;
alter table public.reports enable row level security;
drop policy if exists "Read own profile or staff profiles" on public.profiles;
create policy "Read own profile or staff profiles" on public.profiles for select to authenticated using(id=auth.uid() or public.is_staff());
drop policy if exists "Insert own report" on public.reports;
create policy "Insert own report" on public.reports for insert to authenticated with check(reporter_id=auth.uid() and status='Submitted');
drop policy if exists "Users read own reports; staff read all" on public.reports;
create policy "Users read own reports; staff read all" on public.reports for select to authenticated using(reporter_id=auth.uid() or public.is_staff());
drop policy if exists "Staff update report status" on public.reports;
create policy "Staff update report status" on public.reports for update to authenticated using(public.is_staff()) with check(public.is_staff());

-- Create default user profiles. Auth email uniqueness is enforced by Supabase Auth;
-- profiles.email is also UNIQUE as a second safeguard.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,email,display_name,role)
 values(new.id,lower(new.email),coalesce(new.raw_user_meta_data->>'display_name',''),'user')
 on conflict(id) do update set email=lower(excluded.email);
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.promote_user_to_support(target_email text) returns text language plpgsql security definer set search_path=public as $$
begin
 if not public.is_admin() then raise exception 'Only an administrator can promote users.'; end if;
 update public.profiles set role='support' where email=lower(trim(target_email)) and role='user';
 if found then return 'User promoted to support.'; end if;
 if exists(select 1 from public.profiles where email=lower(trim(target_email)) and role='support') then return 'This user is already support staff.'; end if;
 return 'No registered general user found for that email.';
end; $$;
revoke all on function public.promote_user_to_support(text) from public;
grant execute on function public.promote_user_to_support(text) to authenticated;
grant select on public.profiles to authenticated;
grant select,insert,update on public.reports to authenticated;

-- IMPORTANT SECURITY HARDENING:
-- For a public launch, replace the broad staff UPDATE policy above with a database
-- trigger or restricted RPC that only permits changes to status/updated_at.
-- The browser UI alone is not a security boundary.
-- After creating and registering your own account, assign the first admin from SQL Editor:
-- update public.profiles set role='admin' where id='YOUR-VERIFIED-USER-UUID';
