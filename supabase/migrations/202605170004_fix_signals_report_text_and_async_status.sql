-- Fix live signal inserts rejected by an older/stricter report_text constraint
-- and allow async pipeline states written by the current Edge Function.

alter table public.signals
  drop constraint if exists signals_report_text_check;

alter table public.signals
  add constraint signals_report_text_check
  check (
    report_text is not null
    and length(
      btrim(
        regexp_replace(report_text, '[[:cntrl:]]', '', 'g')
      )
    ) > 0
  );

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

update public.signals
set status = 'submitted'
where status is null;
