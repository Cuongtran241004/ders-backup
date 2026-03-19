@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View for AR Aging - Fixed'
@Metadata.allowExtensions: true
define root view entity ZI_DERS_AR03_V2
  with parameters
    P_KeyDate  : abap.dats,
    P_BaseDate : abap.dats
  as select from I_JournalEntryItem
  association [0..1] to I_Customer as _Customer on $projection.Customer = _Customer.Customer
{
  key CompanyCode,
  key FiscalYear,
  key AccountingDocument,
  key AccountingDocumentItem,
  key Ledger,
  Customer,
  _Customer.CustomerName,
  
  /* 1. Phải có trường Currency Key để làm tham chiếu */
  CompanyCodeCurrency as LocalCurrency,

  /* 2. CAST trường Original Amount sang DEC(23,2) */
  @Semantics.amount.currencyCode: 'LocalCurrency'
  cast( AmountInCompanyCodeCurrency as abap.dec(23,2) ) as OriginalAmount,

  /* Tính tuổi nợ */
  dats_days_between(NetDueDate, $parameters.P_BaseDate) as AgingDays,

  
  -- Bucket: Not Due
  @Semantics.amount.currencyCode: 'LocalCurrency'
  cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $parameters.P_BaseDate ) < 0
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_NotDue,

  -- Bucket: 0 - 30 Days
  @Semantics.amount.currencyCode: 'LocalCurrency'
  cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $parameters.P_BaseDate ) between 0 and 30
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_0_30,

  -- Bucket: 31 - 60 Days
  @Semantics.amount.currencyCode: 'LocalCurrency'
  cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $parameters.P_BaseDate ) between 31 and 60
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_31_60,

  -- Bucket: 61 - 90 Days
  @Semantics.amount.currencyCode: 'LocalCurrency'
  cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $parameters.P_BaseDate ) between 61 and 90
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_61_90,

  -- Bucket: Over 90 Days
  @Semantics.amount.currencyCode: 'LocalCurrency'
  cast(
        case
            when NetDueDate is not null
             and dats_days_between( NetDueDate, $parameters.P_BaseDate ) > 90
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as Bucket_Over_90,

  _Customer
}
where Ledger = '0L' 
  and FinancialAccountType = 'D'
  and ClearingAccountingDocument is initial
  and PostingDate <= $parameters.P_KeyDate
