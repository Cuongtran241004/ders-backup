//=============================================================================
// CDS VIEW: ZVH_DERS_Module
// TYPE: Value Help View
// PURPOSE: Module dropdown F4 help
// SOURCE: ZDERS_MODULE_VT
//=============================================================================
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Module Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.dataClass: #CUSTOMIZING

@Search.searchable: true

define view entity ZVH_DERS_Module
  as select from zders_module_vt
{
      @ObjectModel.text.element: ['Description']
      @Search.defaultSearchElement: true
  key module_id   as ModuleId,
  
      @Semantics.text: true
      @Search.defaultSearchElement: true
      description as Description,
      
      is_active   as IsActive
}
where is_active = 'X'
