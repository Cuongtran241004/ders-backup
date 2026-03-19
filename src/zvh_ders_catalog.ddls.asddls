//=============================================================================
// CDS VIEW: ZVH_DERS_Catalog
// TYPE: Value Help View
// PURPOSE: Report Catalog dropdown F4 help
// SOURCE: ZDERS_CATALOG
//=============================================================================
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #M
@ObjectModel.usageType.dataClass: #MASTER

@Search.searchable: true

define view entity ZVH_DERS_Catalog
  as select from zders_catalog
{
      @ObjectModel.text.element: ['ReportName']
      @Search.defaultSearchElement: true
  key report_id   as ReportId,
  
      @Semantics.text: true
      @Search.defaultSearchElement: true
      @Search.ranking: #HIGH
      report_name as ReportName,
      
      @Search.defaultSearchElement: true
      module_id   as ModuleId,
      
      description as Description
}
where is_active = 'X'
