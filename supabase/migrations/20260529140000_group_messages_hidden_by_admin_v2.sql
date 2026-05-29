-- Add hidden_by_admin column (idempotent)
alter table public.group_messages
  add column if not exists hidden_by_admin boolean not null default false;

-- Admin sees all messages including hidden ones
-- Author always sees their own messages
-- Others only see visible, non-hidden messages
drop policy if exists "group_messages_select" on public.group_messages;
create policy "group_messages_select" on public.group_messages
  for select using (
    exists (
      select 1 from public.user_roles
      where user_roles.user_id = auth.uid()
        and user_roles.role = 'admin'
    )
    or user_id = auth.uid()
    or (visible = true and hidden_by_admin is not true)
  );

-- Allow admins to update messages (set hidden_by_admin)
drop policy if exists "group_messages_update_admin" on public.group_messages;
create policy "group_messages_update_admin" on public.group_messages
  for update using (
    exists (
      select 1 from public.user_roles
      where user_roles.user_id = auth.uid()
        and user_roles.role = 'admin'
    )
  );

