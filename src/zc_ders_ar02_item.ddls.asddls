define view entity ZC_DERS_AR02_ITEM
  as select from ZI_DERS_AR02

association to ZC_DERS_AR02 as _Header
    on  $projection.CompanyCode = _Header.CompanyCode
    and $projection.Customer    = _Header.Customer
    and $projection.FiscalYear  = _Header.FiscalYear
    and $projection.PostingDate = _Header.PostingDate

{

  key CompanyCode,
  key Customer,

  @UI.lineItem: [{ position: 10 }]
  key FiscalYear,

  @UI.lineItem: [{ position: 20 }]
  key AccountingDocument,

  @UI.lineItem: [{ position: 30 }]
  key AccountingDocumentItem,

  @UI.lineItem: [{ position: 40 }]
  PostingDate,
  
  @UI.lineItem: [{ position: 55 }]
  @EndUserText.label: 'Debit'
  Debit,
    
  @UI.lineItem: [{ position: 56 }]
  @EndUserText.label: 'Credit'
  Credit,
  
  @UI.lineItem: [{ position: 58 }]
  @EndUserText.label: 'Amount'
  Amount,
  
  @UI.lineItem: [{ position: 60 }]
  @EndUserText.label: 'Local Currency'
  LocalCurrency,

  _Header
}
