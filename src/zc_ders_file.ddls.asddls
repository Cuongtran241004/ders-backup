//=============================================================================
// CDS VIEW: ZC_DERS_File
// TYPE: Projection View (Consumption)
// PURPOSE: File Metadata with UI annotations - child of ZC_DERS_JobHistory
// BASE: ZI_DERS_File
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'File Metadata Projection'
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'Report File',
  typeNamePlural: 'Report Files',
  title: { type: #STANDARD, value: 'FileName' },
  description: { value: 'MimeType' }
}

define view entity ZC_DERS_File
  as projection on ZI_DERS_File
{
      @UI.facet: [
        { id: 'FileDetails', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'FileDetails', label: 'File Details',        position: 10 },
        { id: 'AdminData',   purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'AdminData',   label: 'Administrative Data', position: 20 }
      ]
      @UI.hidden: true
  key FileUuid,

      @UI.hidden: true
      JobUuid,

      // ═══════════════════════════════════════════════════════════════
      // File Metadata
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 20 }]
      @EndUserText.label: 'File Name'
      FileName,

      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 30 }]
      @EndUserText.label: 'File Content'
      FileContent,

      @UI.hidden: true
      FileSizeBytes,

      @UI.lineItem: [{ position: 40, importance: #HIGH }]
      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 40 }]
      @EndUserText.label: 'File Size'
      FileSizeDisplay,

      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 50 }]
      FileExtension,

      @UI.hidden: true
      MimeType,

      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 60 }]
      CompressedSize,

      @UI.hidden: true
      IsCompressed,

      // ═══════════════════════════════════════════════════════════════
      // Download Tracking
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 70 }]
      DownloadCount,

      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 80 }]
      LastDownloadAt,

      @UI.fieldGroup: [{ qualifier: 'FileDetails', position: 90 }]
      LastDownloadBy,

      // ═══════════════════════════════════════════════════════════════
      // Administrative Data
      // ═══════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 60, importance: #MEDIUM }]
      @UI.fieldGroup: [{ qualifier: 'AdminData', position: 10 }]
      @EndUserText.label: 'Created By'
      CreatedBy,

      @UI.lineItem: [{ position: 70, importance: #MEDIUM }]
      @UI.fieldGroup: [{ qualifier: 'AdminData', position: 20 }]
      @EndUserText.label: 'Created At'
      CreatedAt,

      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _JobHistory : redirected to parent ZC_DERS_JobHistory
}
