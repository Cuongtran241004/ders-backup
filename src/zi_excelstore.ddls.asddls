@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Excel Store Entity'

define root view entity ZI_ExcelStore
  as select from zders_excelstore
{
    key file_id,

    @Semantics.largeObject: { 
        mimeType: 'mimetype', 
        fileName: 'filename', 
        contentDispositionPreference: #ATTACHMENT 
    }
    attachment,

    @Semantics.mimeType: true
    mimetype,

    @EndUserText.label: 'File Name'
    filename,

    @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at,

    /* Trường ảo để chứa URL trả về cho UI */
    @ObjectModel.virtualElement: true
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DERS_CALC_URL'
    cast( '' as abap.sstring(1024) ) as DownloadUrl
}
