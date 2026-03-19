@EndUserText.label: 'Download File Report'
define abstract entity ZI_FileDownload
{
  key FileName    : abap.char(255); 
  
  @Semantics.mimeType: true
  MimeType    : abap.char(128);
  
  @Semantics.largeObject: { 
      contentDispositionPreference: #ATTACHMENT, 
      fileName: 'FileName', 
      mimeType: 'MimeType' 
  }
  FileContent : abap.rawstring;
}
   
