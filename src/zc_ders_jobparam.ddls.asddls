//=============================================================================
// CDS VIEW: ZC_DERS_JobParam
// TYPE: Projection View (Consumption)
// PURPOSE: Job Parameter with UI annotations - child of ZC_DERS_JobHistory
// BASE: ZI_DERS_JobParam
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Parameter Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Parameter',
  typeNamePlural: 'Parameters',
  title.value: 'ParamLabel',
  description.value: 'DisplayValue'
}

define view entity ZC_DERS_JobParam
  as projection on ZI_DERS_JobParam
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key JobParamUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Parent Reference
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
      ParentUuid,
      
      // ═══════════════════════════════════════════════════════════════
      // Parameter Identity
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 10 }]
      ItemNo,
      
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 10 }]
      ParamName,
      
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 20 }]
      ParamLabel,
      
      // ═══════════════════════════════════════════════════════════════
      // Parameter Values
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 30 }]
      ParamValueFrom,
      
      @UI.lineItem: [{ position: 50 }]
      @UI.identification: [{ position: 40 }]
      ParamValueTo,
      
      @UI.lineItem: [{ position: 60 }]
      ParamType,
      
      // ═══════════════════════════════════════════════════════════════
      // Display Value
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 70 }]
      DisplayValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Metadata
      // ═══════════════════════════════════════════════════════════════
      DataElement,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _JobHistory : redirected to parent ZC_DERS_JobHistory
}
