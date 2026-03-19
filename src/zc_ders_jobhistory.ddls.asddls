//=============================================================================
// CDS VIEW: ZC_DERS_JobHistory
// TYPE: Projection View (Consumption) - Child
// PURPOSE: Job History with UI annotations for Fiori
// BASE: ZI_DERS_JobHistory
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Job History Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Job',
  typeNamePlural: 'Jobs',
  title.value: 'JobId',
  description.value: 'ReportId'
}

@Search.searchable: true

define root view entity ZC_DERS_JobHistory
  as projection on ZI_DERS_JobHistory
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
      @UI.facet: [
        { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 },
        { id: 'Execution', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, label: 'Execution', position: 20, targetQualifier: 'Execution' },
        { id: 'Parameters', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Parameters', position: 30, targetElement: '_Parameters' },
        { id: 'File', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Output File', position: 40, targetElement: '_File' }
      ]
      
      // ═══════════════════════════════════════════════════════════════
      // ACTION BUTTONS
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [
        { type: #FOR_ACTION, dataAction: 'retry', label: 'Retry', position: 1 },
        { type: #FOR_ACTION, dataAction: 'cancelJob', label: 'Cancel Job', position: 2 }
      ]
      @UI.identification: [
        { type: #FOR_ACTION, dataAction: 'retry', label: 'Retry', position: 1 },
        { type: #FOR_ACTION, dataAction: 'cancelJob', label: 'Cancel Job', position: 2 }
      ]
  key JobUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Identification
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Job ID'
      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
      @Search.defaultSearchElement: true
      JobId,
      
      @EndUserText.label: 'Job Type'
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      JobType,
      
      @UI.hidden: true
      SourceUuid,
      
      // ═══════════════════════════════════════════════════════════════
      // Report Reference
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Report'
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
      ReportId,
      
      @EndUserText.label: 'User'
      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 40 }]
      UserId,
      
      @EndUserText.label: 'Company Code'
      @UI.selectionField: [{ position: 20 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
      Bukrs,
      
      // ═══════════════════════════════════════════════════════════════
      // Parameters
      // ═══════════════════════════════════════════════════════════════
      @UI.hidden: true
      ParamJson,
      
      @EndUserText.label: 'Output Format'
      @UI.identification: [{ position: 50 }]
      OutputFormat,
      
      // ═══════════════════════════════════════════════════════════════
      // Status
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Status'
      @UI.lineItem: [{ position: 50, criticality: 'StatusCriticality', importance: #HIGH }]
      @UI.identification: [{ position: 60, criticality: 'StatusCriticality' }]
      @UI.selectionField: [{ position: 30 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_JobStatus', element: 'Status' } }]
      Status,
      
      @UI.hidden: true
      StatusCriticality,
      
      // StatusIcon,
      
      // ═══════════════════════════════════════════════════════════════
      // Timestamps
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Scheduled At'
      @UI.fieldGroup: [{ qualifier: 'Execution', position: 10 }]
      ScheduledTs,
      
      @EndUserText.label: 'Started At'
      @UI.lineItem: [{ position: 60 }]
      @UI.fieldGroup: [{ qualifier: 'Execution', position: 20 }]
      StartedTs,
      
      @EndUserText.label: 'Completed At'
      @UI.lineItem: [{ position: 70 }]
      @UI.fieldGroup: [{ qualifier: 'Execution', position: 30 }]
      CompletedTs,
      
      // ═══════════════════════════════════════════════════════════════
      // Execution Metrics
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Rows Processed'
      @UI.lineItem: [{ position: 80 }]
      @UI.fieldGroup: [{ qualifier: 'Execution', position: 40 }]
      RowsProcessed,
      
      @UI.hidden: true
      FileUuid,
      
      // ═══════════════════════════════════════════════════════════════
      // Error Information
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Error Message'
      @UI.fieldGroup: [{ qualifier: 'Execution', position: 50 }]
      ErrorMessage,
      
      @EndUserText.label: 'Error Code'
      @UI.fieldGroup: [{ qualifier: 'Execution', position: 60 }]
      ErrorCode,
      
      // ═══════════════════════════════════════════════════════════════
      // Background Job Link
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'BG Job Name'
      BgJobName,
      @EndUserText.label: 'BG Job Count'
      BgJobCount,
      
      // ═══════════════════════════════════════════════════════════════
      // Application Job v5 Fields
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Job Template'
      JobTemplateName,
      @EndUserText.label: 'Run Type'
      RunType,
      @EndUserText.label: 'Start Immediately'
      StartImmediately,
      @EndUserText.label: 'Start Timestamp'
      StartTimestamp,
      @EndUserText.label: 'Is Periodic'
      IsPeriodic,
      @EndUserText.label: 'Periodic Granularity'
      PeriodicGranularity,
      @EndUserText.label: 'Periodic Value'
      PeriodicValue,
      @EndUserText.label: 'Time Zone'
      Tmzone,
      @EndUserText.label: 'Priority'
      Priority,
      
      // ═══════════════════════════════════════════════════════════════
      // Retry & Recovery
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Retry Of Job'
      RetryOfJob,
      @EndUserText.label: 'Retry Count'
      RetryCount,
      
      // ═══════════════════════════════════════════════════════════════
      // Email Status
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Email Sent'
      EmailSent,
      @EndUserText.label: 'Email Sent At'
      EmailSentTs,
      
      // ═══════════════════════════════════════════════════════════════
      // Archiving
      // ═══════════════════════════════════════════════════════════════
      @EndUserText.label: 'Archived'
      IsArchived,
      @EndUserText.label: 'Archived Date'
      ArchivedDate,
      @EndUserText.label: 'Retention Until'
      RetentionUntil,
      
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
      _Parameters : redirected to composition child ZC_DERS_JobParam,
      _File       : redirected to composition child ZC_DERS_File,
      _Catalog,
      _JobStatus
}
