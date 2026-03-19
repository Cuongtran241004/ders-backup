//=============================================================================
// CDS VIEW: ZI_DERS_Export
// TYPE: Interface View (Root Entity)
// PURPOSE: One-time Export Request Business Object
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Export Request Interface View'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_DERS_Export
  as select from zders_export as Export
  
  association [0..1] to ZI_DERS_Catalog as _Catalog on $projection.ReportId = _Catalog.ReportId
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Export.export_uuid         as ExportUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Export Identity
      // ═══════════════════════════════════════════════════════════════
      Export.export_id           as ExportId,
      Export.user_id             as UserId,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Configuration
      // ═══════════════════════════════════════════════════════════════
      Export.report_id           as ReportId,
      Export.output_format       as OutputFormat,
      Export.param_json          as ParamJson,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      Export.status              as Status,
      
      case Export.status
        when 'A' then 3  // Active = Green
        when 'P' then 2  // Paused = Yellow
        when 'D' then 1  // Deleted = Red
        else 0
      end                        as StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Email Configuration
      // ═══════════════════════════════════════════════════════════════
      Export.send_email          as SendEmail,
      Export.email_to            as EmailTo,
      Export.email_cc            as EmailCc,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Export.created_by          as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Export.created_at          as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Export.last_changed_by     as LastChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Export.last_changed_at     as LastChangedAt,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Export.local_last_changed_at as LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Catalog
}
