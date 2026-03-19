//=============================================================================
// ABSTRACT ENTITY: ZA_DERS_QuickSubscription
// PURPOSE: Parameter structure for createQuickSubscription action
//=============================================================================
@EndUserText.label: 'Quick Subscription Parameters'

define abstract entity ZA_DERS_QuickSubscription
{
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Catalog', element: 'ReportId' } }]
  @EndUserText.label: 'Report ID'
  ReportId      : abap.char(10);
  
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  @EndUserText.label: 'Company Code'
  Bukrs         : bukrs;
  
  @EndUserText.label: 'Subscription Name'
  SubscrName    : abap.char(50);
  
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Format', element: 'Format' } }]
  @EndUserText.label: 'Output Format'
  OutputFormat  : abap.char(4);
  
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_DERS_Frequency', element: 'Frequency' } }]
  @EndUserText.label: 'Frequency'
  Frequency     : abap.char(1);
  
  @EndUserText.label: 'Execution Time'
  ExecTime      : abap.tims;
  
  @EndUserText.label: 'Email Recipients'
  EmailTo       : abap.char(255);
}
