//=============================================================================
// CDS VIEW: ZC_DERS_Catalog
// TYPE: Projection View (Consumption)
// PURPOSE: Report Catalog with UI annotations for Fiori
// BASE: ZI_DERS_Catalog
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Report',
  typeNamePlural: 'Reports',
  title.value: 'ReportName',
  description.value: 'Description'
}

@Search.searchable: true

define root view entity ZC_DERS_Catalog
  provider contract transactional_query
  as projection on ZI_DERS_Catalog
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
      @Search.defaultSearchElement: true
      @UI.facet: [
        { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 },
        { id: 'Parameters', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Parameters', position: 20, targetElement: '_Parameters' }
      ]
      @UI.lineItem: [
        { position: 10 },
        { type: #FOR_ACTION, dataAction: 'activateReport', label: 'Activate', position: 1 },
        { type: #FOR_ACTION, dataAction: 'deactivateReport', label: 'Deactivate', position: 2 }
      ]
      @UI.identification: [
        { position: 10 },
        { type: #FOR_ACTION, dataAction: 'activateReport', label: 'Activate', position: 1 },
        { type: #FOR_ACTION, dataAction: 'deactivateReport', label: 'Deactivate', position: 2 }
      ]
  key ReportId,
  
      // ═══════════════════════════════════════════════════════════════
      // Classification
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Module', element: 'ModuleId' } }]
      ModuleId,
      
      @UI.identification: [{ position: 30 }]
      TargetRole,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Metadata
      // ═══════════════════════════════════════════════════════════════
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 40 }]
      ReportName,
      
      @Search.defaultSearchElement: true
      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 50 }]
      Description,
      
      // ═══════════════════════════════════════════════════════════════
      // Technical Configuration
      // ═══════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 60 }]
      CdsViewName,
      
      @UI.identification: [{ position: 70 }]
      SupportedFormats,
      
      // ═══════════════════════════════════════════════════════════════
      // Limits
      // ═══════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 80 }]
      MaxRows,
      
      @UI.identification: [{ position: 90 }]
      EstimatedRuntime,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 50, criticality: 'ActiveCriticality' }]
      @UI.identification: [{ position: 100, criticality: 'ActiveCriticality' }]
      @UI.selectionField: [{ position: 20 }]
      IsActive,
      
      @UI.hidden: true
      ActiveCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Virtual Elements
      // ═══════════════════════════════════════════════════════════════
      SupportsExcel,
      SupportsPdf,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 60 }]
      CreatedBy,
      
      @UI.lineItem: [{ position: 70 }]
      CreatedAt,
      
      ChangedBy,
      ChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Parameters : redirected to composition child ZC_DERS_Parameter,
      _Module,
      _Company
}
