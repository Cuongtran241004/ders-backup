@EndUserText.label: 'Vendor Open Items - Consumption'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_VendorOpenItem
  provider contract transactional_query
  as projection on ZI_VendorOpenItem
{
  @UI.facet: [ { id: 'idIdentification', type: #IDENTIFICATION_REFERENCE, label: 'General Information', position: 10 } ]

  @UI.lineItem: [
    { position: 10 },
    { type: #FOR_ACTION, dataAction: 'ExportExcel', label: 'Export to Excel' }
  ]
  @UI.selectionField: [{ position: 10 }]
  @Consumption.filter: { selectionType: #SINGLE, multipleSelections: false, mandatory: true }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
  key CompanyCode,

  @UI.lineItem: [{ position: 20 }]
  @Search.defaultSearchElement: true
  key AccountingDocument,

  @UI.selectionField: [{ position: 20 }]
  @Consumption.filter: { selectionType: #SINGLE, multipleSelections: false, mandatory: true }
  key FiscalYear,

  key AccountingDocumentItem,

  /*====================*/
  /*      Supplier      */
  /*====================*/
  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  @UI.selectionField: [{ position: 30 }]
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
  @ObjectModel.text.element: ['SupplierName']
  Supplier,

  @UI.lineItem: [{ position: 35 }]
  SupplierName,

  @UI.lineItem: [{ position: 40 }]
  @UI.selectionField: [{ position: 40 }]
  @EndUserText.label: 'Vendor Group'
  VendorGroup,

  @UI.lineItem: [{ position: 50 }]
  @UI.selectionField: [{ position: 50 }]
  Country,

  /*====================*/
  /*        Dates       */
  /*====================*/
  @UI.lineItem: [{ position: 60 }]
  PostingDate,

  @UI.lineItem: [{ position: 70 }]
  DocumentDate,

  @UI.lineItem: [{ position: 80, label: 'Due Date' }]
  NetDueDate,

  @UI.lineItem: [{ position: 90, label: 'Overdue Days', criticality: 'OverdueDays' }]
  OverdueDays,

  /*====================*/
  /*       Amount       */
  /*====================*/
  @UI.lineItem: [{ position: 100, importance: #HIGH }]
  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  AmountInCompanyCodeCurrency,

  @Consumption.filter: { selectionType: #SINGLE, defaultValue: 'VND' }
  CompanyCodeCurrency,

  /*====================*/
  /*  Account & Terms   */
  /*====================*/
  @UI.lineItem: [{ position: 110 }]
  @UI.selectionField: [{ position: 60 }]
  @EndUserText.label: 'Reconciliation Account'
  ReconciliationAccount,

  @UI.lineItem: [{ position: 120 }]
  @UI.selectionField: [{ position: 70 }]
  @EndUserText.label: 'Payment Terms'
  PaymentTerms,

  /*====================*/
  /*      Others        */
  /*====================*/
  @UI.lineItem: [{ position: 130 }]
  AssignmentReference,

  @UI.lineItem: [{ position: 140 }]
  AccountingDocumentType,

  @UI.lineItem: [{ position: 150 }]
  DocumentItemText,

  /* Associations */
  _Supplier,
  _CompanyCode
}
