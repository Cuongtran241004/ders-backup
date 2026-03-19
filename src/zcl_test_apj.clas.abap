CLASS zcl_test_apj DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_test_apj IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA lt_apj_params TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA ls_apj_param  TYPE cl_apj_rt_api=>ty_job_parameter_value.
    DATA ls_value      TYPE cl_apj_rt_api=>ty_value_range.
    DATA ls_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA lv_jobname    TYPE cl_apj_rt_api=>ty_jobname.
    DATA lv_jobcount   TYPE cl_apj_rt_api=>ty_jobcount.

    " Generate UUID and convert to HEX string
    DATA(lv_uuid_raw) = cl_system_uuid=>create_uuid_x16_static( ).
    DATA(lv_uuid_str) = |{ lv_uuid_raw }|.  " Convert RAW16 to string

    ls_apj_param-name = 'P_JOBUUID'.
    ls_value-sign   = 'I'.
    ls_value-option = 'EQ'.
    ls_value-low    = lv_uuid_str.  " Pass as string!
    APPEND ls_value TO ls_apj_param-t_value.
    APPEND ls_apj_param TO lt_apj_params.

    ls_start_info-start_immediately = abap_true.

    TRY.
        cl_apj_rt_api=>schedule_job(
          EXPORTING
            iv_job_template_name   = 'ZDERS_JOB_TEMPLATE_V4'
            iv_job_text            = 'Test Job'
            it_job_parameter_value = lt_apj_params
            is_start_info          = ls_start_info
          IMPORTING
            ev_jobname  = lv_jobname
            ev_jobcount = lv_jobcount
        ).
        out->write( |Success! Job: { lv_jobname } / { lv_jobcount }| ).

      CATCH cx_apj_rt INTO DATA(lx).
        out->write( |Error: { lx->get_text( ) }| ).
        DATA(ls_ret) = lx->get_bapiret2( ).
        out->write( |ID: { ls_ret-id } Number: { ls_ret-number }| ).
        out->write( |Message: { ls_ret-message }| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
