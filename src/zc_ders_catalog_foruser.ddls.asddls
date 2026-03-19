//=============================================================================
// CDS VIEW: ZC_DERS_Catalog_ForUser
// TYPE: Consumption View (User-specific Catalog)
// PURPOSE: Show only reports the current user has permission for
//
// USAGE:
// - Fiori app should use this view instead of ZC_DERS_Catalog for user screens
// - Automatically filters by current user's permissions in ZDERS_USER_PERM
// - Displays CanExport and CanSubscribe flags for UI
//
// JOIN LOGIC:
// - INNER JOIN with ZDERS_USER_PERM on report_id
// - Filter by $session.user (current logged-in user)
// - Only active permissions (is_active = 'X')
//
// BUSINESS REQUIREMENT:
// - Admin assigns user to system (ZDERS_UASSIGN)
// - Admin assigns report permissions (ZDERS_USER_PERM)
// - User sees only assigned reports in catalog
// - User can only subscribe to reports they have permission for
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog for Current User'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Report',
  typeNamePlural: 'Reports',
  title: { value: 'ReportName' },
  description: { value: 'Description' }
}

@Search.searchable: true

define view entity ZC_DERS_Catalog_ForUser
  as select from ZI_DERS_Catalog as Catalog
  
  //===========================================================================
  // JOIN with user permissions - filters to only permitted reports
  // This is the KEY filter that implements permission-based catalog visibility
  //===========================================================================
  inner join zders_user_perm as Perm
    on  Catalog.ReportId = Perm.report_id
    and Perm.user_id     = $session.user
    and Perm.is_active   = 'X'
  
  //===========================================================================
  // Associations
  //===========================================================================
  association [0..1] to ZVH_DERS_Module   as _Module     on $projection.ModuleId = _Module.ModuleId
  association [0..*] to ZI_DERS_Parameter as _Parameters on $projection.ReportId = _Parameters.ReportId
{
      //=======================================================================
      // Key Fields
      //=======================================================================
  key Catalog.ReportId,
  
      //=======================================================================
      // Report Metadata (from Catalog)
      //=======================================================================
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Catalog.ReportName,
      
      @Search.defaultSearchElement: true
      Catalog.Description,
      
      Catalog.ModuleId,
      Catalog.TargetRole,
      Catalog.CdsViewName,
      Catalog.SupportedFormats,
      Catalog.MaxRows,
      Catalog.EstimatedRuntime,
      
      //=======================================================================
      // Virtual fields for format support (UI convenience)
      //=======================================================================
      Catalog.SupportsExcel,
      Catalog.SupportsPdf,
      
      //=======================================================================
      // User's Permission Flags (from ZDERS_USER_PERM)
      // These control what actions user can perform on this report
      //=======================================================================
      @UI.hidden: true
      Perm.can_export      as CanExport,
      
      @UI.hidden: true  
      Perm.can_subscribe   as CanSubscribe,
      
      @UI.hidden: true
      Perm.bukrs           as PermittedBukrs,
      
      //=======================================================================
      // Criticality for UI icons
      //=======================================================================
      case Perm.can_subscribe
        when 'X' then 3  // Green - can subscribe
        else 1           // Red - cannot subscribe
      end                as SubscribeCriticality,
      
      case Perm.can_export
        when 'X' then 3  // Green - can export
        else 1           // Red - cannot export
      end                as ExportCriticality,
      
      //=======================================================================
      // Status (from Catalog)
      //=======================================================================
      Catalog.IsActive,
      Catalog.ActiveCriticality,
      
      //=======================================================================
      // Associations (published)
      //=======================================================================
      _Module,
      _Parameters
}
where Catalog.IsActive = 'X'
