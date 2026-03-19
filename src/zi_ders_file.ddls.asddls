//=============================================================================
// CDS VIEW: ZI_DERS_File
// TYPE: Interface View (Child Entity)
// PURPOSE: File Metadata - child of ZI_DERS_JobHistory
// PARENT: ZI_DERS_JobHistory
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'File Metadata Interface View'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_DERS_File
  as select from zders_file as File
  
  association to parent ZI_DERS_JobHistory as _JobHistory 
    on $projection.JobUuid = _JobHistory.JobUuid
  
{
      // ═══════════════════════════════════════════════════════════════
      // Key Fields
      // ═══════════════════════════════════════════════════════════════
  key File.file_uuid             as FileUuid,
  
      // ═══════════════════════════════════════════════════════════════
      // Parent Reference
      // ═══════════════════════════════════════════════════════════════
      File.job_uuid              as JobUuid,
      
      // ═══════════════════════════════════════════════════════════════
      // File Metadata
      // ═══════════════════════════════════════════════════════════════
      File.file_name             as FileName,
      File.file_extension        as FileExtension,
      File.file_size_bytes       as FileSizeBytes,
      File.mime_type             as MimeType,
      
      // ═══════════════════════════════════════════════════════════════
      // Derived: Human Readable Size (simplified)
      // ═══════════════════════════════════════════════════════════════
      concat( cast( coalesce( File.file_size_bytes, 0 ) as abap.char(20) ), ' bytes' ) as FileSizeDisplay,
      
      // ═══════════════════════════════════════════════════════════════
      // Compression Info
      // ═══════════════════════════════════════════════════════════════
      File.compressed_size       as CompressedSize,
      File.is_compressed         as IsCompressed,
      
      // ═══════════════════════════════════════════════════════════════
      // Download Tracking
      // ═══════════════════════════════════════════════════════════════
      File.download_count        as DownloadCount,
      File.last_download_at      as LastDownloadAt,
      File.last_download_by      as LastDownloadBy,
      
      // ═══════════════════════════════════════════════════════════════
      // Lifecycle
      // ═══════════════════════════════════════════════════════════════
      File.created_at            as CreatedAt,
      File.created_by            as CreatedBy,

      // ═══════════════════════════════════════════════════════════════
      // STREAM: Raw file content served via OData $value endpoint
      // @Semantics.largeObject enables automatic browser download
      // ═══════════════════════════════════════════════════════════════
      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #ATTACHMENT
      }
      File.file_content          as FileContent,

      // ═══════════════════════════════════════════════════════════════
      // Associations
      // ═══════════════════════════════════════════════════════════════
      _JobHistory
}
