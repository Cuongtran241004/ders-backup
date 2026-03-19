//@AccessControl.authorizationCheck: #NOT_REQUIRED
//@EndUserText.label: 'GL Balance Base View'
//
//define view entity ZI_DERS_GL01
//  as select from ZI_GL_PERIOD as P
//  left outer join I_JournalEntryItem as J
//    on  J.FiscalPeriod = P.Period
//    and J.Ledger       = '0L'
//
//{
//
///* ================= KEY ================= */
//
//key P.Period,
//
//
///* ================= DIMENSIONS ================= */
//
//J.CompanyCode,
//J.GLAccount,
//J.FiscalYear,
//
//
///* ================= CURRENCY ================= */
//
//J.CompanyCodeCurrency as LocalCurrency,
//
//
///* ================= DEBIT ================= */
//
//@Semantics.amount.currencyCode: 'LocalCurrency'
//sum(
//    case
//        when J.DebitCreditCode = 'S'
//        then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
//        else 0
//    end
//) as DebitAmount,
//
//
///* ================= CREDIT ================= */
//
//@Semantics.amount.currencyCode: 'LocalCurrency'
//sum(
//    case
//        when J.DebitCreditCode = 'H'
//        then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
//        else 0
//    end
//) as CreditAmount,
//
//
///* ================= BALANCE ================= */
//
//@Semantics.amount.currencyCode: 'LocalCurrency'
//sum(
//    case
//        when J.DebitCreditCode = 'S'
//        then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
//
//        when J.DebitCreditCode = 'H'
//        then -cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
//
//        else 0
//    end
//) as BalanceAmount
//
//}
//
//group by
//P.Period,
//J.CompanyCode,
//J.GLAccount,
//J.FiscalYear,
//J.CompanyCodeCurrency


@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GL01 Base View'
@Analytics.dataCategory: #CUBE

define root view entity ZI_DERS_GL01
  as select from    ZI_GL_PERIOD       as P
    inner join I_JournalEntryItem as J on  J.FiscalPeriod = P.Period
                                            and J.FiscalYear   = P.FiscalYear
                                            and J.Ledger       = '0L'
   inner join I_GLAccountText    as T on  T.GLAccount    = J.GLAccount
                                            and T.Language     = $session.system_language
    association [0..*] to I_JournalEntryItem as _Items on  _Items.GLAccount    = $projection.GLAccount
                                                    and _Items.CompanyCode  = $projection.CompanyCode
                                                    and _Items.FiscalYear   = $projection.FiscalYear
                                                    and _Items.FiscalPeriod = $projection.Period
                                                    and _Items.Ledger       = '0L'
{
    key J.FiscalYear,
    key J.FiscalPeriod as Period,
    key J.CompanyCode, 
    key J.GLAccount,
    
    T.GLAccountName,
    J.ProfitCenter,
    J.CostCenter,

    // Just project the currency field
    J.CompanyCodeCurrency as LocalCurrency,

    /* Using casting to dec for calculation */
    
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    sum( case when J.DebitCreditCode = 'S' 
              then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) ) 
              else 0 end ) as DebitAmount,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    sum( case when J.DebitCreditCode = 'H' 
              then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) ) 
              else 0 end ) as CreditAmount,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    @Aggregation.default: #SUM
    sum( case when J.DebitCreditCode = 'S' then cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
              when J.DebitCreditCode = 'H' then -cast( J.AmountInCompanyCodeCurrency as abap.dec(23,2) )
              else 0 end ) as BalanceAmount,
    _Items          
}
group by
    J.FiscalYear, J.FiscalPeriod, J.CompanyCode, J.GLAccount,
    T.GLAccountName, J.ProfitCenter, J.CostCenter, J.CompanyCodeCurrency


