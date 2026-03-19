//@AccessControl.authorizationCheck: #NOT_REQUIRED
//@EndUserText.label: 'GL01 Overview'
//@Metadata.ignorePropagatedAnnotations: true
//
//@UI.presentationVariant: [{
//    sortOrder: [{
//        by: 'Period',
//        direction: #ASC
//    }]
//}]
//
//define root view entity ZC_DERS_GL01
//  as projection on ZI_DERS_GL01
//{
//
///* ================= FILTER ================= */
//
//@UI.selectionField: [{ position: 10 }]
//@Consumption.filter: { mandatory: true, selectionType: #SINGLE }
//key CompanyCode,
//
//
//@UI.selectionField: [{ position: 20 }]
//@Consumption.filter: { mandatory: true, selectionType: #SINGLE }
//key FiscalYear,
//
//
//@UI.selectionField: [{ position: 30 }]
//key GLAccount,
//
//
///* ================= PERIOD ================= */
//
//@UI.lineItem: [{ position: 10 }]
//@UI.selectionField: [{ position: 40 }]
//@Consumption.filter: { selectionType: #INTERVAL }
//key Period,
//
//
///* ================= DEBIT ================= */
//
//@UI.lineItem: [{ position: 20 }]
//@EndUserText.label: 'Debit Amount in Company Code Currency'
//@Semantics.amount.currencyCode: 'LocalCurrency'
//@Aggregation.default: #SUM
//DebitAmount,
//
//
///* ================= CREDIT ================= */
//
//@UI.lineItem: [{ position: 30 }]
//@EndUserText.label: 'Credit Amount in Company Code Currency'
//@Semantics.amount.currencyCode: 'LocalCurrency'
//@Aggregation.default: #SUM
//CreditAmount,
//
//
///* ================= BALANCE ================= */
//
//@UI.lineItem: [{ position: 40 }]
//@EndUserText.label: 'Balance Amount in Company Code Currency'
//@Semantics.amount.currencyCode: 'LocalCurrency'
//@Aggregation.default: #SUM
//BalanceAmount,
//
//
///* ================= ENDING BALANCE ================= */
//
//@UI.lineItem: [{ position: 50 }]
//@EndUserText.label: 'Ending Balance Amount in Company Code Currency'
//@Semantics.amount.currencyCode: 'LocalCurrency'
//@Aggregation.default: #SUM
//BalanceAmount as EndingBalance,
//
//
///* ================= CURRENCY ================= */
//
//LocalCurrency
//
//}


@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GL01 Projection View - Full Account Balances'
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.headerInfo: { 
        typeName: 'Account Balance', 
        typeNamePlural: 'Account Balances', 
        title: { type: #STANDARD, value: 'GLAccount' },
        description: { type: #STANDARD, value: 'GLAccountName' } 
    }

    
    
define root view entity ZC_DERS_GL01
  provider contract transactional_query
  as projection on ZI_DERS_GL01
{
    /* ================= HEADER & FACETS ================= */
    
    @UI.facet: [ 
        { id: 'HeaderData',
          purpose: #HEADER,             
          type: #FIELDGROUP_REFERENCE,
          label: 'Context Info',
          targetQualifier: 'HeaderGroup',
          position: 10 },
          
        { id: 'idIdentification', 
          type: #IDENTIFICATION_REFERENCE, 
          label: 'Account Details', 
          position: 10 },
          
        { id: 'ItemsList',
          purpose: #STANDARD,
          type: #LINEITEM_REFERENCE,
          label: 'Journal Entry Details (Items)',
          position: 20,
          targetElement: '_Items' } // Trỏ tới association chi tiết
    ]

    /* ================= KEY FIELDS ================= */

    @UI.lineItem:       [{ position: 10 }]
    @UI.selectionField: [{ position: 10 }]
    @UI.identification: [{ position: 10 }]
    @UI.fieldGroup:     [{ qualifier: 'HeaderGroup', position: 10, label: 'Year' }]
     key FiscalYear,

    @UI.lineItem:       [{ position: 20 }]
    @UI.selectionField: [{ position: 20 }]
    @UI.identification: [{ position: 20 }]
    @UI.fieldGroup:     [{ qualifier: 'HeaderGroup', position: 20, label: 'Period' }]
    key Period,

    @UI.lineItem:       [{ position: 30 }]
    @UI.selectionField: [{ position: 30 }]
    @UI.identification: [{ position: 30 }]
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
    @UI.fieldGroup:     [{ qualifier: 'HeaderGroup', position: 30, label: 'Co. Code' }]
    key CompanyCode,

    @UI.lineItem:       [{ position: 40 }]
    @UI.selectionField: [{ position: 40 }]
    @UI.identification: [{ position: 40 }]
    @Search.defaultSearchElement: true
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_GLAccount', element: 'GLAccount' } }]
    key GLAccount,

    /* ================= DIMENSIONS ================= */

    @UI.lineItem:       [{ position: 50 }]
    @UI.identification: [{ position: 50 }]
    @Search.defaultSearchElement: true
    GLAccountName,

    @UI.lineItem:       [{ position: 60 }]
    @UI.identification: [{ position: 60 }]
    ProfitCenter,

    @UI.lineItem:       [{ position: 70 }]
    @UI.identification: [{ position: 70 }]
    CostCenter,


    /* ================= MEASURES ================= */

    @UI.lineItem:       [{ position: 80 }]
    @UI.identification: [{ position: 80 }]
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @EndUserText.label: 'Debit'
    DebitAmount,

    @UI.lineItem:       [{ position: 90 }]
    @UI.identification: [{ position: 90 }]
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @EndUserText.label: 'Credit'
    CreditAmount,

    @UI.lineItem:       [{ position: 100 }]
    @UI.identification: [{ position: 100 }]
    @Semantics.amount.currencyCode: 'LocalCurrency'
    @EndUserText.label: 'Balance Amount'
    BalanceAmount,

    @UI.hidden: true
    LocalCurrency,

    /* ================= EXPOSED ASSOCIATIONS ================= */
    // QUAN TRỌNG: Phải expose association để UI có thể truy cập data item
    _Items : redirected to ZC_DERS_GL01_ITEM
}
