//=============================================================================
// CDS VIEW: ZC_DERS_Parameter
// TYPE: Projection View (Consumption)
// PURPOSE: Report Parameter with UI annotations - child of ZC_DERS_Catalog
// BASE: ZI_DERS_Parameter
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Parameter Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Parameter',
  typeNamePlural: 'Parameters',
  title.value: 'ParamLabel',
  description.value: 'ParamName'
}

define view entity ZC_DERS_Parameter
  as projection on ZI_DERS_Parameter
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
  key ReportId,
  
      @UI.lineItem: [{ position: 10 }]
  key ParamSeq,
  
      // ═══════════════════════════════════════════════════════════════
      // Parameter Identity
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 10 }]
      ParamName,
      
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 20 }]
      ParamLabel,
      
      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 30 }]
      ParamType,
      
      @UI.lineItem: [{ position: 50 }]
      ParamTypeText,
      
      // ═══════════════════════════════════════════════════════════════
      // Data Type Reference
      // ═══════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 40 }]
      DataElement,
      
      // ═══════════════════════════════════════════════════════════════
      // Constraints
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 60 }]
      @UI.identification: [{ position: 50 }]
      IsMandatory,
      
      @UI.identification: [{ position: 60 }]
      DefaultValue,
      
      @UI.identification: [{ position: 70 }]
      MinValue,
      
      @UI.identification: [{ position: 80 }]
      MaxValue,
      
      // ═══════════════════════════════════════════════════════════════
      // Authorization Mapping
      // ═══════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 90 }]
      AuthObject,
      
      @UI.identification: [{ position: 100 }]
      AuthField,
      
      // ═══════════════════════════════════════════════════════════════
      // F4 Help Configuration
      // ═══════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 110 }]
      F4CdsView,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      CreatedBy,
      CreatedAt,
      ChangedBy,
      ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Catalog : redirected to parent ZC_DERS_Catalog
}
