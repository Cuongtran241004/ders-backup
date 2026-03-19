//=============================================================================
// CDS VIEW: ZVH_DERS_Format
// TYPE: Value Help View
// PURPOSE: Output Format dropdown F4 help
// SOURCE: ZDERS_FORMAT_VT
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Output Format Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.dataClass: #CUSTOMIZING

@Search.searchable: true

define view entity ZVH_DERS_Format
  as select from zders_format_vt
{
      @ObjectModel.text.element: ['Description']
      @Search.defaultSearchElement: true
  key format_id       as FormatId,
  
      @Semantics.text: true
      description     as Description,
      
      file_extension  as FileExtension,
      mime_type       as MimeType
}
where is_active = 'X'
