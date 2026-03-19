@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Aging Summary by Customer'
define root view entity ZI_DERS_AR03_CUST
  with parameters
    P_KeyDate  : abap.dats,
    P_BaseDate : abap.dats
  as select from ZI_DERS_AR03_V2( P_KeyDate: $parameters.P_KeyDate, 
                                   P_BaseDate: $parameters.P_BaseDate )
{
  key CompanyCode,
  key Customer,
  CustomerName,
  LocalCurrency,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( OriginalAmount ) as TotalAmount,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( Bucket_NotDue )   as Total_NotDue,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( Bucket_0_30 )     as Total_0_30,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( Bucket_31_60 )    as Total_31_60,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( Bucket_61_90 )    as Total_61_90,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  sum( Bucket_Over_90 )  as Total_Over_90
}
group by
  CompanyCode,
  Customer,
  CustomerName,
  LocalCurrency
