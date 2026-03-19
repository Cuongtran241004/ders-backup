@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Balance Report'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true

@UI.headerInfo: {
   typeName: 'Vendor Balance',
   typeNamePlural: 'Vendor Balances',
   title: { value: 'Supplier' },
   description: { value: 'SupplierName' }
}

define root view entity ZC_DERS_AP02
  as select from ZI_DERS_AP02

association [0..*] to ZC_DERS_AP02_ITEM as _Items
    on  $projection.CompanyCode = _Items.CompanyCode
    and $projection.Supplier    = _Items.Supplier
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

@EndUserText.label: 'Company Code'
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
key CompanyCode,

/* ================= SUPPLIER ================= */

@EndUserText.label: 'Supplier'
@UI.lineItem: [{ position: 20 }]
@UI.selectionField: [{ position: 20 }]
@Consumption.filter: { selectionType: #SINGLE }
@Consumption.valueHelpDefinition: [{
    entity: {
        name: 'I_Supplier',
        element: 'Supplier'
    }
}]
key Supplier,

/* ================= FISCAL YEAR ================= */

@EndUserText.label: 'Fiscal Year'
@UI.lineItem: [{ position: 25 }]
@UI.selectionField: [{ position: 30 }]
@Consumption.filter: { selectionType: #SINGLE }
@Consumption.valueHelpDefinition: [{
    entity: {
        name: 'I_FiscalYear',
        element: 'FiscalYear'
    }
}]
key FiscalYear,

/* ================= POSTING DATE ================= */

@EndUserText.label: 'Posting Date'
@UI.lineItem: [{ position: 26 }]
@UI.selectionField: [{ position: 40 }]
@Consumption.filter: { selectionType: #INTERVAL }
key PostingDate,

/* ================= SUPPLIER INFO ================= */

@EndUserText.label: 'Supplier Name'
@UI.lineItem: [{ position: 30 }]
SupplierName,

@EndUserText.label: 'Address'
@UI.lineItem: [{ position: 40 }]
Address,

/* ================= CURRENCY ================= */

@EndUserText.label: 'Local Currency'
@UI.lineItem: [{ position: 50 }]
LocalCurrency,

/* ================= OPENING ================= */

@EndUserText.label: 'Opening Balance'
@UI.lineItem: [{ position: 60 }]
sum( OpeningBalance ) as OpeningBalance,

/* ================= DEBIT ================= */

@EndUserText.label: 'Debit Amount'
@UI.lineItem: [{ position: 70 }]
sum( Debit ) as Debit,

/* ================= CREDIT ================= */

@EndUserText.label: 'Credit Amount'
@UI.lineItem: [{ position: 80 }]
sum( Credit ) as Credit,

/* ================= PERIOD ================= */

@EndUserText.label: 'Period Activity'
@UI.lineItem: [{ position: 90 }]
sum( PeriodActivity ) as PeriodActivity,

/* ================= CLOSING ================= */

@EndUserText.label: 'Closing Balance'
@UI.lineItem: [{ position: 100 }]
sum( ClosingBalance ) as ClosingBalance,

_Items
}

group by
    CompanyCode,
    Supplier,
    FiscalYear,
    PostingDate,
    SupplierName,
    Address,
    LocalCurrency
