"! <p class="shorttext synchronized">Report Generator - Core Engine</p>
"! Central class that:
"! 1. Reads report metadata from Catalog
"! 2. Executes the appropriate CDS view with parameters
"! 3. Generates output file (XLSX/PDF/CSV)
"!
"! <strong>Usage Flow:</strong>
"! <pre>
"! ┌─────────────────────────────────────────────────────────────────────────┐
"! │  User selects report from Catalog                                      │
"! │           ↓                                                            │
"! │  User enters parameters (Bukrs, KeyDate, etc.)                         │
"! │           ↓                                                            │
"! │  System calls zcl_ders_report_generator=>generate( )                   │
"! │           ↓                                                            │
"! │  1. Read catalog → get SourceType, SourceName                          │
"! │  2. Parse parameters from JSON                                         │
"! │  3. Execute CDS View / Function Module / Class                         │
"! │  4. Format data → XLSX/PDF/CSV                                         │
"! │  5. Store file → zders_file                                            │
"! │  6. Send email (if requested)                                          │
"! └─────────────────────────────────────────────────────────────────────────┘
"! </pre>
CLASS zcl_ders_report_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Report generation result
    TYPES: BEGIN OF ty_result,
             success    TYPE abap_bool,
             file_uuid  TYPE sysuuid_x16,
             file_name  TYPE string,
             file_size  TYPE int4,
             message    TYPE string,
           END OF ty_result.

    "! <p class="shorttext synchronized">Generate report</p>
    "! Main entry point - generates report based on catalog and parameters
    "! @parameter iv_report_id     | Report ID from catalog (e.g., 'AR_AGING')
    "! @parameter iv_bukrs         | Company Code
    "! @parameter iv_output_format | Output format: XLSX, PDF, CSV
    "! @parameter iv_param_json    | Additional parameters as JSON
    "! @parameter rs_result        | Generation result
    CLASS-METHODS generate
      IMPORTING
        iv_report_id     TYPE char10
        iv_bukrs         TYPE bukrs
        iv_output_format TYPE char4 DEFAULT 'XLSX'
        iv_param_json    TYPE string OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PROTECTED SECTION.

  PRIVATE SECTION.
    "! Read catalog metadata
    CLASS-METHODS get_catalog_info
      IMPORTING
        iv_report_id     TYPE char10
      EXPORTING
        ev_cds_view_name TYPE char30
      RETURNING
        VALUE(rv_found)  TYPE abap_bool.

    "! Parse JSON parameters
    CLASS-METHODS parse_parameters
      IMPORTING
        iv_param_json TYPE string
      RETURNING
        VALUE(rt_params) TYPE tihttpnvp.

    "! Execute CDS view and return data
    CLASS-METHODS execute_cds_view
      IMPORTING
        iv_cds_view_name TYPE char30
        iv_bukrs         TYPE bukrs
        it_params        TYPE tihttpnvp
      EXPORTING
        et_data          TYPE REF TO data
      RETURNING
        VALUE(rv_success) TYPE abap_bool.

    "! Generate XLSX file
    CLASS-METHODS generate_xlsx
      IMPORTING
        ir_data         TYPE REF TO data
        iv_report_id    TYPE char10
      RETURNING
        VALUE(rv_xstring) TYPE xstring.

    "! Store file to database
    CLASS-METHODS store_file
      IMPORTING
        iv_file_name    TYPE string
        iv_xstring      TYPE xstring
      RETURNING
        VALUE(rv_uuid)  TYPE sysuuid_x16.

ENDCLASS.



CLASS zcl_ders_report_generator IMPLEMENTATION.

  METHOD generate.
    "═══════════════════════════════════════════════════════════════════════
    " STEP 1: Read Catalog to get CDS View Name
    "═══════════════════════════════════════════════════════════════════════
    DATA: lv_cds_view_name TYPE char30.

    IF get_catalog_info(
         EXPORTING iv_report_id     = iv_report_id
         IMPORTING ev_cds_view_name = lv_cds_view_name
       ) = abap_false.
      rs_result = VALUE #(
        success = abap_false
        message = |Report '{ iv_report_id }' not found in catalog|
      ).
      RETURN.
    ENDIF.

    "═══════════════════════════════════════════════════════════════════════
    " STEP 2: Parse JSON parameters
    "═══════════════════════════════════════════════════════════════════════
    DATA(lt_params) = parse_parameters( iv_param_json ).

    "═══════════════════════════════════════════════════════════════════════
    " STEP 3: Execute data source based on SourceType
    "═══════════════════════════════════════════════════════════════════════
    DATA: lr_data TYPE REF TO data.

    "---------------------------------------------------------------
    " Execute CDS View
    "---------------------------------------------------------------
    IF execute_cds_view(
         EXPORTING
           iv_cds_view_name = lv_cds_view_name
           iv_bukrs         = iv_bukrs
           it_params        = lt_params
         IMPORTING
           et_data          = lr_data
       ) = abap_false.
      rs_result = VALUE #(
        success = abap_false
        message = |Failed to execute CDS view '{ lv_cds_view_name }'|
      ).
      RETURN.
    ENDIF.

    "═══════════════════════════════════════════════════════════════════════
    " STEP 4: Generate output file
    "═══════════════════════════════════════════════════════════════════════
    DATA: lv_xstring TYPE xstring,
          lv_file_name TYPE string.

    CASE iv_output_format.
      WHEN 'XLSX'.
        lv_xstring = generate_xlsx( ir_data = lr_data iv_report_id = iv_report_id ).
        lv_file_name = |{ iv_report_id }_{ iv_bukrs }_{ sy-datum }.xlsx|.

      WHEN 'CSV'.
        " TODO: Generate CSV
        lv_file_name = |{ iv_report_id }_{ iv_bukrs }_{ sy-datum }.csv|.

      WHEN 'PDF'.
        " TODO: Generate PDF
        lv_file_name = |{ iv_report_id }_{ iv_bukrs }_{ sy-datum }.pdf|.
    ENDCASE.

    "═══════════════════════════════════════════════════════════════════════
    " STEP 5: Store file
    "═══════════════════════════════════════════════════════════════════════
    DATA(lv_file_uuid) = store_file(
      iv_file_name = lv_file_name
      iv_xstring   = lv_xstring
    ).

    "═══════════════════════════════════════════════════════════════════════
    " STEP 6: Return result
    "═══════════════════════════════════════════════════════════════════════
    rs_result = VALUE #(
      success   = abap_true
      file_uuid = lv_file_uuid
      file_name = lv_file_name
      file_size = xstrlen( lv_xstring )
      message   = |Report generated successfully|
    ).
  ENDMETHOD.


  METHOD get_catalog_info.
    "═══════════════════════════════════════════════════════════════════════
    " Read catalog metadata to get CDS view name
    "═══════════════════════════════════════════════════════════════════════
    SELECT SINGLE cds_view_name
      FROM zders_catalog
      WHERE report_id = @iv_report_id
        AND is_active = @abap_true
      INTO @ev_cds_view_name.

    rv_found = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD parse_parameters.
    "═══════════════════════════════════════════════════════════════════════
    " Parse JSON string into parameter name-value pairs
    " Input:  {"keydate":"20260307","currency":"USD"}
    " Output: itab with name=keydate, value=20260307 etc.
    "═══════════════════════════════════════════════════════════════════════
    IF iv_param_json IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        " Use ABAP JSON parser
        DATA(lo_reader) = cl_sxml_string_reader=>create(
          cl_abap_codepage=>convert_to( iv_param_json )
        ).

        " Simple JSON parsing - would need proper implementation
        " This is a placeholder

      CATCH cx_root.
        " Return empty on parse error
    ENDTRY.
  ENDMETHOD.


  METHOD execute_cds_view.
    "═══════════════════════════════════════════════════════════════════════
    " Execute CDS view dynamically with WHERE clause filter
    "
    " KEY CONCEPT: The CDS view name comes from catalog.cds_view_name
    " Each report type has its own CDS view:
    "   - UC-FI-01  → ZI_DERS_RPT_AR_AGING
    "   - UC-FI-02  → ZI_DERS_RPT_AP_PAYMENT
    "   - UC-FI-03  → ZI_DERS_RPT_CASH_POSITION
    "═══════════════════════════════════════════════════════════════════════

    CASE iv_cds_view_name.
      WHEN 'ZI_DERS_RPT_AR_AGING'.
        "-----------------------------------------------------------------
        " AR Aging Report - Filter by Company Code
        "-----------------------------------------------------------------
        SELECT *
          FROM zi_ders_rpt_ar_aging
          WHERE bukrs = @iv_bukrs
          INTO TABLE @DATA(lt_ar_aging).

        " Create reference to data
        CREATE DATA et_data LIKE lt_ar_aging.
        ASSIGN et_data->* TO FIELD-SYMBOL(<lt_data>).
        <lt_data> = lt_ar_aging.

        rv_success = abap_true.

      WHEN OTHERS.
        " Unknown CDS view - for extensibility, add more WHEN clauses
        rv_success = abap_false.
    ENDCASE.
  ENDMETHOD.


  METHOD generate_xlsx.
    "═══════════════════════════════════════════════════════════════════════
    " Generate Excel file from data
    " Uses CL_XLSX_WORKBOOK_BUILDER (SAP standard)
    " OR custom implementation with cl_openxml_xlsx
    "═══════════════════════════════════════════════════════════════════════
    " Placeholder - actual implementation in 07-File-Generation.md

    " TODO: Implement XLSX generation
    " DATA(lo_builder) = NEW cl_xlsx_workbook_builder( ).
    " lo_builder->add_worksheet( ... ).
    " rv_xstring = lo_builder->get_content( ).
  ENDMETHOD.


  METHOD store_file.
    "═══════════════════════════════════════════════════════════════════════
    " Store generated file in zders_file table
    "═══════════════════════════════════════════════════════════════════════
    TRY.
        rv_uuid = cl_system_uuid=>create_uuid_x16_static( ).

        INSERT INTO zders_file VALUES @(
          VALUE #(
            file_uuid       = rv_uuid
            file_name       = iv_file_name
            file_content    = iv_xstring
            file_size_bytes = xstrlen( iv_xstring )
            created_by      = sy-uname
            created_at      = sy-datum
          )
        ).

      CATCH cx_root.
        CLEAR rv_uuid.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

