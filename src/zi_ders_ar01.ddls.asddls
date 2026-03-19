@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Base View'

define view entity ZI_DERS_AR01
  as select from I_JournalEntryItem as Item

  association [0..1] to I_Customer as _Customer
    on $projection.Customer = _Customer.Customer

  association [0..1] to I_JournalEntry as _JournalEntry
    on  Item.CompanyCode        = _JournalEntry.CompanyCode
    and Item.AccountingDocument = _JournalEntry.AccountingDocument
    and Item.FiscalYear         = _JournalEntry.FiscalYear

{
  key Item.Ledger,
  key Item.SourceLedger,
  key Item.CompanyCode,
  key Item.Customer,
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.LedgerGLLineItem,

  Item.PostingDate,
  Item.NetDueDate,
  Item.ClearingDate,

  /* Document Type từ Journal Entry Header */
  _JournalEntry.AccountingDocumentType as DocumentType,

  _Customer.CustomerName,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  case 
      when Item.DebitCreditCode = 'H'
      then - Item.AmountInCompanyCodeCurrency
      else Item.AmountInCompanyCodeCurrency
  end as OpenAmount,

  Item.CompanyCodeCurrency as LocalCurrency,
  Item.FinancialAccountType

}
where Item.FinancialAccountType = 'D'
  and Item.ClearingDate is initial
