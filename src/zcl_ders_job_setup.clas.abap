"!──────────────────────────────────────────────────────────────────────────────
"! CLASS: ZCL_DERS_JOB_SETUP
"! PURPOSE: Setup script for SAP Application Job Catalog + Template
"!
"! Creates two APJ artifacts:
"!   1. ZDERS_JOB_CATALOG_V4   / ZDERS_JOB_TEMPLATE_V4
"!      Class: ZCL_DERS_JOB_PROCESSOR  (executes one report job)
"!
"!   2. ZDERS_SCANNER_CATALOG  / ZDERS_SCANNER_TEMPLATE
"!      Class: ZCL_DERS_SUBSCRIPTION_SCANNER  (hourly subscription polling)
"!
"! USAGE: Run with F9 in ADT. Safe to re-run - deletes old entries first.
"!──────────────────────────────────────────────────────────────────────────────
CLASS zcl_ders_job_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CLASS-METHODS setup_job_processor
      IMPORTING
        io_dt     TYPE REF TO cl_apj_dt_create_content
        io_out    TYPE REF TO if_oo_adt_classrun_out
        iv_tr     TYPE cl_apj_dt_create_content=>ty_transport_request
        iv_pkg    TYPE cl_apj_dt_create_content=>ty_package.

    CLASS-METHODS setup_scanner
      IMPORTING
        io_dt     TYPE REF TO cl_apj_dt_create_content
        io_out    TYPE REF TO if_oo_adt_classrun_out
        iv_tr     TYPE cl_apj_dt_create_content=>ty_transport_request
        iv_pkg    TYPE cl_apj_dt_create_content=>ty_package.

ENDCLASS.

CLASS zcl_ders_job_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    CONSTANTS lc_transport_request TYPE cl_apj_dt_create_content=>ty_transport_request VALUE 'S40K916289'.
    CONSTANTS lc_package           TYPE cl_apj_dt_create_content=>ty_package           VALUE 'ZPK_SP26_SAP01_DERS'.

    DATA(lo_dt) = cl_apj_dt_create_content=>get_instance( ).

    out->write( '=== DERS APJ Setup ===' ).
    out->write( ' ' ).

    out->write( '--- [1/2] Job Processor Template ---' ).
    setup_job_processor( io_dt = lo_dt io_out = out iv_tr = lc_transport_request iv_pkg = lc_package ).

    out->write( ' ' ).
    out->write( '--- [2/2] Subscription Scanner Template ---' ).
    setup_scanner( io_dt = lo_dt io_out = out iv_tr = lc_transport_request iv_pkg = lc_package ).

    out->write( ' ' ).
    out->write( '=== Setup Complete ===' ).
    out->write( 'NEXT: To activate subscription scheduling, run:' ).
    out->write( '  zcl_ders_data_setup=>setup_scanner_job( )' ).
    out->write( '  → Registers a recurring hourly APJ job for ZDERS_SCANNER_TEMPLATE' ).
  ENDMETHOD.

  METHOD setup_job_processor.
    CONSTANTS lc_catalog_name  TYPE cl_apj_dt_create_content=>ty_catalog_name  VALUE 'ZDERS_JOB_CATALOG_V4'.
    CONSTANTS lc_catalog_text  TYPE cl_apj_dt_create_content=>ty_text          VALUE 'DERS Report Export Job'.
    CONSTANTS lc_class_name    TYPE cl_apj_dt_create_content=>ty_class_name    VALUE 'ZCL_DERS_JOB_PROCESSOR'.
    CONSTANTS lc_template_name TYPE cl_apj_dt_create_content=>ty_template_name VALUE 'ZDERS_JOB_TEMPLATE_V4'.
    CONSTANTS lc_template_text TYPE cl_apj_dt_create_content=>ty_text          VALUE 'DERS Report Export Template'.

    " 0. Delete existing entries (safe re-run)
    TRY.
        io_dt->delete_job_template_entry( iv_template_name = lc_template_name iv_transport_request = iv_tr ).
        io_out->write( '  Template deleted (old)' ).
      CATCH cx_apj_dt_content.
    ENDTRY.
    TRY.
        io_dt->delete_job_cat_entry( iv_catalog_name = lc_catalog_name iv_transport_request = iv_tr ).
        io_out->write( '  Catalog deleted (old)' ).
      CATCH cx_apj_dt_content.
    ENDTRY.

    " 1. Create catalog entry
    TRY.
        io_dt->create_job_cat_entry(
            iv_catalog_name       = lc_catalog_name
            iv_class_name         = lc_class_name
            iv_text               = lc_catalog_text
            iv_catalog_entry_type = cl_apj_dt_create_content=>class_based
            iv_transport_request  = iv_tr
            iv_package            = iv_pkg
        ).
        io_out->write( |  Catalog created: { lc_catalog_name }| ).
      CATCH cx_apj_dt_content INTO DATA(lx1).
        io_out->write( |  ERROR catalog: { lx1->get_text( ) }| ).
        RETURN.
    ENDTRY.

    " 2. Create template with P_JOBUUI parameter
    DATA lt_params TYPE if_apj_dt_exec_object=>tt_templ_val.
    TRY.
        io_dt->create_job_template_entry(
            iv_template_name     = lc_template_name
            iv_catalog_name      = lc_catalog_name
            iv_text              = lc_template_text
            it_parameters        = lt_params
            iv_transport_request = iv_tr
            iv_package           = iv_pkg
        ).
        io_out->write( |  Template created: { lc_template_name }| ).
      CATCH cx_apj_dt_content INTO DATA(lx2).
        io_out->write( |  ERROR template: { lx2->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD setup_scanner.
    CONSTANTS lc_catalog_name  TYPE cl_apj_dt_create_content=>ty_catalog_name  VALUE 'ZDERS_SCANNER_CATALOG'.
    CONSTANTS lc_catalog_text  TYPE cl_apj_dt_create_content=>ty_text          VALUE 'DERS Subscription Scanner'.
    CONSTANTS lc_class_name    TYPE cl_apj_dt_create_content=>ty_class_name    VALUE 'ZCL_DERS_SUBSCRIPTION_SCANNER'.
    CONSTANTS lc_template_name TYPE cl_apj_dt_create_content=>ty_template_name VALUE 'ZDERS_SCANNER_TEMPLATE'.
    CONSTANTS lc_template_text TYPE cl_apj_dt_create_content=>ty_text          VALUE 'DERS Subscription Scanner (Hourly)'.

    " 0. Delete existing entries (safe re-run)
    TRY.
        io_dt->delete_job_template_entry( iv_template_name = lc_template_name iv_transport_request = iv_tr ).
        io_out->write( '  Template deleted (old)' ).
      CATCH cx_apj_dt_content.
    ENDTRY.
    TRY.
        io_dt->delete_job_cat_entry( iv_catalog_name = lc_catalog_name iv_transport_request = iv_tr ).
        io_out->write( '  Catalog deleted (old)' ).
      CATCH cx_apj_dt_content.
    ENDTRY.

    " 1. Create catalog entry
    TRY.
        io_dt->create_job_cat_entry(
            iv_catalog_name       = lc_catalog_name
            iv_class_name         = lc_class_name
            iv_text               = lc_catalog_text
            iv_catalog_entry_type = cl_apj_dt_create_content=>class_based
            iv_transport_request  = iv_tr
            iv_package            = iv_pkg
        ).
        io_out->write( |  Catalog created: { lc_catalog_name }| ).
      CATCH cx_apj_dt_content INTO DATA(lx1).
        io_out->write( |  ERROR catalog: { lx1->get_text( ) }| ).
        RETURN.
    ENDTRY.

    " 2. Create template (no parameters for scanner)
    DATA lt_params TYPE if_apj_dt_exec_object=>tt_templ_val.
    TRY.
        io_dt->create_job_template_entry(
            iv_template_name     = lc_template_name
            iv_catalog_name      = lc_catalog_name
            iv_text              = lc_template_text
            it_parameters        = lt_params
            iv_transport_request = iv_tr
            iv_package           = iv_pkg
        ).
        io_out->write( |  Template created: { lc_template_name }| ).
      CATCH cx_apj_dt_content INTO DATA(lx2).
        io_out->write( |  ERROR template: { lx2->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


