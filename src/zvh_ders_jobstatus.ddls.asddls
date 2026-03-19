//=============================================================================
// CDS VIEW: ZVH_DERS_JobStatus
// TYPE: Value Help View
// PURPOSE: Job Status dropdown F4 help
// SOURCE: ZDERS_JOBSTAT_VT
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Status Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.dataClass: #CUSTOMIZING

@Search.searchable: true

define view entity ZVH_DERS_JobStatus
  as select from zders_jobstat_vt
{
      @ObjectModel.text.element: ['Description']
      @Search.defaultSearchElement: true
  key status      as Status,
  
      @Semantics.text: true
      description as Description,
      
      criticality as Criticality,
      icon        as Icon
}
