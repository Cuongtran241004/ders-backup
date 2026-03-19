@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project view for AP 03'
@Metadata.ignorePropagatedAnnotations: true

@Search.searchable: true

@UI.headerInfo: {
   typeName: 'Vendor Balance',
   typeNamePlural: 'Vendor Balances',
   title: { value: 'CompanyCode' },
   description: { value: 'Supplier' }
}

@UI.presentationVariant: [{
    sortOrder: [{
        by: 'Bucket_Over_90',
        direction: #DESC
    }],
    visualizations: [{
        type: #AS_CHART
    },{
        type: #AS_LINEITEM
    }]
}]

define root view entity ZC_DERS_AP03
  as select from ZI_DERS_AP03

association [0..*] to ZC_DERS_AP03_ITEM as _Items
    on  $projection.CompanyCode = _Items.CompanyCode
    and $projection.Supplier    = _Items.Supplier

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

    @Search.defaultSearchElement: true
    @UI.lineItem: [{ position: 10 }]
    @UI.selectionField: [{ position: 10 }]
    
    @Consumption.valueHelpDefinition: [{
        entity: {
            name: 'I_CompanyCode',
            element: 'CompanyCode'
        }
    }]
    
    @Consumption.filter: {
        mandatory: true,
        selectionType: #SINGLE,
        multipleSelections: false
    }
    
    @UI.identification: [{ position: 10 }]
    @EndUserText.label: 'Company Code'
    key CompanyCode,

    @Search.defaultSearchElement: true
    @UI.identification: [{ position: 20 }]
    @UI.lineItem: [{ position: 20 }]
    @UI.selectionField: [{ position: 20 }]
    
    @Consumption.valueHelpDefinition: [{
        entity: {
            name: 'I_Supplier',
            element: 'Supplier'
        }
    }]
    
    @EndUserText.label: 'Supplier'
    key Supplier,

    @UI.identification: [{ position: 30 }]
    @UI.lineItem: [{ position: 30 }]
    @EndUserText.label: 'Currency'
    key LocalCurrency,
    
    @UI.lineItem: [{ position: 25 }]
    @EndUserText.label: 'Supplier Name'
    SupplierName,
    
    @UI.identification: [{ position: 40 }]
    @UI.lineItem: [{ position: 40 }]
    @EndUserText.label: 'Total Payables'
    @Aggregation.default: #SUM
    sum( OriginalAmount ) as TotalAmount,

    @EndUserText.label: 'Not Due'
    @UI.lineItem: [{ position: 50 }]
    sum( Bucket_NotDue ) as Bucket_NotDue,

    @EndUserText.label: '0 - 30 Days'
    @UI.lineItem: [{ position: 60 }]
    sum( Bucket_0_30 ) as Bucket_0_30,

    @EndUserText.label: '31 - 60 Days'
    @UI.lineItem: [{ position: 70 }]
    sum( Bucket_31_60 ) as Bucket_31_60,

    @EndUserText.label: '61 - 90 Days'
    @UI.lineItem: [{ position: 80 }]
    sum( Bucket_61_90 ) as Bucket_61_90,

    @EndUserText.label: 'Over 90 Days'
    @UI.lineItem: [{ position: 90 }]
    sum( Bucket_Over_90 ) as Bucket_Over_90,

    _Items
}

group by
    CompanyCode,
    Supplier,
    SupplierName,
    LocalCurrency
