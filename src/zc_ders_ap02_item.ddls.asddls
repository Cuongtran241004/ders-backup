define view entity ZC_DERS_AP02_ITEM
  as select from ZI_DERS_AP02

association to ZC_DERS_AP02 as _Header
    on  $projection.CompanyCode = _Header.CompanyCode
    and $projection.Supplier    = _Header.Supplier
    and $projection.FiscalYear  = _Header.FiscalYear
    and $projection.PostingDate = _Header.PostingDate

{

  key CompanyCode,
  key Supplier,

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
