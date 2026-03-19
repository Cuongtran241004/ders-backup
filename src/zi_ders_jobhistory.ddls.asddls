//=============================================================================
// CDS VIEW: ZI_DERS_JobHistory
// TYPE: Interface View (Root Entity - separate from Subscription)
// PURPOSE: Job Execution History - system-generated records
// NOTE: This is a ROOT entity with its own BDEF because:
//   1. Records are created by background job scheduler (not user)
//   2. Has own lifecycle independent of Subscription
//   3. Needs actions (retry, cancel) which require own BDEF
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Job History Interface View'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_DERS_JobHistory 
  as select from zders_jobhist as Job
  
  // Child composition - JobParam belongs to JobHistory
  composition [0..*] of ZI_DERS_JobParam as _Parameters
  
  // Child composition - File belongs to JobHistory (1:1)
  composition [0..1] of ZI_DERS_File as _File
  
  // Association back to Subscription (lookup, not parent)
  association [0..1] to ZI_DERS_Subscription as _Subscription 
    on $projection.SourceUuid = _Subscription.SubscrUuid
  
  association [0..1] to ZI_DERS_Catalog    as _Catalog    on $projection.ReportId = _Catalog.ReportId
  association [0..1] to ZVH_DERS_JobStatus as _JobStatus  on $projection.Status = _JobStatus.Status
  
{
  key Job.job_uuid               as JobUuid,
      Job.job_id                 as JobId,
      Job.job_type               as JobType,
      Job.source_uuid            as SourceUuid,
      Job.report_id              as ReportId,
      Job.user_id                as UserId,
      Job.bukrs                  as Bukrs,
      Job.param_json             as ParamJson,
      Job.output_format          as OutputFormat,
      Job.status                 as Status,
      
      case Job.status
        when 'S' then 0
        when 'R' then 2
        when 'C' then 3
        when 'F' then 1
        when 'X' then 0
        else 0
      end                        as StatusCriticality,
      
      Job.scheduled_ts           as ScheduledTs,
      Job.started_ts             as StartedTs,
      Job.completed_ts           as CompletedTs,
      Job.rows_processed         as RowsProcessed,
      Job.file_uuid              as FileUuid,
      Job.error_message          as ErrorMessage,
      Job.error_code             as ErrorCode,
      Job.bg_job_name            as BgJobName,
      Job.bg_job_count           as BgJobCount,
      Job.job_template_name      as JobTemplateName,
      Job.run_type               as RunType,
      Job.start_immediately      as StartImmediately,
      Job.start_timestamp        as StartTimestamp,
      Job.is_periodic            as IsPeriodic,
      Job.periodic_granularity   as PeriodicGranularity,
      Job.periodic_value         as PeriodicValue,
      Job.tmzone                 as Tmzone,
      Job.priority               as Priority,
      Job.retry_of_job           as RetryOfJob,
      Job.retry_count            as RetryCount,
      Job.email_sent             as EmailSent,
      Job.email_sent_ts          as EmailSentTs,
      Job.is_archived            as IsArchived,
      Job.archived_date          as ArchivedDate,
      Job.retention_until        as RetentionUntil,
      
      @Semantics.user.createdBy: true
      Job.created_by             as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Job.created_at             as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Job.last_changed_by        as LastChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Job.last_changed_at        as LastChangedAt,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Job.local_last_changed_at  as LocalLastChangedAt,
      
      _Parameters,
      _File,
      _Subscription,
      _Catalog,
      _JobStatus
}
