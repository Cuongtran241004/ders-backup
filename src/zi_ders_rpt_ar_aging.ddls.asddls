/****************************************************************
 *  CDS View: ZI_DERS_RPT_AR_AGING
 *  Purpose:  Report Data - AR Customer Aging Analysis
 *            Exposed via OData for Fiori List Report
 *  
 *  Data Sources:
 *    - ACDOCA: Universal Journal (S/4HANA)
 *    - I_Customer: Customer Master (Released CDS View)
 *    - T001: Company Code Master
 *  
 *  Filter: Customer line items (KOESSION = 'D') with open balance
 *  
 *  Usage in Fiori:
 *    Filter Bar: Bukrs = 1000
 *    → GET /ARAgingReport?$filter=Bukrs eq '1000'
 ****************************************************************/
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Report: AR Customer Aging'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #L,
  dataClass: #MIXED
}

define view entity ZI_DERS_RPT_AR_AGING
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    P_KeyDate : abap.dats
  as select from acdoca as OpenItem
    inner join   I_Customer as Customer on Customer.Customer = OpenItem.kunnr
    inner join   t001 as CompanyCode on CompanyCode.bukrs = OpenItem.rbukrs
{
      //------------------------------------------------------------------
      // KEY FIELDS
      //------------------------------------------------------------------
      key OpenItem.rbukrs                                 as Bukrs,
      key OpenItem.kunnr                                  as CustomerNumber,
      key OpenItem.belnr                                  as InvoiceNumber,
      key OpenItem.gjahr                                  as FiscalYear,
      key OpenItem.docln                                  as LineItem,

      //------------------------------------------------------------------
      // CUSTOMER INFO (from I_Customer)
      //------------------------------------------------------------------
      Customer.CustomerName                               as CustomerName,
      Customer.CityName                                   as City,
      Customer.Country                                    as Country,
      Customer.TelephoneNumber1                           as Phone,
      
      //------------------------------------------------------------------
      // INVOICE INFO
      //------------------------------------------------------------------
      OpenItem.blart                                      as DocumentType,
      OpenItem.bldat                                      as DocumentDate,
      OpenItem.budat                                      as PostingDate,
      
      //------------------------------------------------------------------
      // DUE DATE = Posting Date + 30 days (simplified)
      //------------------------------------------------------------------
      @Semantics.businessDate.at: true
      dats_add_days( OpenItem.budat, 30, 'INITIAL' )      as DueDate,
      
      //------------------------------------------------------------------
      // KEY DATE (from input parameter - allows historical reporting)
      //------------------------------------------------------------------
      @EndUserText.label: 'Key Date'
      $parameters.P_KeyDate                               as KeyDate,
      
      //------------------------------------------------------------------
      // AGING CALCULATION (Days overdue as of Key Date)
      //------------------------------------------------------------------
      cast(
        dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) as abap.int4
      )                                                   as DaysOverdue,
      
      //------------------------------------------------------------------
      // AGING BUCKET (relative to Key Date)
      //------------------------------------------------------------------
      case
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) <= 30 
             then 'CURRENT'
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) <= 60 
             then '1-30'
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) <= 90 
             then '31-60'
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) <= 120 
             then '61-90'
        else '91+'
      end                                                 as AgingBucket,
      
      //------------------------------------------------------------------
      // AMOUNT FIELDS
      //------------------------------------------------------------------
      @Semantics.amount.currencyCode: 'LocalCurrency'
      OpenItem.hsl                                        as AmountInLocalCurrency,
      
      @Semantics.amount.currencyCode: 'DocumentCurrency'
      OpenItem.wsl                                        as AmountInDocCurrency,
      
      OpenItem.rwcur                                      as DocumentCurrency,
      
      CompanyCode.waers                                   as LocalCurrency,
      
      //------------------------------------------------------------------
      // CRITICALITY (for UI coloring)
      //------------------------------------------------------------------
      case
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) > 120 
             then 1   // Red - Critical
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) > 90 
             then 2   // Orange - Warning
        when dats_days_between( OpenItem.budat, $parameters.P_KeyDate ) > 60 
             then 3   // Yellow - Attention
        else 5        // Green - OK
      end                                                 as Criticality,
      
      //------------------------------------------------------------------
      // ADDITIONAL REFERENCES
      //------------------------------------------------------------------
      OpenItem.awref                                      as Reference,
      OpenItem.bstat                                      as ItemText,
      OpenItem.drcrk                                      as DebitCreditIndicator
}
where OpenItem.kunnr <> ''
