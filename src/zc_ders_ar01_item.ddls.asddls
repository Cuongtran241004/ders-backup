@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Item Details'
@Metadata.allowExtensions: true

define view entity ZC_DERS_AR01_ITEM
  as select from ZI_DERS_AR01

  association to parent ZC_DERS_AR01 as _Header
    on  $projection.Ledger       = _Header.Ledger
    and $projection.SourceLedger = _Header.SourceLedger
    and $projection.CompanyCode  = _Header.CompanyCode
    and $projection.Customer     = _Header.Customer
{
  key Ledger,
  key SourceLedger,
  key CompanyCode,
  key Customer,

  @UI.lineItem: [{ position: 10 }]
  key AccountingDocument,

  key FiscalYear,
  key LedgerGLLineItem,

  @UI.lineItem: [{ position: 20 }]
  DocumentType,

  @UI.lineItem: [{ position: 30 }]
  PostingDate,

  @UI.lineItem: [{ position: 40 }]
  NetDueDate,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  @UI.lineItem: [{ position: 50 }]
  OpenAmount,

  LocalCurrency,

  @UI.lineItem: [{ position: 60 }]
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
