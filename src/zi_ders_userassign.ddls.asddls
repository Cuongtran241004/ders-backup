//=============================================================================
// CDS VIEW: ZI_DERS_UserAssign
// TYPE: Interface View (RAP Root Entity)
// PURPOSE: User-Company Code assignment management
//
// TABLE: ZDERS_UASSIGN
// KEY: USER_ID + BUKRS
//
// USE CASE:
// - Admin assigns users to company codes
// - Links user to SAP Business Role
// - Controls which company codes user can access in DERS
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'User-Company Assignment'
@Metadata.ignorePropagatedAnnotations: true

// Required for RAP Business Object root entity
@ObjectModel.semanticKey: ['UserId', 'Bukrs']

define root view entity ZI_DERS_UserAssign
  as select from zders_uassign as Assign
  
  association [0..1] to I_CompanyCode as _Company 
    on $projection.Bukrs = _Company.CompanyCode
  
  association [0..*] to ZI_DERS_UserPerm as _Permissions
    on $projection.UserId = _Permissions.UserId
   and $projection.Bukrs = _Permissions.Bukrs
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Assign.user_id           as UserId,
  key Assign.bukrs             as Bukrs,
  
      // ═══════════════════════════════════════════════════════════════
      // Role Assignment
      // ═══════════════════════════════════════════════════════════════
      Assign.business_role     as BusinessRole,
      
      // ═══════════════════════════════════════════════════════════════
      // Status with Criticality
      // ═══════════════════════════════════════════════════════════════
      Assign.is_active         as IsActive,
      
      case Assign.is_active
        when 'X' then 3  // Active = Green
        else 1           // Inactive = Red
      end                      as StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Assign.created_by        as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Assign.created_at        as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Assign.changed_by        as ChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Assign.changed_at        as ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Company,
      _Permissions
}
