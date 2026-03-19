@EndUserText.label: 'Fiscal Period Dimension'

define view entity ZI_GL_PERIOD
  as select from I_FiscalYearPeriod
{
    key FiscalYear,
    key FiscalPeriod as Period
}
where FiscalPeriod <= '013'
