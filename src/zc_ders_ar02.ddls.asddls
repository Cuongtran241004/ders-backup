@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project view for AR 02'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true

@UI.headerInfo: {
   typeName: 'Customer Balance',
   typeNamePlural: 'Customer Balances',
   title: { value: 'Customer' },
   description: { value: 'CustomerName' }
}

@UI.presentationVariant: [{
    sortOrder: [{
        by: 'ClosingBalance',
        direction: #DESC
    }],
    visualizations: [{
        type: #AS_LINEITEM
    }]
}]

define root view entity ZC_DERS_AR02
  as select from ZI_DERS_AR02

association [0..*] to ZC_DERS_AR02_ITEM as _Items
    on  $projection.CompanyCode = _Items.CompanyCode
    and $projection.Customer    = _Items.Customer
    and $projection.FiscalYear  = _Items.FiscalYear
    and $projection.PostingDate = _Items.PostingDate

{

@UI.facet: [
  {
    id: 'General',
    type: #IDENTIFICATION_REFERENCE,
    label: 'General Information',
    position: 10
  },
  {
    id: 'Items',
    type: #LINEITEM_REFERENCE,
    label: 'Journal Entry Items',
    position: 20,
    targetElement: '_Items'
  }
]

/* ================= COMPANY CODE ================= */

@UI.lineItem: [{ position: 10 }]
@UI.selectionField: [{ position: 10 }]
@Consumption.filter: {
    mandatory: true,
    selectionType: #SINGLE
}
@Consumption.valueHelpDefinition: [{
    entity: {
        name: 'I_CompanyCode',
        element: 'CompanyCode'
    }
}]
@UI.identification: [{ position: 10 }]
key CompanyCode,

/* ================= CUSTOMER ================= */

@UI.lineItem: [{ position: 20 }]
@UI.selectionField: [{ position: 20 }]
@Consumption.filter: {
    selectionType: #SINGLE
}
@Consumption.valueHelpDefinition: [{
    entity: {
        name: 'I_Customer',
        element: 'Customer'
    }
}]
@UI.identification: [{ position: 20 }]
key Customer,

/* ================= FISCAL YEAR ================= */

@UI.lineItem: [{ position: 25 }]
@UI.selectionField: [{ position: 30 }]
@Consumption.filter: { selectionType: #SINGLE }

@Consumption.valueHelpDefinition: [{
    entity: {
        name: 'I_FiscalYear',
        element: 'FiscalYear'
    }
}]

@EndUserText.label: 'Fiscal Year'
key FiscalYear,

/* ================= POSTING DATE ================= */

@UI.lineItem: [{ position: 26 }]
@UI.selectionField: [{ position: 40 }]
@Consumption.filter: { selectionType: #INTERVAL }
@EndUserText.label: 'Posting Date'
key PostingDate,

/* ================= CUSTOMER INFO ================= */

@UI.lineItem: [{ position: 30 }]
CustomerName,

@UI.lineItem: [{ position: 40 }]
Address,

/* ================= CURRENCY ================= */

@UI.lineItem: [{ position: 50 }]
@UI.identification: [{ position: 30 }]
@EndUserText.label: 'Local Currency'
LocalCurrency,

/* ================= OPENING ================= */

@UI.lineItem: [{ position: 60 }]
@EndUserText.label: 'Opening Balance'
sum( OpeningBalance ) as OpeningBalance,

/* ================= DEBIT ================= */

@UI.lineItem: [{ position: 70 }]
@EndUserText.label: 'Debit'
sum( Debit ) as Debit,

/* ================= CREDIT ================= */

@UI.lineItem: [{ position: 80 }]
@EndUserText.label: 'Credit'
sum( Credit ) as Credit,

/* ================= PERIOD ================= */

@UI.lineItem: [{ position: 90 }]
@EndUserText.label: 'Period Activity'
sum( PeriodActivity ) as PeriodActivity,

/* ================= CLOSING ================= */

@UI.lineItem: [{ position: 100 }]
@UI.identification: [{ position: 40 }]
@EndUserText.label: 'Closing Balance'
sum( ClosingBalance ) as ClosingBalance,

_Items
}

group by
    CompanyCode,
    Customer,
    FiscalYear,
    PostingDate,
    CustomerName,
    Address,
    LocalCurrency
