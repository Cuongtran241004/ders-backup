@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GL01 Line Item Details'
@Metadata.allowExtensions: true

define view entity ZC_DERS_GL01_ITEM
  as projection on I_JournalEntryItem
{
    @UI.lineItem: [{ position: 10, label: 'Co. Code' }]
    key CompanyCode,
    
    @UI.lineItem: [{ position: 20, label: 'Year' }]
    key FiscalYear,
    
    @UI.lineItem: [{ position: 30, label: 'Doc. Number' }]
    key AccountingDocument,
    
    @UI.lineItem: [{ position: 40, label: 'Line Item' }]
    key LedgerGLLineItem,

    @UI.lineItem: [{ position: 50, label: 'G/L Account' }]
    GLAccount,
    
    @EndUserText.label: 'Account Type'
    @UI.lineItem: [{ position: 55 }]
    GLAccountType as GLAccountCategory, 
    
    @UI.lineItem: [{ position: 60, label: 'Posting Date' }]
    PostingDate,

    @UI.lineItem: [{ position: 70, label: 'Amount' }]
    @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
    AmountInCompanyCodeCurrency,

    @UI.hidden: true
    CompanyCodeCurrency,
    
    @UI.lineItem: [{ position: 80, label: 'Text' }]
    DocumentItemText,
    
    /* Technical Fields for Filtering */
    @UI.hidden: true
    FiscalPeriod,
    
    @UI.hidden: true
    Ledger
}
