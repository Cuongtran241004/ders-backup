@EndUserText.label: 'AR Aging Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_DERS_AR03_V2
  provider contract transactional_query
  as projection on ZI_DERS_AR03_CUST( P_KeyDate: $session.system_date, 
                                      P_BaseDate: $session.system_date )
{
    key CompanyCode,
    key Customer,
    CustomerName,
    LocalCurrency,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    TotalAmount,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    Total_NotDue,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    Total_0_30,
    
    @Semantics.amount.currencyCode: 'LocalCurrency'
    Total_31_60,
    
    @Semantics.amount.currencyCode: 'LocalCurrency'
    Total_61_90,

    @Semantics.amount.currencyCode: 'LocalCurrency'
    Total_Over_90
}
