@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project view for AP 03'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_DERS_AP03
  as select from I_JournalEntryItem

  association [0..1] to I_Supplier as _Supplier
      on $projection.Supplier = _Supplier.Supplier

{

    /* ===================== KEY ===================== */

    @EndUserText.label: 'Company Code'
    key CompanyCode,

    @EndUserText.label: 'Fiscal Year'
    key FiscalYear,

    @EndUserText.label: 'Accounting Document'
    key AccountingDocument,

    @EndUserText.label: 'Accounting Document Item'
    key AccountingDocumentItem,

    @EndUserText.label: 'Ledger'
    key Ledger,

    /* ===================== DIMENSION ===================== */

    @EndUserText.label: 'Supplier'
    Supplier,

    @EndUserText.label: 'Supplier Name'
    _Supplier.SupplierName,

    @EndUserText.label: 'Posting Date'
    PostingDate,

    @EndUserText.label: 'Document Date'
    DocumentDate,

    @EndUserText.label: 'Net Due Date'
    NetDueDate,

    @EndUserText.label: 'Accounting Document Type'
    AccountingDocumentType,

    @EndUserText.label: 'Currency'
    CompanyCodeCurrency as LocalCurrency,

    /* ===================== ORIGINAL AMOUNT ===================== */

    @EndUserText.label: 'Original Amount'
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        as OriginalAmount,

    /* ===================== AGING DAYS ===================== */

    @EndUserText.label: 'Aging Days'
    cast(
        dats_days_between( NetDueDate, $session.system_date )
        as abap.int4
    ) as AgingDays,

    /* ===================== NOT DUE ===================== */

    @EndUserText.label: 'Not Due'
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) < 0
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_NotDue,
    
    /* ===================== BUCKET 0–30 ===================== */

    @EndUserText.label: '0 - 30 Days'
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) between 0 and 30
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_0_30,

    /* ===================== BUCKET 31–60 ===================== */

    @EndUserText.label: '31 - 60 Days'
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) between 31 and 60
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_31_60,

    /* ===================== BUCKET 61–90 ===================== */

    @EndUserText.label: '61 - 90 Days'
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) between 61 and 90
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_61_90,

    /* ===================== BUCKET > 90 ===================== */

    @EndUserText.label: 'Over 90 Days'
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $session.system_date ) > 90
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_Over_90

}

where
      Ledger = '0L'
  and Supplier is not null
  and FinancialAccountType = 'K'
  and ClearingAccountingDocument is initial
