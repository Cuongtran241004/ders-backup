//=============================================================================
// CDS VIEW: ZC_DERS_Export
// TYPE: Projection View (Consumption)
// PURPOSE: Export Request with UI annotations for Fiori
// BASE: ZI_DERS_Export
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Export Request Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Export',
  typeNamePlural: 'Exports',
  title.value: 'ExportId',
  description.value: 'ReportId'
}

@Search.searchable: true

define root view entity ZC_DERS_Export
  provider contract transactional_query
  as projection on ZI_DERS_Export
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
      @UI.facet: [
        { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 }
      ]
      
      // ═══════════════════════════════════════════════════════════════
      // ACTION BUTTONS
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [
        { type: #FOR_ACTION, dataAction: 'execute', label: 'Execute', position: 1 },
        { type: #FOR_ACTION, dataAction: 'cancel', label: 'Cancel', position: 2 },
        { type: #FOR_ACTION, dataAction: 'download', label: 'Download', position: 3 }
      ]
      @UI.identification: [
        { type: #FOR_ACTION, dataAction: 'execute', label: 'Execute', position: 1 },
        { type: #FOR_ACTION, dataAction: 'cancel', label: 'Cancel', position: 2 },
        { type: #FOR_ACTION, dataAction: 'download', label: 'Download', position: 3 }
      ]
  key ExportUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Export Identity
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
      @Search.defaultSearchElement: true
      ExportId,
      
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      UserId,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Configuration
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
      ReportId,
      
      @UI.identification: [{ position: 40 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Format', element: 'FormatId' } }]
      OutputFormat,
      
      @UI.hidden: true
      ParamJson,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 40, criticality: 'StatusCriticality' }]
      @UI.identification: [{ position: 50, criticality: 'StatusCriticality' }]
      @UI.selectionField: [{ position: 20 }]
      Status,
      
      @UI.hidden: true
      StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Email Configuration
      // ═══════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 60 }]
      SendEmail,
      
      @UI.identification: [{ position: 70 }]
      EmailTo,
      
      @UI.identification: [{ position: 80 }]
      EmailCc,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 50 }]
      CreatedBy,
      
      @UI.lineItem: [{ position: 60 }]
      CreatedAt,
      
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _Catalog
}
