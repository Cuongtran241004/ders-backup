@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Vendor Open Items - Interface'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define root view entity ZI_VendorOpenItem
  as select from I_JournalEntryItem
  /* Associations to Master Data */
  association [1..1] to I_Supplier    as _Supplier    on $projection.Supplier = _Supplier.Supplier
  association [1..1] to I_CompanyCode as _CompanyCode on $projection.CompanyCode = _CompanyCode.CompanyCode
  association [1..1] to I_SupplierCompany as _SupplierCompany on $projection.Supplier    = _SupplierCompany.Supplier 
                                                             and $projection.CompanyCode = _SupplierCompany.CompanyCode
{
  /*====================*/
  /*        Keys        */
  /*====================*/
  key CompanyCode,
  key AccountingDocument,
  key FiscalYear,
  key AccountingDocumentItem,

  /*====================*/
  /*      Supplier      */ 
  /*====================*/
  Supplier,
  _Supplier.SupplierName,
  _Supplier.SupplierAccountGroup as VendorGroup,
  _Supplier.Country              as Country,

  /*====================*/
  /*        Dates       */
  /*====================*/
  PostingDate,
  DocumentDate,
  
  // Tính toán số ngày quá hạn sơ bộ (Aging cơ bản dựa trên System Date)
  dats_days_between(NetDueDate, $session.system_date) as OverdueDays,

  /*====================*/
  /*       Amount       */
  /*====================*/
  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  AmountInCompanyCodeCurrency,
  
  CompanyCodeCurrency,

  /*====================*/
  /*      Account       */
  /*====================*/
  GLAccount                      as ReconciliationAccount,
  
  /*====================*/
  /*      Clearing      */
  /*====================*/
  ClearingAccountingDocument,
  ClearingDate,

  /*====================*/
  /*   Payment Terms    */
  /*====================*/
  NetDueDate,
  _SupplierCompany.PaymentTerms,
  AssignmentReference,
  
  /*====================*/
  /*      Others        */
  /*====================*/
  AccountingDocumentType,
  DocumentItemText,
  
  /* Ad-hoc Associations */
  _Supplier,
  _CompanyCode

}
where
      FinancialAccountType       = 'K'  // Chỉ lấy Vendor (Supplier)
  and ClearingAccountingDocument = ''   // Chỉ lấy Open Items
  and BalanceTransactionCurrency = 'VND' // Theo yêu cầu của bạn là VND
