CLASS zcl_debug_template DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_debug_template IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " Check what parameters the processor class defines
    DATA lv_template TYPE apj_job_template_name VALUE 'ZDERS_JOB_TEMPLATE_V4'.
    DATA lv_catalog  TYPE cl_apj_dt_create_content=>ty_catalog_name VALUE 'ZDERS_JOB_CATALOG_V4'.

    out->write( |===== APJ TEMPLATE VERIFICATION =====| ).
    out->write( |Template: { lv_template }| ).
    out->write( |Catalog: { lv_catalog }| ).
    out->write( |---| ).

    " Get parameter definition from the processor class
    TRY.
        DATA lo_processor TYPE REF TO zcl_ders_job_processor.
        CREATE OBJECT lo_processor.

        DATA lt_params TYPE if_apj_dt_exec_object=>tt_templ_def.
        lo_processor->if_apj_dt_exec_object~get_parameters(
          IMPORTING
            et_parameter_def = lt_params ).

        out->write( |Processor class (ZCL_DERS_JOB_PROCESSOR) defines { lines( lt_params ) } parameter(s):| ).

        DATA lv_found_p_jobuuid TYPE abap_bool VALUE abap_false.
        LOOP AT lt_params INTO DATA(ls_param).
          out->write( |  - { ls_param-selname }: type={ ls_param-datatype }, len={ ls_param-length }, mandatory={ ls_param-mandatory_ind }| ).
          IF ls_param-selname = 'P_JOBUUI'.
            lv_found_p_jobuuid = abap_true.
          ENDIF.
        ENDLOOP.

        out->write( |---| ).

        IF lv_found_p_jobuuid = abap_true.
          out->write( |✓ GOOD: P_JOBUUI parameter is defined in processor| ).
          out->write( |  Type should be: C (CHAR)| ).
          out->write( |  Length should be: 32| ).
        ELSE.
          out->write( |✗ ERROR: P_JOBUUI parameter NOT FOUND in processor!| ).
          out->write( |  This will cause the job to fail!| ).
        ENDIF.

        out->write( |---| ).
        out->write( |IMPORTANT: If you modified the processor class parameter definition,| ).
        out->write( |you MUST run ZCL_DERS_JOB_SETUP (F9) to refresh the APJ template.| ).
        out->write( |The template won't automatically update when you change the class.| ).

      CATCH cx_root INTO DATA(lx_err).
        out->write( |✗ ERROR: Cannot instantiate processor class!| ).
        out->write( |  { lx_err->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

