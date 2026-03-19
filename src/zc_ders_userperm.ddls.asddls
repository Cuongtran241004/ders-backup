//=============================================================================
// CDS VIEW: ZC_DERS_UserPerm
// TYPE: Consumption View (Projection)
// PURPOSE: Admin UI for managing user report permissions
//
// USAGE:
// - Exposed in OData service for Admin Fiori app
// - Allows admin to view, create, update, delete user permissions
// - Shows permission type (Default from role vs Override by admin)
//
// UI ELEMENTS:
// - List Report: All user permissions with filters
// - Object Page: Edit permission details
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'User Permissions (Admin)'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Permission',
  typeNamePlural: 'User Permissions',
  title: { value: 'UserId' },
  description: { value: 'ReportName' }
}

@Search.searchable: true

define root view entity ZC_DERS_UserPerm
  as projection on ZI_DERS_UserPerm
{
      //=======================================================================
      // Key Fields
      //=======================================================================
      @UI.facet: [
        { id: 'GeneralInfo', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Permission Details', position: 10 }
      ]
      
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
      @UI.identification: [{ position: 10 }]
      @Search.defaultSearchElement: true
  key UserId,
  
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      @UI.identification: [{ position: 20 }]
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
  key ReportId,
  
      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 30 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  key Bukrs,
  
      //=======================================================================
      // Permission Flags
      //=======================================================================
      @UI.lineItem: [{ position: 40, importance: #MEDIUM }]
      @UI.identification: [{ position: 40 }]
      @EndUserText.label: 'Can Export'
      CanExport,
      
      @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
      @UI.identification: [{ position: 50 }]
      @EndUserText.label: 'Can Subscribe'
      CanSubscribe,
      
      //=======================================================================
      // Permission Type
      //=======================================================================
      @UI.lineItem: [{ position: 60, importance: #LOW }]
      @UI.identification: [{ position: 60 }]
      @EndUserText.label: 'Permission Type'
      PermType,
      
      @UI.lineItem: [{ position: 65, importance: #LOW }]
      PermTypeText,
      
      //=======================================================================
      // Status
      //=======================================================================
      @UI.lineItem: [{ position: 70, importance: #HIGH, criticality: 'StatusCriticality' }]
      @UI.identification: [{ position: 70 }]
      @EndUserText.label: 'Active'
      IsActive,
      
      @UI.hidden: true
      StatusCriticality,
      
      //=======================================================================
      // Administrative Data (collapsed section)
      //=======================================================================
      @UI.identification: [{ position: 100, label: 'Created By' }]
      CreatedBy,
      
      @UI.identification: [{ position: 110, label: 'Created At' }]
      CreatedAt,
      
      @UI.identification: [{ position: 120, label: 'Changed By' }]
      ChangedBy,
      
      @UI.identification: [{ position: 130, label: 'Changed At' }]
      ChangedAt,
      
      //=======================================================================
      // Associations
      //=======================================================================
      _Catalog,
      _Company
}
