@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Frequency Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.dataClass: #CUSTOMIZING
@Search.searchable: true

define view entity ZVH_DERS_Frequency
  as select from zders_freq_vt
{
      @ObjectModel.text.element: ['Description']
      @Search.defaultSearchElement: true
  key frequency    as Frequency,
  
      @Semantics.text: true
      description  as Description,
      
      cron_pattern as CronPattern
}
where is_active = 'X'
