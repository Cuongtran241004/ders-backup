//=============================================================================
// CDS VIEW: ZI_DERS_JobParam
// TYPE: Interface View (Child Entity of JobHistory)
// PURPOSE: Job Parameter snapshot - child of ZI_DERS_JobHistory
// PARENT: ZI_DERS_JobHistory (composition)
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Parameter Interface View'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_DERS_JobParam
  as select from zders_job_param as Param
  
  // Parent association
  association to parent ZI_DERS_JobHistory as _JobHistory 
    on $projection.ParentUuid = _JobHistory.JobUuid
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Param.job_param_uuid       as JobParamUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Parent Reference
      // ═══════════════════════════════════════════════════════════════
      Param.parent_uuid          as ParentUuid,
      
      // ═══════════════════════════════════════════════════════════════
      // Parameter Identity
      // ═══════════════════════════════════════════════════════════════
      Param.item_no              as ItemNo,
      Param.param_name           as ParamName,
      Param.param_label          as ParamLabel,
      
      // ═══════════════════════════════════════════════════════════════
      // Parameter Values
      // ═══════════════════════════════════════════════════════════════
      Param.param_value_from     as ParamValueFrom,
      Param.param_value_to       as ParamValueTo,
      Param.param_type           as ParamType,
      
      // ═══════════════════════════════════════════════════════════════
      // Display Value (From - To for ranges)
      // ═══════════════════════════════════════════════════════════════
      case Param.param_type
        when 'R' then concat( 
          concat( Param.param_value_from, ' - ' ), 
          Param.param_value_to 
        )
        else Param.param_value_from
      end                        as DisplayValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Metadata
      // ═══════════════════════════════════════════════════════════════
      Param.data_element         as DataElement,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Param.created_by           as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Param.created_at           as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Param.last_changed_by      as LastChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Param.last_changed_at      as LastChangedAt,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Param.local_last_changed_at as LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _JobHistory
}
