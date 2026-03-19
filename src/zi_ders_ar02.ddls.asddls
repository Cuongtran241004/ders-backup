@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project view for AR 02'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_DERS_AR02
  as select from I_JournalEntryItem

  association [0..1] to I_Customer as _Customer
      on $projection.Customer = _Customer.Customer

{

    /* ===================== KEY ===================== */

    key CompanyCode,
    key FiscalYear,

    @UI.lineItem: [{
        position: 5,
        type: #FOR_INTENT_BASED_NAVIGATION,
        semanticObject: 'JournalEntry',
        semanticObjectAction: 'display'
    }]
    key AccountingDocument,
    key AccountingDocumentItem,
    key Ledger,

    /* ===================== CUSTOMER ===================== */

    @UI.lineItem: [{ position: 10 }]
    Customer,

    @UI.lineItem: [{ position: 20 }]
    _Customer.CustomerName,

    @UI.lineItem: [{ position: 30 }]
    _Customer.CityName as Address,

    @UI.lineItem: [{ position: 40 }]
    Customer as CustomerAccount,

    /* ===================== DATE ===================== */

    @UI.lineItem: [{ position: 50 }]
    PostingDate,

    CompanyCodeCurrency as LocalCurrency,

    /* ===================== AMOUNT ===================== */


    @Aggregation.default: #SUM
    cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        as Amount,

    /* ===================== OPENING BALANCE ===================== */

    
    @Aggregation.default: #SUM
    cast(
        case
            when PostingDate < $session.system_date
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as OpeningBalance,
    /* ===================== DEBIT ===================== */


@Aggregation.default: #SUM
cast(
    case
        when DebitCreditCode = 'S'
        then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        else cast( 0 as abap.dec(23,2) )
    end
    as abap.dec(23,2)
) as Debit,

/* ===================== CREDIT ===================== */


@Aggregation.default: #SUM
cast(
    case
        when DebitCreditCode = 'H'
        then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        else cast( 0 as abap.dec(23,2) )
    end
    as abap.dec(23,2)
) as Credit,
/* ===================== CLOSING ===================== */

@Aggregation.default: #SUM
cast(
    case
        when DebitCreditCode = 'S'
        then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        when DebitCreditCode = 'H'
        then - cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
        else cast( 0 as abap.dec(23,2) )
    end
    as abap.dec(23,2)
) as ClosingBalance,

    /* ===================== PERIOD ACTIVITY ===================== */


    @Aggregation.default: #SUM
    cast(
        case
            when PostingDate = $session.system_date
            then cast( AmountInCompanyCodeCurrency as abap.dec(23,2) )
            else cast( 0 as abap.dec(23,2) )
        end
        as abap.dec(23,2)
    ) as PeriodActivity

}
where
      Ledger = '0L'
  and FinancialAccountType = 'D'
  
  
