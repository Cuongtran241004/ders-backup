//=============================================================================
// CDS VIEW: ZC_DERS_RolePerm
// TYPE: Projection View (Admin UI)
// PURPOSE: Role-to-Report permission management UI
//
// BASE: ZI_DERS_RolePerm
// UI: Fiori Elements List Report + Object Page
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Role Report Permissions'
@Metadata.allowExtensions: true

@UI: {
  headerInfo: {
    typeName: 'Role Permission',
    typeNamePlural: 'Role Permissions',
    title: { type: #STANDARD, value: 'BusinessRole' },
    description: { type: #STANDARD, value: 'ReportId' }
  }
}

@Search.searchable: true

define root view entity ZC_DERS_RolePerm
  provider contract transactional_query
  as projection on ZI_DERS_RolePerm
{
      //═══════════════════════════════════════════════════════════════════════
      // KEY FIELDS
      //═══════════════════════════════════════════════════════════════════════
      @UI.facet: [
        { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General Information', position: 10 },
        { id: 'Permissions', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'Permissions', label: 'Permission Flags', position: 20 },
        { id: 'Admin', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'Admin', label: 'Administrative Data', position: 30 }
      ]

      @UI: {
        lineItem: [{ position: 10, importance: #HIGH }],
        identification: [{ position: 10 }],
        selectionField: [{ position: 10 }]
      }
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Business Role'
  key BusinessRole,

      @UI: {
        lineItem: [{ position: 20, importance: #HIGH }],
        identification: [{ position: 20 }],
        selectionField: [{ position: 20 }]
      }
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
      @EndUserText.label: 'Report ID'
  key ReportId,

      //═══════════════════════════════════════════════════════════════════════
      // PERMISSION FLAGS
      //═══════════════════════════════════════════════════════════════════════
      @UI: {
        lineItem: [{ position: 30, importance: #MEDIUM }],
        fieldGroup: [{ qualifier: 'Permissions', position: 10 }]
      }
      @EndUserText.label: 'Can Export'
      CanExport,

      @UI: {
        lineItem: [{ position: 40, importance: #MEDIUM }],
        fieldGroup: [{ qualifier: 'Permissions', position: 20 }]
      }
      @EndUserText.label: 'Can Subscribe'
      CanSubscribe,

      @UI: {
        lineItem: [{ position: 50, importance: #MEDIUM }],
        fieldGroup: [{ qualifier: 'Permissions', position: 30 }]
      }
      @EndUserText.label: 'Is Default'
      IsDefault,

      //═══════════════════════════════════════════════════════════════════════
      // STATUS
      //═══════════════════════════════════════════════════════════════════════
      @UI: {
        lineItem: [{ position: 60, importance: #HIGH, criticality: 'StatusCriticality' }],
        identification: [{ position: 30, criticality: 'StatusCriticality' }]
      }
      @EndUserText.label: 'Active'
      IsActive,

      @UI.hidden: true
      StatusCriticality,

      //═══════════════════════════════════════════════════════════════════════
      // ADMINISTRATIVE DATA
      //═══════════════════════════════════════════════════════════════════════
      @UI.fieldGroup: [{ qualifier: 'Admin', position: 10 }]
      @EndUserText.label: 'Created By'
      CreatedBy,

      @UI.fieldGroup: [{ qualifier: 'Admin', position: 20 }]
      @EndUserText.label: 'Created At'
      CreatedAt,

      @UI.fieldGroup: [{ qualifier: 'Admin', position: 30 }]
      @EndUserText.label: 'Changed By'
      ChangedBy,

      @UI.fieldGroup: [{ qualifier: 'Admin', position: 40 }]
      @EndUserText.label: 'Changed At'
      ChangedAt,

      //═══════════════════════════════════════════════════════════════════════
      // ASSOCIATIONS
      //═══════════════════════════════════════════════════════════════════════
      _Catalog
}
