//=============================================================================
// CDS VIEW: ZI_DERS_UserPerm
// TYPE: Interface View (RAP Root Entity)
// PURPOSE: User-specific report permissions (overrides from admin)
//
// TABLE: ZDERS_USER_PERM
// KEY: USER_ID + REPORT_ID + BUKRS
//
// USE CASE:
// - Default permissions come from ZDERS_ROLE_PERM via business role
// - Admin can create override entries here for specific users
// - PermType = 'D' (Default from role) or 'O' (Override by admin)
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'User Report Permissions'
@Metadata.ignorePropagatedAnnotations: true

// Required for RAP Business Object root entity
@ObjectModel.semanticKey: ['UserId', 'ReportId', 'Bukrs']

define root view entity ZI_DERS_UserPerm
  as select from zders_user_perm as Perm
  
  association [0..1] to ZI_DERS_Catalog as _Catalog 
    on $projection.ReportId = _Catalog.ReportId
  
  association [0..1] to I_CompanyCode as _Company 
    on $projection.Bukrs = _Company.CompanyCode
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Perm.user_id             as UserId,
  key Perm.report_id           as ReportId,
  key Perm.bukrs               as Bukrs,
  
      // ═══════════════════════════════════════════════════════════════
      // Permission Flags
      // ═══════════════════════════════════════════════════════════════
      Perm.can_export          as CanExport,
      Perm.can_subscribe       as CanSubscribe,
      
      // ═══════════════════════════════════════════════════════════════
      // Permission Type
      // ═══════════════════════════════════════════════════════════════
      Perm.perm_type           as PermType,
      
      case Perm.perm_type
        when 'D' then 'Default (from Role)'
        when 'O' then 'Override (Admin)'
        else 'Unknown'
      end                      as PermTypeText,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      Perm.is_active           as IsActive,
      
      case Perm.is_active
        when 'X' then 3  // Active = Green
        else 1           // Inactive = Red
      end                      as StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Perm.created_by          as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Perm.created_at          as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Perm.changed_by          as ChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Perm.changed_at          as ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Catalog,
      _Company
}
