//=============================================================================
// CDS VIEW: ZVH_DERS_Status
// TYPE: Value Help View
// PURPOSE: Entity Status dropdown F4 help
// SOURCE: ZDERS_STATUS_VT
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Status Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.dataClass: #CUSTOMIZING

@Search.searchable: true

define view entity ZVH_DERS_Status
  as select from zders_status_vt
{
      @ObjectModel.text.element: ['Description']
      @Search.defaultSearchElement: true
  key status      as Status,
  
      @Semantics.text: true
      description as Description,
      
      criticality as Criticality
}
