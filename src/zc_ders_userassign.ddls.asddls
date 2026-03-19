//=============================================================================
// CDS VIEW: ZC_DERS_UserAssign
// TYPE: Consumption View (Projection)
// PURPOSE: Admin UI for user-company assignment
//
// USAGE:
// - Exposed in OData service for Admin Fiori app
// - Admin assigns users to company codes with business roles
// - After assignment, admin can click "Generate Permissions" action
//
// UI ELEMENTS:
// - List Report: All user assignments with filters
// - Object Page: User details + Generate Permissions button
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'User-Company Assignment (Admin)'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'User Assignment',
  typeNamePlural: 'User Assignments',
  title: { value: 'UserId' },
  description: { value: 'CompanyName' }
}

@Search.searchable: true

define root view entity ZC_DERS_UserAssign
  as projection on ZI_DERS_UserAssign
{
      //=======================================================================
      // Key Fields
      //=======================================================================
      @UI.facet: [
        { id: 'GeneralInfo', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Assignment Details', position: 10 }
      ]
      
      @UI.lineItem: [
        { position: 10, importance: #HIGH },
        { type: #FOR_ACTION, dataAction: 'generatePermissions', label: 'Generate Permissions' }
      ]
      @UI.identification: [
        { position: 10 },
        { type: #FOR_ACTION, dataAction: 'generatePermissions', label: 'Generate Permissions' }
      ]
      @Search.defaultSearchElement: true
  key UserId,
  
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      @UI.identification: [{ position: 20 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  key Bukrs,
  
      //=======================================================================
      // Role Assignment
      //=======================================================================
      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 30 }]
      @EndUserText.label: 'Business Role'
      BusinessRole,
      
      //=======================================================================
      // Status
      //=======================================================================
      @UI.lineItem: [{ position: 40, importance: #HIGH, criticality: 'StatusCriticality' }]
      @UI.identification: [{ position: 40 }]
      @EndUserText.label: 'Active'
      IsActive,
      
      @UI.hidden: true
      StatusCriticality,
      
      //=======================================================================
      // Administrative Data
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
      _Company,
      
      // Association to permissions (NOT redirected - separate BO)
      // Use this for navigation/filtering, not for embedded list
      // To see permissions, navigate to UserPermissions app
      _Permissions
}
