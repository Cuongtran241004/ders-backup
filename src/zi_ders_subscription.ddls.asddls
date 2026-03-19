//=============================================================================
// CDS VIEW: ZI_DERS_Subscription
// TYPE: Interface View (Root Entity)
// PURPOSE: Subscription Business Object definition
// NOTE: _JobHistory is association (not composition) because JobHistory is
//       system-generated, has its own lifecycle, and needs separate BDEF
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Subscription Interface View'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_DERS_Subscription
  as select from zders_subscr as Subscr
  
  // Association to JobHistory (NOT composition - separate BDEF)
  association [0..*] to ZI_DERS_JobHistory as _JobHistory 
    on $projection.SubscrUuid = _JobHistory.SourceUuid
  
  association [0..1] to ZI_DERS_Catalog    as _Catalog    on $projection.ReportId = _Catalog.ReportId
  association [0..1] to I_CompanyCode      as _Company    on $projection.Bukrs = _Company.CompanyCode
  association [0..1] to ZVH_DERS_Frequency as _Frequency  on $projection.Frequency = _Frequency.Frequency
  association [0..1] to ZVH_DERS_Status    as _Status     on $projection.Status = _Status.Status
  
  // Composition to Parameter child entity
  composition [0..*] of ZI_DERS_SubscriptionParam as _Params
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Subscr.subscr_uuid         as SubscrUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Subscription Identity
      // ═══════════════════════════════════════════════════════════════
      Subscr.user_id             as UserId,
      Subscr.subscr_name         as SubscrName,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Configuration
      // ═══════════════════════════════════════════════════════════════
      Subscr.report_id           as ReportId,
      Subscr.bukrs               as Bukrs,
      Subscr.output_format       as OutputFormat,
      Subscr.param_json          as ParamJson,
      
      // ═══════════════════════════════════════════════════════════════
      // Schedule Configuration
      // ═══════════════════════════════════════════════════════════════
      Subscr.frequency           as Frequency,
      Subscr.exec_day            as ExecDay,
      Subscr.exec_time           as ExecTime,
      Subscr.tmzone              as Tmzone,
      
      // ═══════════════════════════════════════════════════════════════
      // Derived: Schedule Description
      // ═══════════════════════════════════════════════════════════════
      case Subscr.frequency
        when 'D' then concat( 'Daily at ', cast( Subscr.exec_time as abap.char(8) ) )
        when 'W' then concat( concat( 'Weekly Day ', Subscr.exec_day ), concat( ' at ', cast( Subscr.exec_time as abap.char(8) ) ) )
        when 'M' then concat( concat( 'Monthly Day ', Subscr.exec_day ), concat( ' at ', cast( Subscr.exec_time as abap.char(8) ) ) )
        else 'Not Scheduled'
      end                        as ScheduleDescription,
      
      // ═══════════════════════════════════════════════════════════════
      // Email Configuration
      // ═══════════════════════════════════════════════════════════════
      Subscr.email_to            as EmailTo,
      Subscr.email_cc            as EmailCc,
      
      // ═══════════════════════════════════════════════════════════════
      // Status with Criticality
      // ═══════════════════════════════════════════════════════════════
      Subscr.status              as Status,
      
      case Subscr.status
        when 'A' then 3  // Active = Green
        when 'P' then 2  // Paused = Yellow
        when 'D' then 1  // Deleted = Red
        else 0
      end                        as StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Tracking
      // ═══════════════════════════════════════════════════════════════
      Subscr.next_run_ts         as NextRunTs,
      Subscr.last_run_ts         as LastRunTs,
      Subscr.run_count           as RunCount,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data (ETag)
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Subscr.created_by          as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Subscr.created_at          as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Subscr.last_changed_by     as LastChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Subscr.last_changed_at     as LastChangedAt,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Subscr.local_last_changed_at as LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _JobHistory,
      _Catalog,
      _Company,
      _Frequency,
      _Status,
      
      // ═══════════════════════════════════════════════════════════════
      // Compositions (Child Entities)
      // ═══════════════════════════════════════════════════════════════
      _Params
}
