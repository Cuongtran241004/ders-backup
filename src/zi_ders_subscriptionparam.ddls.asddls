//=============================================================================
// CDS VIEW: ZI_DERS_SubscriptionParam
// TYPE: Interface View (Child Entity)
// PURPOSE: Subscription Parameter Business Object
// PARENT: ZI_DERS_Subscription [composition]
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Subscription Parameter Interface'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_DERS_SubscriptionParam
  as select from zders_sub_param as Param
  
  association to parent ZI_DERS_Subscription as _Subscription
    on $projection.SubscrUuid = _Subscription.SubscrUuid
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Param.subscr_uuid          as SubscrUuid,
  key Param.param_seq            as ParamSeq,
  
      // ═══════════════════════════════════════════════════════════════
      // Parameter Identity (from definition)
      // ═══════════════════════════════════════════════════════════════
      Param.param_name           as ParamName,
      Param.param_label          as ParamLabel,
      Param.param_type           as ParamType,
      
      // ═══════════════════════════════════════════════════════════════
      // Parameter Type Description (virtual)
      // ═══════════════════════════════════════════════════════════════
      case Param.param_type
        when 'S' then 'Single Value'
        when 'R' then 'Range'
        when 'M' then 'Multiple Selection'
        else 'Unknown'
      end                        as ParamTypeText,
      
      // ═══════════════════════════════════════════════════════════════
      // User Input Values
      // ═══════════════════════════════════════════════════════════════
      Param.param_value          as ParamValue,
      Param.param_value_from     as ParamValueFrom,
      Param.param_value_to       as ParamValueTo,
      
      // ═══════════════════════════════════════════════════════════════
      // Validation Metadata
      // ═══════════════════════════════════════════════════════════════
      Param.data_element         as DataElement,
      Param.is_mandatory         as IsMandatory,
      Param.default_value        as DefaultValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Computed: Effective Value
      // Shows which value will be used (user value or default)
      // ═══════════════════════════════════════════════════════════════
      case
        when Param.param_value is not initial
        then Param.param_value
        else Param.default_value
      end                        as EffectiveValue,
      
      // ═════════════════════════════════════════════════════════════== 
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
      // Association to Parent
      // ═══════════════════════════════════════════════════════════════
      _Subscription
}
