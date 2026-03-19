//=============================================================================
// ABSTRACT ENTITY: ZA_DERS_CreateFromTemplate
// PURPOSE: Parameter structure for createFromTemplate action
//=============================================================================
@EndUserText.label: 'Create Report from Template Parameters'

define abstract entity ZA_DERS_CreateFromTemplate
{
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
  @EndUserText.label: 'Template Report ID'
  TemplateReportId : abap.char(10);
  
  @EndUserText.label: 'New Report ID'
  NewReportId      : abap.char(10);
  
  @EndUserText.label: 'New Report Name'
  NewReportName    : abap.char(50);
  
  @EndUserText.label: 'Copy Parameters'
  CopyParameters   : abap_boolean;
}
