@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AP Aging - Item Details'
@Metadata.allowExtensions: true

define view entity ZC_DERS_AP01_ITEM
  as select from ZI_DERS_AP01

  association to parent ZC_DERS_AP01 as _Header
    on  $projection.Ledger       = _Header.Ledger
    and $projection.SourceLedger = _Header.SourceLedger
    and $projection.CompanyCode  = _Header.CompanyCode
    and $projection.Supplier     = _Header.Supplier
{

  @EndUserText.label: 'Ledger'
  key Ledger,

  @EndUserText.label: 'Source Ledger'
  key SourceLedger,

  @EndUserText.label: 'Company Code'
  key CompanyCode,

  @EndUserText.label: 'Vendor'
  key Supplier,


  @UI.lineItem: [{ position: 10 }]
  @EndUserText.label: 'Accounting Document'
  key AccountingDocument,


  @EndUserText.label: 'Fiscal Year'
  key FiscalYear,


  @EndUserText.label: 'G/L Line Item'
  key LedgerGLLineItem,


  @UI.lineItem: [{ position: 20 }]
  @EndUserText.label: 'Document Type'
  DocumentType,


  @UI.lineItem: [{ position: 30 }]
  @EndUserText.label: 'Posting Date'
  PostingDate,


  @UI.lineItem: [{ position: 40 }]
  @EndUserText.label: 'Net Due Date'
  NetDueDate,


  @Semantics.amount.currencyCode: 'LocalCurrency'
  @UI.lineItem: [{ position: 50 }]
  @EndUserText.label: 'Open Amount'
  OpenAmount,


  @EndUserText.label: 'Currency'
  LocalCurrency,


  @UI.lineItem: [{ position: 60 }]
  @EndUserText.label: 'Days Overdue'
  case
      when NetDueDate is initial
           or NetDueDate >= $session.system_date
      then 0
      else dats_days_between(
              NetDueDate,
              $session.system_date
           )
  end as DaysOverdue,


  _Header

}
