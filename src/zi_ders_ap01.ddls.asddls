@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AP Aging - Base View'

define view entity ZI_DERS_AP01
  as select from I_JournalEntryItem as Item

  association [0..1] to I_Supplier as _Supplier
    on $projection.Supplier = _Supplier.Supplier

  association [0..1] to I_JournalEntry as _JournalEntry
    on  Item.CompanyCode        = _JournalEntry.CompanyCode
    and Item.AccountingDocument = _JournalEntry.AccountingDocument
    and Item.FiscalYear         = _JournalEntry.FiscalYear

{
  key Item.Ledger,
  key Item.SourceLedger,
  key Item.CompanyCode,
  key Item.Supplier,
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.LedgerGLLineItem,

  Item.PostingDate,
  Item.NetDueDate,
  Item.ClearingDate,

  _JournalEntry.AccountingDocumentType as DocumentType,

  _Supplier.SupplierName,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  case 
      when Item.DebitCreditCode = 'H'
      then - Item.AmountInCompanyCodeCurrency
      else Item.AmountInCompanyCodeCurrency
  end as OpenAmount,

  Item.CompanyCodeCurrency as LocalCurrency,
  Item.FinancialAccountType

}
where Item.FinancialAccountType = 'K'
  and Item.ClearingDate is initial
