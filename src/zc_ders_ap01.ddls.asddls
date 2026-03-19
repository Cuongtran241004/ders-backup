@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AP Aging - Vendor Summary'
@Metadata.allowExtensions: true

@UI.headerInfo: {
   typeName: 'Vendor',
   typeNamePlural: 'Vendors',
   title: { value: 'Supplier' },
   description: { value: 'SupplierName' }
}

define root view entity ZC_DERS_AP01
  as select from ZI_DERS_AP01_HEADER
      ( p_key_date : $session.system_date )

  composition [0..*] of ZC_DERS_AP01_ITEM as _Items
{

  @UI.facet: [

    {
      id: 'Summary',
      type: #IDENTIFICATION_REFERENCE,
      label: 'Summary',
      position: 10
    },

    {
      id: 'InvoiceDetails',
      type: #LINEITEM_REFERENCE,
      label: 'Invoice Details',
      position: 20,
      targetElement: '_Items'
    }

  ]


  /* ================= FILTER ================= */
  key Ledger,


  key SourceLedger,


    @UI.selectionField: [{ position: 10 }]
    @UI.identification: [{ position: 30 }]
    @UI.lineItem: [{ position: 10 }]
    @EndUserText.label: 'Company Code'
    @Consumption.filter.mandatory: true
    @Consumption.valueHelpDefinition: [{
        entity: { name: 'I_CompanyCode', element: 'CompanyCode' }
    }]
    key CompanyCode,
    
    
    @UI.selectionField: [{ position: 20 }]
    @UI.identification: [{ position: 10 }]
    @UI.lineItem: [{ position: 20 }]
    @EndUserText.label: 'Vendor'
    @Consumption.valueHelpDefinition: [{
        entity: { name: 'I_Supplier', element: 'Supplier' }
    }]
    key Supplier,
    
    
    @UI.identification: [{ position: 20 }]
    @UI.lineItem: [{ position: 30 }]
    @EndUserText.label: 'Vendor Name'
    SupplierName,

  @Semantics.amount.currencyCode: 'LocalCurrency'
  @UI.identification: [{ position: 40 }]
  @UI.lineItem: [{ position: 40 }]
  @EndUserText.label: 'Total Open Amount'
  TotalOpenAmount,


  @UI.identification: [{ position: 50 }]
  @EndUserText.label: 'Currency'
  LocalCurrency,


  @UI.identification: [{ position: 60 }]
  @UI.lineItem: [{ position: 50 }]
  @EndUserText.label: 'Max Days Overdue'
  MaxDaysOverdue,


  /* ================= ASSOCIATION ================= */

  _Items

}
