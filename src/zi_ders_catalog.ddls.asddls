//=============================================================================
// CDS VIEW: ZI_DERS_Catalog
// TYPE: Interface View (Root Entity)
// PURPOSE: Report Catalog Business Object definition
// COMPOSITION: _Parameters → ZI_DERS_Parameter [0..*]
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog Interface View'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_DERS_Catalog
  as select from zders_catalog as Catalog
  composition [0..*] of ZI_DERS_Parameter as _Parameters
  association [0..1] to ZVH_DERS_Module   as _Module    on $projection.ModuleId = _Module.ModuleId
  association [0..1] to I_CompanyCode     as _Company   on $projection.TargetRole = _Company.CompanyCode
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Catalog.report_id          as ReportId,
  
      // ═══════════════════════════════════════════════════════════════
      // Classification
      // ═══════════════════════════════════════════════════════════════
      Catalog.module_id          as ModuleId,
      Catalog.target_role        as TargetRole,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Metadata
      // ═══════════════════════════════════════════════════════════════
      Catalog.report_name        as ReportName,
      Catalog.description        as Description,
      
      // ═══════════════════════════════════════════════════════════════
      // Technical Configuration
      // ═══════════════════════════════════════════════════════════════
      Catalog.cds_view_name      as CdsViewName,
      Catalog.supported_formats  as SupportedFormats,
      
      // ═══════════════════════════════════════════════════════════════
      // Limits
      // ═══════════════════════════════════════════════════════════════
      Catalog.max_rows           as MaxRows,
      Catalog.estimated_runtime  as EstimatedRuntime,
      
      // ═══════════════════════════════════════════════════════════════
      // Status with Criticality
      // ═══════════════════════════════════════════════════════════════
      Catalog.is_active          as IsActive,
      
      case Catalog.is_active
        when 'X' then 3  // Positive (Green)
        else 1           // Negative (Red)
      end                        as ActiveCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Virtual Elements for UI
      // ═══════════════════════════════════════════════════════════════
      case 
        when Catalog.supported_formats like '%XLSX%' then 'X'
        else ''
      end                        as SupportsExcel,
      
      case 
        when Catalog.supported_formats like '%PDF%' then 'X'
        else ''
      end                        as SupportsPdf,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data (RAP managed)
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Catalog.created_by         as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Catalog.created_at         as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Catalog.changed_by         as ChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Catalog.changed_at         as ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Parameters,
      _Module,
      _Company
}
