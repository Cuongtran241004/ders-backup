//=============================================================================
// CDS VIEW: ZI_DERS_Parameter
// TYPE: Interface View (Child Entity)
// PURPOSE: Report Parameter definition - child of ZI_DERS_Catalog
// PARENT: ZI_DERS_Catalog
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Parameter Interface View'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_DERS_Parameter
  as select from zders_param as Param
  
  association to parent ZI_DERS_Catalog as _Catalog 
    on $projection.ReportId = _Catalog.ReportId
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key Param.report_id            as ReportId,
  key Param.param_seq            as ParamSeq,
  
      // ═══════════════════════════════════════════════════════════════
      // Parameter Identity
      // ═══════════════════════════════════════════════════════════════
      Param.param_name           as ParamName,
      Param.param_label          as ParamLabel,
      Param.param_type           as ParamType,
      
      // ═══════════════════════════════════════════════════════════════
      // Data Type Reference
      // ═══════════════════════════════════════════════════════════════
      Param.data_element         as DataElement,
      
      // ═══════════════════════════════════════════════════════════════
      // Constraints
      // ═══════════════════════════════════════════════════════════════
      Param.is_mandatory         as IsMandatory,
      Param.default_value        as DefaultValue,
      Param.min_value            as MinValue,
      Param.max_value            as MaxValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Authorization Mapping
      // ═══════════════════════════════════════════════════════════════
      Param.auth_object          as AuthObject,
      Param.auth_field           as AuthField,
      
      // ═══════════════════════════════════════════════════════════════
      // F4 Help Configuration
      // ═══════════════════════════════════════════════════════════════
      Param.f4_cds_view          as F4CdsView,
      
      // ═══════════════════════════════════════════════════════════════
      // Derived: Parameter Type Description
      // ═══════════════════════════════════════════════════════════════
      case Param.param_type
        when 'S' then 'Single Value'
        when 'R' then 'Range'
        when 'M' then 'Multiple Selection'
        else 'Unknown'
      end                        as ParamTypeText,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @Semantics.user.createdBy: true
      Param.created_by           as CreatedBy,
      
      @Semantics.systemDateTime.createdAt: true
      Param.created_at           as CreatedAt,
      
      @Semantics.user.lastChangedBy: true
      Param.changed_by           as ChangedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      Param.changed_at           as ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Catalog
}
