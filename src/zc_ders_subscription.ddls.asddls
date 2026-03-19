//=============================================================================
// CDS VIEW: ZC_DERS_Subscription
// TYPE: Projection View (Consumption)
// PURPOSE: Subscription with UI annotations for Fiori
// BASE: ZI_DERS_Subscription
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Subscription Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Subscription',
  typeNamePlural: 'Subscriptions',
  title.value: 'SubscrName',
  description.value: 'ReportId'
}

@Search.searchable: true

define root view entity ZC_DERS_Subscription
  provider contract transactional_query
  as projection on ZI_DERS_Subscription
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
      @UI.facet: [
        { id: 'Header',   purpose: #HEADER,   type: #DATAPOINT_REFERENCE, targetQualifier: 'Status', position: 5 },
        { id: 'General',  purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 },
        { id: 'Parameters', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Report Parameters', position: 15, targetElement: '_Params' },
        { id: 'Schedule', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, label: 'Schedule', position: 20, targetQualifier: 'Schedule' },
        { id: 'Email',    purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, label: 'Email', position: 30, targetQualifier: 'Email' }
        // Note: JobHistory facet removed - access via dedicated JobHistory app
        // OData V4 blocks query options on 3-level deep navigation: Subscription→_JobHistory→_File
      ]
      
      // ═══════════════════════════════════════════════════════════════
      // ACTION BUTTONS - Visible in List and Object Page
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [
        { type: #FOR_ACTION, dataAction: 'executeNow', label: 'Execute Now', position: 1 },
        { type: #FOR_ACTION, dataAction: 'pause', label: 'Pause', position: 2 },
        { type: #FOR_ACTION, dataAction: 'resumeSubscription', label: 'Resume', position: 3 },
        { type: #FOR_ACTION, dataAction: 'cancelSubscription', label: 'Cancel', position: 4 }
      ]
      @UI.identification: [
        { type: #FOR_ACTION, dataAction: 'executeNow', label: 'Execute Now', position: 1 },
        { type: #FOR_ACTION, dataAction: 'pause', label: 'Pause', position: 2 },
        { type: #FOR_ACTION, dataAction: 'resumeSubscription', label: 'Resume', position: 3 },
        { type: #FOR_ACTION, dataAction: 'cancelSubscription', label: 'Cancel', position: 4 }
      ]
  key SubscrUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Subscription Identity
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
      UserId,
      
      @EndUserText.label: 'Subscription Name'
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
      SubscrName,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Configuration
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Report'
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
      ReportId,
      
      @EndUserText.label: 'Company Code'
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
      Bukrs,
      
      @EndUserText.label: 'Output Format'
      @UI.identification: [{ position: 40 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Format', element: 'FormatId' } }]
      OutputFormat,
      
      @EndUserText.label: 'Report Parameters (JSON)'
      @EndUserText.quickInfo: 'Example: {"from_date":"20260101","to_date":"20261231"}'
      @UI.identification: [{ position: 45 }]
      @UI.multiLineText: true
      ParamJson,
      
      // ═══════════════════════════════════════════════════════════════
      // Schedule Configuration
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Frequency'
      @UI.fieldGroup: [{ qualifier: 'Schedule', position: 10 }]
      @UI.lineItem: [{ position: 40 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Frequency', element: 'Frequency' } }]
      Frequency,
      
      @EndUserText.label: 'Execution Day'
      @EndUserText.quickInfo: 'Weekly: 1-7 (Mon-Sun), Monthly: 1-31, Daily: leave empty'
      @UI.fieldGroup: [{ qualifier: 'Schedule', position: 20 }]
      ExecDay,
      
      @EndUserText.label: 'Execution Time'
      @UI.fieldGroup: [{ qualifier: 'Schedule', position: 30 }]
      ExecTime,
      
      @EndUserText.label: 'Time Zone'
      @UI.fieldGroup: [{ qualifier: 'Schedule', position: 40 }]
      Tmzone,
      
      @EndUserText.label: 'Schedule'
      @UI.fieldGroup: [{ qualifier: 'Schedule', position: 50 }]
      ScheduleDescription,
      
      // ═══════════════════════════════════════════════════════════════
      // Email Configuration
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Email To'
      @UI.fieldGroup: [{ qualifier: 'Email', position: 10 }]
      EmailTo,
      
      @EndUserText.label: 'Email CC'
      @UI.fieldGroup: [{ qualifier: 'Email', position: 20 }]
      EmailCc,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Status'
      @UI.lineItem: [{ position: 50, criticality: 'StatusCriticality' }]
      @UI.identification: [{ position: 50, criticality: 'StatusCriticality' }]
      @UI.selectionField: [{ position: 30 }]
      @UI.dataPoint: { qualifier: 'Status', title: 'Status', criticality: 'StatusCriticality' }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Status', element: 'Status' } }]
      Status,
      
      @UI.hidden: true
      StatusCriticality,
      
      // ═══════════════════════════════════════════════════════════════
      // Tracking
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Next Run'
      @UI.lineItem: [{ position: 60 }]
      NextRunTs,
      
      @EndUserText.label: 'Last Run'
      @UI.lineItem: [{ position: 70 }]
      LastRunTs,
      
      @EndUserText.label: 'Run Count'
      RunCount,
      
      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Created By'
      CreatedBy,
      @EndUserText.label: 'Created At'
      CreatedAt,
      @EndUserText.label: 'Changed By'
      LastChangedBy,
      @EndUserText.label: 'Changed At'
      LastChangedAt,
      LocalLastChangedAt,
      
      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _JobHistory : redirected to ZC_DERS_JobHistory,
      _Catalog,
      _Company,
      _Frequency,
      _Status,
      
      // Compositions (Child Entities)
      _Params : redirected to composition child ZC_DERS_SubscriptionParam
}
