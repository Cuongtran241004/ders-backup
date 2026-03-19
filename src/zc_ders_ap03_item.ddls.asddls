@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Item of AP03'
@Metadata.ignorePropagatedAnnotations: true

@Search.searchable: true

define view entity ZC_DERS_AP03_ITEM
  as select from ZI_DERS_AP03

  association to ZC_DERS_AP03 as _Header
    on  $projection.CompanyCode = _Header.CompanyCode
    and $projection.Supplier    = _Header.Supplier

{

  @EndUserText.label: 'Company Code'
  key CompanyCode,

  @EndUserText.label: 'Supplier'
  key Supplier,

  @EndUserText.label: 'Fiscal Year'
  key FiscalYear,

  @EndUserText.label: 'Accounting Document'
  @UI.lineItem: [{ position: 5 }]
  key AccountingDocument,

  @EndUserText.label: 'Accounting Document Item'
  key AccountingDocumentItem,

  @EndUserText.label: 'Supplier Name'
  @UI.lineItem: [{ position: 10 }]
  SupplierName,

  @EndUserText.label: 'Posting Date'
  @UI.lineItem: [{ position: 20 }]
  PostingDate,

  @EndUserText.label: 'Document Date'
  @UI.lineItem: [{ position: 30 }]
  DocumentDate,

  @EndUserText.label: 'Net Due Date'
  @UI.lineItem: [{ position: 40 }]
  NetDueDate,

  @EndUserText.label: 'Document Type'
  @UI.lineItem: [{ position: 50 }]
  AccountingDocumentType,

  @EndUserText.label: 'Original Amount'
  @UI.lineItem: [{ position: 60 }]
  @Semantics.amount.currencyCode: 'LocalCurrency'
  OriginalAmount,

  @EndUserText.label: 'Currency'
  LocalCurrency,

  _Header
}
