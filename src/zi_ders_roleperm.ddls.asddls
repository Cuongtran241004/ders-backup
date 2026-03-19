//=============================================================================
// CDS VIEW: ZI_DERS_RolePerm
// TYPE: Interface View (Configuration)
// PURPOSE: Role-to-Report permission mapping (customizing table)
//
// TABLE: ZDERS_ROLE_PERM
// KEY: BUSINESS_ROLE + REPORT_ID
//
// USE CASE:
// - Developer/Admin defines which reports each business role can access
// - When user is assigned to a role, they inherit these permissions
// - is_default = 'X' means auto-populate to ZDERS_USER_PERM on assignment
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Role Report Permissions'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.semanticKey: ['BusinessRole', 'ReportId']

define root view entity ZI_DERS_RolePerm
  as select from zders_role_perm as RolePerm
  
  association [0..1] to ZI_DERS_Catalog as _Catalog 
    on $projection.ReportId = _Catalog.ReportId
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key RolePerm.business_role   as BusinessRole,
  key RolePerm.report_id       as ReportId,
  
      // ═══════════════════════════════════════════════════════════════
      // Permission Flags
      // ═══════════════════════════════════════════════════════════════
      RolePerm.can_export      as CanExport,
      RolePerm.can_subscribe   as CanSubscribe,
      RolePerm.is_default      as IsDefault,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      RolePerm.is_active       as IsActive,
      
      case RolePerm.is_active
        when 'X' then 3  // Active = Green
        else 1           // Inactive = Red
      end                      as StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      RolePerm.created_by      as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      RolePerm.created_at      as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      RolePerm.changed_by      as ChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      RolePerm.changed_at      as ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Catalog
}
