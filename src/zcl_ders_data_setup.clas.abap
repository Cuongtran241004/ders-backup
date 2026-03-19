"!──────────────────────────────────────────────────────────────────────────────
"! CLASS: ZCL_DERS_DATA_SETUP
"! PURPOSE: Initialize default data for DERS value help tables
"! USAGE: Run via SE38 report or F9 in ADT
"!
"! Tables populated:
"!   - ZDERS_MODULE_VT  : SAP Modules (FI, CO, MM, SD, HR, PP)
"!   - ZDERS_FORMAT_VT  : Output formats (XLSX, CSV, PDF)
"!   - ZDERS_FREQ_VT    : Schedule frequency (Daily, Weekly, Monthly...)
"!   - ZDERS_STATUS_VT  : Subscription status (Active, Paused, Deleted)
"!   - ZDERS_JOBSTAT_VT : Job status (Scheduled, Running, Completed...)
"!   - ZDERS_CATALOG    : Sample report catalog entries
"!   - ZDERS_PARAM      : Sample report parameters
"!   - ZDERS_ROLE_PERM  : Role-Report permission defaults
"!   - ZDERS_UASSIGN    : User-Company assignments
"!   - ZDERS_USER_PERM  : User report permissions
"!──────────────────────────────────────────────────────────────────────────────
CLASS zcl_ders_data_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CLASS-METHODS:
      "! Run all setup methods
      setup_all
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        EXPORTING
          ev_message       TYPE string,

      "! Setup module master data
      setup_modules
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup output format master data
      setup_formats
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup frequency master data
      setup_frequencies
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup subscription status master data
      setup_statuses
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup job status master data
      setup_job_statuses
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup sample report catalog
      setup_sample_catalog
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup sample report parameters
      setup_sample_parameters
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup role-report permission defaults
      setup_role_permissions
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup sample user-company assignments
      setup_user_assignments
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Setup user permissions (from role defaults)
      setup_user_permissions
        IMPORTING
          iv_force_refresh TYPE abap_bool DEFAULT abap_false
        RETURNING
          VALUE(rv_count)  TYPE i,

      "! Register the subscription scanner as an APJ recurring job (run ONCE).
      "! Creates a hourly APJ job using ZDERS_SCANNER_TEMPLATE.
      "! DO NOT call from setup_all - call manually after initial system setup.
      setup_scanner_job
        RETURNING
          VALUE(rv_registered) TYPE abap_bool.

  PRIVATE SECTION.
    CLASS-DATA:
      gv_timestamp TYPE timestampl.

    CLASS-METHODS:
      get_timestamp
        RETURNING
          VALUE(rv_timestamp) TYPE timestampl.

ENDCLASS.


CLASS zcl_ders_data_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " Entry point when running class with F9 in ADT
    DATA lv_message TYPE string.

    setup_all(
      EXPORTING
        iv_force_refresh = abap_true   " Always refresh data when running F9
      IMPORTING
        ev_message = lv_message
    ).

    out->write( lv_message ).

  ENDMETHOD.


  METHOD setup_all.
    DATA:
      lv_modules      TYPE i,
      lv_formats      TYPE i,
      lv_frequencies  TYPE i,
      lv_statuses     TYPE i,
      lv_job_statuses TYPE i,
      lv_catalog      TYPE i,
      lv_parameters   TYPE i,
      lv_role_perms   TYPE i,
      lv_user_assign  TYPE i,
      lv_user_perms   TYPE i.

    " Setup all master data
    lv_modules      = setup_modules( iv_force_refresh ).
    lv_formats      = setup_formats( iv_force_refresh ).
    lv_frequencies  = setup_frequencies( iv_force_refresh ).
    lv_statuses     = setup_statuses( iv_force_refresh ).
    lv_job_statuses = setup_job_statuses( iv_force_refresh ).
    lv_catalog      = setup_sample_catalog( iv_force_refresh ).
    lv_parameters   = setup_sample_parameters( iv_force_refresh ).

    " Setup user management data (order matters: roles → assignments → permissions)
    lv_role_perms   = setup_role_permissions( iv_force_refresh ).
    lv_user_assign  = setup_user_assignments( iv_force_refresh ).
    lv_user_perms   = setup_user_permissions( iv_force_refresh ).

    " Commit all changes
    COMMIT WORK AND WAIT.

    " Build result message
    ev_message = |DERS Data Setup Complete:\n| &&
                 |─────────────────────────\n| &&
                 |Modules:        { lv_modules } records\n| &&
                 |Formats:        { lv_formats } records\n| &&
                 |Frequencies:    { lv_frequencies } records\n| &&
                 |Statuses:       { lv_statuses } records\n| &&
                 |Job Statuses:   { lv_job_statuses } records\n| &&
                 |Catalog:        { lv_catalog } records\n| &&
                 |Parameters:     { lv_parameters } records\n| &&
                 |─────────────────────────\n| &&
                 |Role Perms:     { lv_role_perms } records\n| &&
                 |User Assigns:   { lv_user_assign } records\n| &&
                 |User Perms:     { lv_user_perms } records\n| &&
                 |─────────────────────────\n| &&
                 |Total: { lv_modules + lv_formats + lv_frequencies +
                           lv_statuses + lv_job_statuses + lv_catalog +
                           lv_parameters + lv_role_perms + lv_user_assign +
                           lv_user_perms } records\n| &&
                 |─────────────────────────\n| &&
                 |NEXT STEP (run once):\n| &&
                 |  zcl_ders_data_setup=>setup_scanner_job( )\n| &&
                 |  → Registers hourly APJ job ZDERS_SCANNER_TEMPLATE\n| &&
                 |  → Monitor: transaction JOBM or SM37|.
  ENDMETHOD.


  METHOD setup_modules.
    " Use actual table structure: zders_module_vt
    DATA lt_data TYPE STANDARD TABLE OF zders_module_vt.

    " Check if data exists
    SELECT COUNT(*) FROM zders_module_vt INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_module_vt.
    ENDIF.

    " Prepare module data (fields: module_id, description, is_active)
    lt_data = VALUE #(
      ( mandt = sy-mandt  module_id = 'FI'  description = 'Finance'                 is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'CO'  description = 'Controlling'             is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'MM'  description = 'Materials Management'    is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'SD'  description = 'Sales & Distribution'    is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'HR'  description = 'Human Resources'         is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'PP'  description = 'Production Planning'     is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'PM'  description = 'Plant Maintenance'       is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'QM'  description = 'Quality Management'      is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'PS'  description = 'Project System'          is_active = abap_true )
      ( mandt = sy-mandt  module_id = 'WM'  description = 'Warehouse Management'    is_active = abap_true )
    ).

    " Insert data
    INSERT zders_module_vt FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_formats.
    " Use actual table structure: zders_format_vt
    DATA lt_data TYPE STANDARD TABLE OF zders_format_vt.

    " Check if data exists
    SELECT COUNT(*) FROM zders_format_vt INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_format_vt.
    ENDIF.

    " Prepare format data (fields: format_id, description, file_extension, mime_type, is_active)
    lt_data = VALUE #(
      ( mandt = sy-mandt  format_id = 'XLSX'
        description = 'Excel Workbook'
        file_extension = 'xlsx'
        mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        is_active = abap_true )
      ( mandt = sy-mandt  format_id = 'CSV'
        description = 'CSV (Comma Separated)'
        file_extension = 'csv'
        mime_type = 'text/csv'
        is_active = abap_true )
      ( mandt = sy-mandt  format_id = 'PDF'
        description = 'PDF Document'
        file_extension = 'pdf'
        mime_type = 'application/pdf'
        is_active = abap_true )
      ( mandt = sy-mandt  format_id = 'JSON'
        description = 'JSON Data'
        file_extension = 'json'
        mime_type = 'application/json'
        is_active = abap_true )
      ( mandt = sy-mandt  format_id = 'XML'
        description = 'XML Data'
        file_extension = 'xml'
        mime_type = 'application/xml'
        is_active = abap_false )  " Inactive by default
    ).

    " Insert data
    INSERT zders_format_vt FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_frequencies.
    " Use actual table structure: zders_freq_vt
    DATA lt_data TYPE STANDARD TABLE OF zders_freq_vt.

    " Check if data exists
    SELECT COUNT(*) FROM zders_freq_vt INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_freq_vt.
    ENDIF.

    " Prepare frequency data (fields: frequency, description, cron_pattern, is_active)
    lt_data = VALUE #(
      ( mandt = sy-mandt  frequency = 'D'  description = 'Daily'       cron_pattern = '0 6 * * *'     is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'W'  description = 'Weekly'      cron_pattern = '0 6 * * 1'     is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'B'  description = 'Bi-Weekly'   cron_pattern = '0 6 1,15 * *'  is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'M'  description = 'Monthly'     cron_pattern = '0 6 1 * *'     is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'Q'  description = 'Quarterly'   cron_pattern = '0 6 1 1,4,7,10 *' is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'H'  description = 'Half-Yearly' cron_pattern = '0 6 1 1,7 *'   is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'Y'  description = 'Yearly'      cron_pattern = '0 6 1 1 *'     is_active = abap_true )
      ( mandt = sy-mandt  frequency = 'O'  description = 'One-Time'    cron_pattern = ''              is_active = abap_true )
    ).

    " Insert data
    INSERT zders_freq_vt FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_statuses.
    " Use actual table structure: zders_status_vt
    DATA lt_data TYPE STANDARD TABLE OF zders_status_vt.

    " Check if data exists
    SELECT COUNT(*) FROM zders_status_vt INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_status_vt.
    ENDIF.

    " Prepare status data (fields: status, description, criticality)
    " Criticality: 0=Grey, 1=Red, 2=Yellow, 3=Green
    lt_data = VALUE #(
      ( mandt = sy-mandt  status = 'A'  description = 'Active'   criticality = 3 )  " Green
      ( mandt = sy-mandt  status = 'P'  description = 'Paused'   criticality = 2 )  " Yellow
      ( mandt = sy-mandt  status = 'D'  description = 'Deleted'  criticality = 1 )  " Red
      ( mandt = sy-mandt  status = 'I'  description = 'Inactive' criticality = 0 )  " Grey
    ).

    " Insert data
    INSERT zders_status_vt FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_job_statuses.
    " Use actual table structure: zders_jobstat_vt
    DATA lt_data TYPE STANDARD TABLE OF zders_jobstat_vt.

    " Check if data exists
    SELECT COUNT(*) FROM zders_jobstat_vt INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_jobstat_vt.
    ENDIF.

    " Prepare job status data (fields: status, description, criticality, icon)
    " Criticality: 0=Grey, 1=Red, 2=Yellow, 3=Green
    lt_data = VALUE #(
      ( mandt = sy-mandt  status = 'S'  description = 'Scheduled'  criticality = 0  icon = 'sap-icon://calendar' )
      ( mandt = sy-mandt  status = 'R'  description = 'Running'    criticality = 2  icon = 'sap-icon://process' )
      ( mandt = sy-mandt  status = 'C'  description = 'Completed'  criticality = 3  icon = 'sap-icon://accept' )
      ( mandt = sy-mandt  status = 'F'  description = 'Failed'     criticality = 1  icon = 'sap-icon://error' )
      ( mandt = sy-mandt  status = 'X'  description = 'Cancelled'  criticality = 0  icon = 'sap-icon://decline' )
      ( mandt = sy-mandt  status = 'W'  description = 'Warning'    criticality = 2  icon = 'sap-icon://warning' )
    ).

    " Insert data
    INSERT zders_jobstat_vt FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_sample_catalog.
    " Use actual table structure: zders_catalog
    DATA lt_data TYPE STANDARD TABLE OF zders_catalog.
    DATA lv_ts TYPE timestampl.

    " Check if data exists
    SELECT COUNT(*) FROM zders_catalog INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_catalog.
    ENDIF.

    lv_ts = get_timestamp( ).

    " Prepare sample catalog entries
    " Fields: report_id, module_id, report_name, description, cds_view_name,
    "         report_class, supported_formats, max_rows, is_active, created_by, etc.
    lt_data = VALUE #(
      " ─────────────────────────────────────────────────────────────
      " FI Module Reports
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id        = 'UC-FI-01'
        module_id        = 'FI'
        report_name      = 'AR Aging Report'
        description      = 'Accounts Receivable Aging Analysis by Customer'
        cds_view_name    = 'ZI_DERS_RPT_AR_AGING'
        report_class     = 'ZCL_DERS_RPT_AR_AGING'
        supported_formats = 'XLSX,CSV,PDF'
        max_rows         = 100000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )

      ( mandt = sy-mandt
        report_id        = 'UC-FI-02'
        module_id        = 'FI'
        report_name      = 'AP Payment Proposal'
        description      = 'Accounts Payable Payment Proposal Report'
        cds_view_name    = 'ZI_DERS_AP_PAYMENT'
        report_class     = 'ZCL_DERS_RPT_AP_PAYMENT'
        supported_formats = 'XLSX,CSV,PDF'
        max_rows         = 100000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )

      ( mandt = sy-mandt
        report_id        = 'UC-FI-03'
        module_id        = 'FI'
        report_name      = 'Cash Position Report'
        description      = 'Daily Cash Position Analysis'
        cds_view_name    = 'ZI_DERS_CASH_POS'
        report_class     = 'ZCL_DERS_RPT_CASH_POS'
        supported_formats = 'XLSX,PDF'
        max_rows         = 50000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )

      ( mandt = sy-mandt
        report_id        = 'UC-FI-04'
        module_id        = 'FI'
        report_name      = 'GL Reconciliation'
        description      = 'General Ledger Reconciliation Report'
        cds_view_name    = 'ZI_DERS_GL_RECON'
        report_class     = 'ZCL_DERS_RPT_GL_RECON'
        supported_formats = 'XLSX,CSV'
        max_rows         = 100000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )

      " ─────────────────────────────────────────────────────────────
      " CO Module Reports
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id        = 'UC-FI-05'
        module_id        = 'CO'
        report_name      = 'Budget vs Actual'
        description      = 'Budget vs Actual Variance Analysis'
        cds_view_name    = 'ZI_DERS_BUDGET'
        report_class     = 'ZCL_DERS_RPT_BUDGET'
        supported_formats = 'XLSX,PDF'
        max_rows         = 50000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )

      " ─────────────────────────────────────────────────────────────
      " MM Module Reports
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id        = 'UC-MM-01'
        module_id        = 'MM'
        report_name      = 'Stock Overview'
        description      = 'Material Stock Overview by Plant/Storage Location'
        cds_view_name    = 'ZI_DERS_STOCK'
        report_class     = 'ZCL_DERS_RPT_STOCK'
        supported_formats = 'XLSX,CSV'
        max_rows         = 200000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )

      " ─────────────────────────────────────────────────────────────
      " SD Module Reports
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id        = 'UC-SD-01'
        module_id        = 'SD'
        report_name      = 'Sales Analysis'
        description      = 'Sales Revenue Analysis by Customer/Product'
        cds_view_name    = 'ZI_DERS_SALES'
        report_class     = 'ZCL_DERS_RPT_SALES'
        supported_formats = 'XLSX,CSV,PDF'
        max_rows         = 100000
        is_active        = abap_true
        created_by       = sy-uname
        created_at       = lv_ts
        changed_by       = sy-uname
        changed_at       = lv_ts )
    ).

    " Insert data
    INSERT zders_catalog FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_sample_parameters.
    " Use actual table structure: zders_param
    DATA lt_data TYPE STANDARD TABLE OF zders_param.
    DATA lv_ts TYPE timestampl.

    " Check if data exists
    SELECT COUNT(*) FROM zders_param INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    " Clear existing data if force refresh
    IF iv_force_refresh = abap_true.
      DELETE FROM zders_param.
    ENDIF.

    lv_ts = get_timestamp( ).

    " Prepare parameter data
    " Fields: report_id, param_seq, param_name, param_label, param_type,
    "         data_element, is_mandatory, default_value, etc.
    lt_data = VALUE #(
      " ─────────────────────────────────────────────────────────
      " UC-FI-01 AR Aging Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-FI-01'
        param_seq     = '001'
        param_name    = 'BUKRS'
        param_label   = 'Company Code'
        param_type    = 'S'
        data_element  = 'BUKRS'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-01'
        param_seq     = '002'
        param_name    = 'CustomerNumber'
        param_label   = 'Customer'
        param_type    = 'R'
        data_element  = 'KUNNR'
        is_mandatory  = abap_false
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-01'
        param_seq     = '003'
        param_name    = 'P_KeyDate'
        param_label   = 'Key Date'
        param_type    = 'P'  " P=CDS Parameter: passed as FROM clause param, not WHERE
        data_element  = 'BUDAT'
        is_mandatory  = abap_false
        default_value = 'SY-DATUM'
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " ─────────────────────────────────────────────────────────
      " UC-FI-02 AP Payment Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-FI-02'
        param_seq     = '001'
        param_name    = 'BUKRS'
        param_label   = 'Company Code'
        param_type    = 'S'
        data_element  = 'BUKRS'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-02'
        param_seq     = '002'
        param_name    = 'LIFNR'
        param_label   = 'Vendor'
        param_type    = 'R'
        data_element  = 'LIFNR'
        is_mandatory  = abap_false
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " ─────────────────────────────────────────────────────────
      " UC-FI-03 Cash Position Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-FI-03'
        param_seq     = '001'
        param_name    = 'BUKRS'
        param_label   = 'Company Code'
        param_type    = 'S'
        data_element  = 'BUKRS'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-03'
        param_seq     = '002'
        param_name    = 'WAERS'
        param_label   = 'Currency'
        param_type    = 'S'
        data_element  = 'WAERS'
        is_mandatory  = abap_true
        default_value = 'USD'
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " ─────────────────────────────────────────────────────────
      " UC-FI-04 GL Recon Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-FI-04'
        param_seq     = '001'
        param_name    = 'BUKRS'
        param_label   = 'Company Code'
        param_type    = 'S'
        data_element  = 'BUKRS'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-04'
        param_seq     = '002'
        param_name    = 'GJAHR'
        param_label   = 'Fiscal Year'
        param_type    = 'S'
        data_element  = 'GJAHR'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " ─────────────────────────────────────────────────────────
      " UC-FI-05 Budget vs Actual Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-FI-05'
        param_seq     = '001'
        param_name    = 'KOKRS'
        param_label   = 'Controlling Area'
        param_type    = 'S'
        data_element  = 'KOKRS'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-05'
        param_seq     = '002'
        param_name    = 'GJAHR'
        param_label   = 'Fiscal Year'
        param_type    = 'S'
        data_element  = 'GJAHR'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-FI-05'
        param_seq     = '003'
        param_name    = 'KOSTL'
        param_label   = 'Cost Center'
        param_type    = 'R'
        data_element  = 'KOSTL'
        is_mandatory  = abap_false
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " ─────────────────────────────────────────────────────────
      " UC-MM-01 Stock Overview Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-MM-01'
        param_seq     = '001'
        param_name    = 'WERKS'
        param_label   = 'Plant'
        param_type    = 'R'
        data_element  = 'WERKS_D'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-MM-01'
        param_seq     = '002'
        param_name    = 'MATNR'
        param_label   = 'Material'
        param_type    = 'R'
        data_element  = 'MATNR'
        is_mandatory  = abap_false
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " ─────────────────────────────────────────────────────────
      " UC-SD-01 Sales Analysis Parameters
      " ─────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        report_id     = 'UC-SD-01'
        param_seq     = '001'
        param_name    = 'VKORG'
        param_label   = 'Sales Organization'
        param_type    = 'S'
        data_element  = 'VKORG'
        is_mandatory  = abap_true
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      ( mandt = sy-mandt
        report_id     = 'UC-SD-01'
        param_seq     = '002'
        param_name    = 'KUNNR'
        param_label   = 'Customer'
        param_type    = 'R'
        data_element  = 'KUNNR'
        is_mandatory  = abap_false
        default_value = ''
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )
    ).

    " Insert data
    INSERT zders_param FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD get_timestamp.
    GET TIME STAMP FIELD rv_timestamp.
  ENDMETHOD.


  METHOD setup_role_permissions.
    DATA lt_data TYPE STANDARD TABLE OF zders_role_perm.
    DATA lv_ts TYPE timestampl.

    " Check if data exists
    SELECT COUNT(*) FROM zders_role_perm INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    IF iv_force_refresh = abap_true.
      DELETE FROM zders_role_perm.
    ENDIF.

    lv_ts = get_timestamp( ).

    " Define which reports each role can access by default
    lt_data = VALUE #(
      " ─────────────────────────────────────────────────────────────
      " Role: Z_AR_ACCT (AR Accountant)
      " Access: AR Aging, Cash Position, GL Recon
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt  business_role = 'Z_AR_ACCT'
        report_id = 'UC-FI-01'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_AR_ACCT'
        report_id = 'UC-FI-03'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_AR_ACCT'
        report_id = 'UC-FI-04'  can_export = abap_true  can_subscribe = abap_false
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      " ─────────────────────────────────────────────────────────────
      " Role: Z_AP_ACCT (AP Accountant)
      " Access: AP Payment, Cash Position
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt  business_role = 'Z_AP_ACCT'
        report_id = 'UC-FI-02'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_AP_ACCT'
        report_id = 'UC-FI-03'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      " ─────────────────────────────────────────────────────────────
      " Role: Z_FI_MGR (Finance Manager)
      " Access: ALL FI reports + Budget
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt  business_role = 'Z_FI_MGR'
        report_id = 'UC-FI-01'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_FI_MGR'
        report_id = 'UC-FI-02'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_FI_MGR'
        report_id = 'UC-FI-03'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_FI_MGR'
        report_id = 'UC-FI-04'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_FI_MGR'
        report_id = 'UC-FI-05'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      " ─────────────────────────────────────────────────────────────
      " Role: Z_CO_ANALYST (Cost Analyst)
      " Access: Budget vs Actual, GL Recon
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt  business_role = 'Z_CO_ANALYST'
        report_id = 'UC-FI-05'  can_export = abap_true  can_subscribe = abap_true
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )

      ( mandt = sy-mandt  business_role = 'Z_CO_ANALYST'
        report_id = 'UC-FI-04'  can_export = abap_true  can_subscribe = abap_false
        is_default = abap_true  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  changed_by = sy-uname  changed_at = lv_ts )
    ).

    INSERT zders_role_perm FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_user_assignments.
    DATA lt_data TYPE STANDARD TABLE OF zders_uassign.
    DATA lv_ts TYPE timestampl.

    " Check if data exists
    SELECT COUNT(*) FROM zders_uassign INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    IF iv_force_refresh = abap_true.
      DELETE FROM zders_uassign.
    ENDIF.

    lv_ts = get_timestamp( ).

    " Sample user-company assignments
    " NOTE: These users must exist in USR02 on the target system
    "       Replace with actual user IDs from your SAP system
    lt_data = VALUE #(
      " ─────────────────────────────────────────────────────────────
      " Demo: Current user as Finance Manager for company 1000
      " ─────────────────────────────────────────────────────────────
      ( mandt = sy-mandt
        user_id       = sy-uname
        bukrs         = '1000'
        business_role = 'Z_FI_MGR'
        is_active     = abap_true
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )

      " Demo: Current user as Finance Manager for company 2000
      ( mandt = sy-mandt
        user_id       = sy-uname
        bukrs         = '2000'
        business_role = 'Z_FI_MGR'
        is_active     = abap_true
        created_by    = sy-uname
        created_at    = lv_ts
        changed_by    = sy-uname
        changed_at    = lv_ts )
    ).

    INSERT zders_uassign FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    rv_count = lines( lt_data ).
  ENDMETHOD.


  METHOD setup_user_permissions.
    DATA lt_data TYPE STANDARD TABLE OF zders_user_perm.
    DATA lv_ts TYPE timestampl.

    " Check if data exists
    SELECT COUNT(*) FROM zders_user_perm INTO @DATA(lv_existing).
    IF lv_existing > 0 AND iv_force_refresh = abap_false.
      rv_count = lv_existing.
      RETURN.
    ENDIF.

    IF iv_force_refresh = abap_true.
      DELETE FROM zders_user_perm.
    ENDIF.

    lv_ts = get_timestamp( ).

    " Auto-generate permissions from role defaults for assigned users
    " Read all user assignments
    SELECT user_id, bukrs, business_role
      FROM zders_uassign
      WHERE is_active = @abap_true
      INTO TABLE @DATA(lt_assignments).

    IF lt_assignments IS INITIAL.
      rv_count = 0.
      RETURN.
    ENDIF.

    " For each assignment, get role permissions and create user permissions
    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>).
      " Get role defaults
      SELECT business_role, report_id, can_export, can_subscribe
        FROM zders_role_perm
        WHERE business_role = @<fs_assign>-business_role
          AND is_default    = @abap_true
          AND is_active     = @abap_true
        INTO TABLE @DATA(lt_role_perms).

      " Create user permission for each role default
      LOOP AT lt_role_perms ASSIGNING FIELD-SYMBOL(<fs_role>).
        APPEND VALUE #(
          mandt         = sy-mandt
          user_id       = <fs_assign>-user_id
          report_id     = <fs_role>-report_id
          bukrs         = <fs_assign>-bukrs
          can_export    = <fs_role>-can_export
          can_subscribe = <fs_role>-can_subscribe
          perm_type     = 'D'         " Default from role
          is_active     = abap_true
          created_by    = sy-uname
          created_at    = lv_ts
          changed_by    = sy-uname
          changed_at    = lv_ts
        ) TO lt_data.
      ENDLOOP.
    ENDLOOP.

    IF lt_data IS NOT INITIAL.
      INSERT zders_user_perm FROM TABLE lt_data ACCEPTING DUPLICATE KEYS.
    ENDIF.
    rv_count = lines( lt_data ).
  ENDMETHOD.

  METHOD setup_scanner_job.
    " Register ZDERS_SUBSCRIPTION_SCANNER as an hourly APJ recurring job.
    " Call this method ONCE after initial system setup.
    " Calling it again will create a duplicate recurring job - check JOBM first.
    rv_registered = abap_false.
    TRY.
        zcl_ders_subscription_scanner=>register_recurring_job( ).
        rv_registered = abap_true.
        WRITE: / 'Scanner job registered successfully. Monitor via JOBM or SM37.'.
      CATCH zcx_ders_job_error INTO DATA(lx_err).
        WRITE: / |Scanner registration failed: { lx_err->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


ENDCLASS.

