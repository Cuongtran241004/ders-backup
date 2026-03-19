@EndUserText.label: 'Tham số chạy báo cáo Aging'
define abstract entity ZEA_AR_AGING_PARAM
{
  @EndUserText.label: 'Mã công ty (Company Code)'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
  company_code   : bukrs;

  @EndUserText.label: 'Mã khách hàng (Customer ID)'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
  customer       : kunnr;

  @EndUserText.label: 'Ngày chốt số nợ (Key Date)'
  key_date       : abap.dats;

  @EndUserText.label: 'Ngày căn cứ tính tuổi (Base Date)'
  base_date      : abap.dats;
  
//  @EndUserText.label: 'Bao gồm hóa đơn tương lai'
//  include_future : abap_boolean;
}
