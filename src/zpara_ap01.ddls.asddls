@EndUserText.label: 'Parameters for AP Open & Aging Report'
define abstract entity ZPARA_ap01
{
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
  CompanyCode           : bukrs;

  @EndUserText.label: 'Key Date'
  KeyDate               : abap.dats;

  @EndUserText.label: 'Vendor'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
  Vendor                : lifnr;

  @EndUserText.label: 'Reconciliation Account'
  ReconciliationAccount : hkont;

  @EndUserText.label: 'Vendor Group'
  VendorGroup           : ktokk;

  @EndUserText.label: 'Payment Terms'
  PaymentTerms          : dzterm;

  @EndUserText.label: 'Country'
  Country               : land1;

  @EndUserText.label: 'Currency'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency' } }]
  Currency              : waers;
  
  @EndUserText.label: 'Output Format'
  OutputFormat          : abap.char(10); // ALV, Excel, CDS
}
