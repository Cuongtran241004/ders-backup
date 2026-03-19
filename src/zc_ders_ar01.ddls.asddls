@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Customer Summary'
@Metadata.allowExtensions: true

define root view entity ZC_DERS_AR01
  as select from ZI_DERS_AR01_HEADER
      ( p_key_date : $session.system_date )

  composition [0..*] of ZC_DERS_AR01_ITEM as _Items
{
  @UI.selectionField: [{ position: 5 }]
  @Consumption.valueHelpDefinition: [{
      entity: { name: 'I_Ledger', element: 'Ledger' }
  }]
  key Ledger,

  key SourceLedger,

  @UI.selectionField: [{ position: 10 }]
  @Consumption.filter.mandatory: true
  @Consumption.valueHelpDefinition: [{
      entity: { name: 'I_CompanyCode', element: 'CompanyCode' }
  }]
  key CompanyCode,

  @UI.lineItem: [{ position: 10 }]
  @UI.selectionField: [{ position: 20 }]
  @Consumption.valueHelpDefinition: [{
      entity: { name: 'I_Customer', element: 'Customer' }
  }]
  key Customer,

  @UI.lineItem: [{ position: 20 }]
  CustomerName,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  @UI.lineItem: [{ position: 30 }]
  TotalOpenAmount,

  LocalCurrency,

  @UI.lineItem: [{ position: 40 }]
  MaxDaysOverdue,

  _Items
}
