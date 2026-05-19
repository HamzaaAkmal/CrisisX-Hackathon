-- The mobile app validates non-empty crisis reports before insert.
-- Some live databases still have an older fragile signals_report_text_check
-- that rejects valid mobile submissions. Normalize text at the database
-- boundary and remove the fragile check so reports can enter the agent queue.

create or replace function public.normalize_signal_report_text()
returns trigger
language plpgsql
as $$
begin
  new.report_text := nullif(
    btrim(
      regexp_replace(
        coalesce(new.report_text, ''),
        '[[:cntrl:]\s]+',
        ' ',
        'g'
      )
    ),
    ''
  );

  if new.report_text is null then
    new.report_text := 'User submitted a crisis report without readable text. Review raw payload.';
    new.raw_payload := coalesce(new.raw_payload, '{}'::jsonb)
      || jsonb_build_object('report_text_recovered_by_db', true);
  end if;

  return new;
end;
$$;

drop trigger if exists normalize_signal_report_text_before_write on public.signals;

create trigger normalize_signal_report_text_before_write
before insert or update of report_text on public.signals
for each row
execute function public.normalize_signal_report_text();

alter table public.signals
  drop constraint if exists signals_report_text_check;

alter table public.signals
  alter column report_text set not null;

alter table public.signals
  drop constraint if exists signals_status_check;

alter table public.signals
  add constraint signals_status_check
  check (
    status in (
      'submitted',
      'queued',
      'normalizing',
      'normalized',
      'geocoding',
      'enriched',
      'clustered',
      'completed',
      'failed',
      'archived'
    )
  );
