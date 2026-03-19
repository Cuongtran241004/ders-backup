CLASS zcl_ders_job_scheduler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      c_job_template TYPE apj_job_template_name VALUE 'ZDERS_JOB_TEMPLATE_V4'.

    "! Schedule a subscription job immediately (from "Execute Now" action)
    CLASS-METHODS schedule_subscription
      IMPORTING
        iv_subscr_uuid TYPE sysuuid_x16
      RAISING
        zcx_ders_job_error.

    "! Schedule a one-time export job (from "Execute" action)
    CLASS-METHODS schedule_export
      IMPORTING
        iv_export_uuid TYPE sysuuid_x16
      RAISING
        zcx_ders_job_error.

    "! Scan all due subscriptions and schedule them (periodic)
    CLASS-METHODS scan_due_subscriptions
      RETURNING VALUE(rv_count) TYPE i.

    "! Core logic: create JOBHIST + JOB_PARAM + call CL_APJ_RT_API
    "! Public so retry action can also use it
    CLASS-METHODS create_and_schedule_job
      IMPORTING
        iv_job_type      TYPE zders_jobhist-job_type
        iv_source_uuid   TYPE sysuuid_x16
        iv_report_id     TYPE zders_jobhist-report_id
        iv_user_id       TYPE syuname
        iv_bukrs         TYPE bukrs
        iv_output_format TYPE zders_jobhist-output_format
        it_params        TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_job_uuid) TYPE sysuuid_x16
      RAISING
        zcx_ders_job_error.

ENDCLASS.

CLASS zcl_ders_job_scheduler IMPLEMENTATION.

  METHOD schedule_subscription.
    " Called by Subscription.executeNow action
    " Flow: Read SUBSCR + SUB_PARAM -> create_and_schedule_job
    " Read subscription header
    SELECT SINGLE * FROM zders_subscr
      WHERE subscr_uuid = @iv_subscr_uuid
      INTO @DATA(ls_subscr).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_ders_job_error
        EXPORTING
          textid  = zcx_ders_job_error=>subscription_not_found
          message = |Subscription UUID '{ iv_subscr_uuid }' not found|.
    ENDIF.

    " Read subscription parameters (structured child table)
    SELECT * FROM zders_sub_param
      WHERE subscr_uuid = @iv_subscr_uuid
      ORDER BY param_seq
      INTO TABLE @DATA(lt_sub_params).

    " Convert ZDERS_SUB_PARAM -> ZDERS_JOB_PARAM format
    DATA lt_job_params TYPE STANDARD TABLE OF zders_job_param.
    LOOP AT lt_sub_params INTO DATA(ls_sp).
      APPEND VALUE #(
        item_no          = ls_sp-param_seq
        param_name       = ls_sp-param_name
        param_label      = ls_sp-param_label
        param_value_from = COND #( WHEN ls_sp-param_value_from IS NOT INITIAL
                                   THEN ls_sp-param_value_from
                                   ELSE ls_sp-param_value )
        param_value_to   = ls_sp-param_value_to
        param_type       = ls_sp-param_type
        data_element     = ls_sp-data_element
      ) TO lt_job_params.
    ENDLOOP.

    " Create job and schedule via APJ
    create_and_schedule_job(
      iv_job_type      = 'S'             " Subscription
      iv_source_uuid   = iv_subscr_uuid
      iv_report_id     = ls_subscr-report_id
      iv_user_id       = ls_subscr-user_id
      iv_bukrs         = ls_subscr-bukrs
      iv_output_format = ls_subscr-output_format
      it_params        = lt_job_params
    ).
  ENDMETHOD.

  METHOD schedule_export.
    " Called by Export.execute action
    " Flow: Read EXPORT + parse param_json -> create_and_schedule_job
    " Read export record
    SELECT SINGLE * FROM zders_export
      WHERE export_uuid = @iv_export_uuid
      INTO @DATA(ls_export).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_ders_job_error
        EXPORTING
          textid  = zcx_ders_job_error=>export_not_found
          message = |Export UUID '{ iv_export_uuid }' not found|.
    ENDIF.

    " Read parameter definitions for this report
    SELECT * FROM zders_param
      WHERE report_id = @ls_export-report_id
      ORDER BY param_seq
      INTO TABLE @DATA(lt_param_defs).

    " Parse JSON -> structured parameters
    DATA lt_job_params TYPE STANDARD TABLE OF zders_job_param.

    IF ls_export-param_json IS NOT INITIAL.
      " Parse JSON key-value pairs
      " Expects format: {"BUKRS":"1000","GJAHR":"2026"}
      LOOP AT lt_param_defs INTO DATA(ls_def).
        " Search for this param's value in JSON
        DATA(lv_search) = |"{ ls_def-param_name }":"|.
        DATA(lv_pos) = find( val = ls_export-param_json sub = lv_search ).
        IF lv_pos >= 0.
          DATA(lv_start) = lv_pos + strlen( lv_search ).
          DATA(lv_end)   = find( val = ls_export-param_json off = lv_start sub = '"' ).
          IF lv_end > lv_start.
            DATA(lv_val) = substring( val = ls_export-param_json
                                      off = lv_start
                                      len = lv_end - lv_start ).
            APPEND VALUE #(
              item_no          = ls_def-param_seq
              param_name       = ls_def-param_name
              param_label      = ls_def-param_label
              param_value_from = lv_val
              param_type       = ls_def-param_type
              data_element     = ls_def-data_element
            ) TO lt_job_params.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " Create job and schedule via APJ
    create_and_schedule_job(
      iv_job_type      = 'O'             " One-time
      iv_source_uuid   = iv_export_uuid
      iv_report_id     = ls_export-report_id
      iv_user_id       = ls_export-user_id
      iv_bukrs         = ''
      iv_output_format = ls_export-output_format
      it_params        = lt_job_params
    ).

    " Update export status to Processing
    UPDATE zders_export
      SET status = 'P'
      WHERE export_uuid = @iv_export_uuid.
    " Note: No COMMIT - RAP framework handles transaction
  ENDMETHOD.

  METHOD create_and_schedule_job.
    " Core Logic: INSERT ZDERS_JOBHIST -> INSERT ZDERS_JOB_PARAM -> Call CL_APJ_RT_API=>SCHEDULE_JOB
    " Step 1: Create ZDERS_JOBHIST record
    DATA(lv_job_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
    DATA(lv_now) = VALUE timestampl( ).
    GET TIME STAMP FIELD lv_now.

    INSERT INTO zders_jobhist VALUES @( VALUE #(
      job_uuid           = lv_job_uuid
      job_type           = iv_job_type
      source_uuid        = iv_source_uuid
      report_id          = iv_report_id
      user_id            = iv_user_id
      bukrs              = iv_bukrs
      output_format      = iv_output_format
      status             = 'S'             " Scheduled
      scheduled_ts       = lv_now
      job_template_name  = c_job_template
      run_type           = 'I'             " Immediate
      start_immediately  = abap_true
      created_by         = sy-uname
      created_at         = lv_now
      last_changed_by    = sy-uname
      last_changed_at    = lv_now
      local_last_changed_at = lv_now
    ) ).

    " Step 2: Copy parameters into ZDERS_JOB_PARAM
    DATA lt_insert TYPE STANDARD TABLE OF zders_job_param.

    LOOP AT it_params ASSIGNING FIELD-SYMBOL(<ls_param>).
      DATA(lv_param_uuid) = cl_system_uuid=>create_uuid_x16_static( ).

      " Read fields dynamically (supports both typed and generic tables)
      DATA(lv_item_no)    = VALUE numc3( ).
      DATA(lv_name)       = VALUE fieldname( ).
      DATA(lv_label)      = VALUE scrtext_m( ).
      DATA(lv_from)       = VALUE char255( ).
      DATA(lv_to)         = VALUE char255( ).
      DATA(lv_type)       = VALUE char1( ).
      DATA(lv_de)         = VALUE rollname( ).

      ASSIGN COMPONENT 'ITEM_NO'          OF STRUCTURE <ls_param> TO FIELD-SYMBOL(<fv>).
      IF sy-subrc = 0. lv_item_no = <fv>. ENDIF.
      ASSIGN COMPONENT 'PARAM_NAME'       OF STRUCTURE <ls_param> TO <fv>.
      IF sy-subrc = 0. lv_name = <fv>. ENDIF.
      ASSIGN COMPONENT 'PARAM_LABEL'      OF STRUCTURE <ls_param> TO <fv>.
      IF sy-subrc = 0. lv_label = <fv>. ENDIF.
      ASSIGN COMPONENT 'PARAM_VALUE_FROM' OF STRUCTURE <ls_param> TO <fv>.
      IF sy-subrc = 0. lv_from = <fv>. ENDIF.
      ASSIGN COMPONENT 'PARAM_VALUE_TO'   OF STRUCTURE <ls_param> TO <fv>.
      IF sy-subrc = 0. lv_to = <fv>. ENDIF.
      ASSIGN COMPONENT 'PARAM_TYPE'       OF STRUCTURE <ls_param> TO <fv>.
      IF sy-subrc = 0. lv_type = <fv>. ENDIF.
      ASSIGN COMPONENT 'DATA_ELEMENT'     OF STRUCTURE <ls_param> TO <fv>.
      IF sy-subrc = 0. lv_de = <fv>. ENDIF.

      APPEND VALUE #(
        job_param_uuid   = lv_param_uuid
        parent_uuid      = lv_job_uuid
        item_no          = lv_item_no
        param_name       = lv_name
        param_label      = lv_label
        param_value_from = lv_from
        param_value_to   = lv_to
        param_type       = lv_type
        data_element     = lv_de
        created_by       = sy-uname
        created_at       = lv_now
        last_changed_by  = sy-uname
        last_changed_at  = lv_now
        local_last_changed_at = lv_now
      ) TO lt_insert.
    ENDLOOP.

    IF lt_insert IS NOT INITIAL.
      INSERT zders_job_param FROM TABLE @lt_insert.
    ENDIF.

    " Step 3: Call SAP Application Job API to schedule
    DATA lx_apj TYPE REF TO cx_apj_rt.
    DATA ls_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA lv_apj_jobname TYPE cl_apj_rt_api=>ty_jobname.
    DATA lv_apj_jobcount TYPE cl_apj_rt_api=>ty_jobcount.
    DATA lv_job_text TYPE cl_apj_rt_api=>ty_job_text.

    TRY.
        DATA lt_apj_params TYPE cl_apj_rt_api=>tt_job_parameter_value.
        DATA ls_apj_param  TYPE cl_apj_rt_api=>ty_job_parameter_value.
        DATA ls_value      TYPE cl_apj_rt_api=>ty_value_range.

        " Convert RAW16 UUID to hex string (32 chars lowercase)
        DATA(lv_uuid_hex) = CONV string( lv_job_uuid ).

        ls_apj_param-name = 'P_JOBUUI'.
        ls_value-sign   = 'I'.
        ls_value-option = 'EQ'.
        ls_value-low    = lv_uuid_hex.  " Pass as hex string
        APPEND ls_value TO ls_apj_param-t_value.
        APPEND ls_apj_param TO lt_apj_params.

        " DEBUG: Log what we're passing to APJ
        DATA(lv_debug) = |Scheduler passing: name={ ls_apj_param-name }, value={ lv_uuid_hex }, count={ lines( lt_apj_params ) }|.
        UPDATE zders_jobhist SET
          error_message = @lv_debug
          WHERE job_uuid = @lv_job_uuid.

        ls_start_info-start_immediately = abap_true.
        lv_job_text = 'DERS Background Job'.

        cl_apj_rt_api=>schedule_job(
          EXPORTING
            iv_job_template_name   = c_job_template
            iv_job_text            = lv_job_text
            it_job_parameter_value = lt_apj_params
            is_start_info          = ls_start_info
          IMPORTING
            ev_jobname  = lv_apj_jobname
            ev_jobcount = lv_apj_jobcount
        ).

        " Update jobhist with APJ job identification
        UPDATE zders_jobhist SET
          bg_job_name  = @lv_apj_jobname,
          bg_job_count = @lv_apj_jobcount
          WHERE job_uuid = @lv_job_uuid.

      CATCH cx_apj_rt INTO lx_apj.
        " APJ scheduling failed - mark job as failed but don't raise
        " (the JOBHIST record is still useful for debugging)
        DATA(lv_error_text) = lx_apj->get_text( ).
        UPDATE zders_jobhist SET
          status        = 'F',
          error_message = @lv_error_text
          WHERE job_uuid = @lv_job_uuid.
        " Note: No COMMIT - RAP framework handles transaction

        RAISE EXCEPTION TYPE zcx_ders_job_error
          EXPORTING
            textid  = zcx_ders_job_error=>scheduling_failed
              message = |APJ scheduling failed: { lx_apj->get_text( ) }|.
    ENDTRY.

    " Note: No COMMIT - RAP framework handles transaction when called from action
    rv_job_uuid = lv_job_uuid.
  ENDMETHOD.

  METHOD scan_due_subscriptions.
    " Periodic: Find all subscriptions where next_run_ts <= NOW and status = 'A'
    DATA(lv_now) = VALUE timestampl( ).
    GET TIME STAMP FIELD lv_now.

    " Find due subscriptions
    SELECT * FROM zders_subscr
      WHERE status     = 'A'
        AND next_run_ts <= @lv_now
      INTO TABLE @DATA(lt_due).

    rv_count = 0.

    LOOP AT lt_due INTO DATA(ls_subscr).
      TRY.
          " Schedule the subscription
          schedule_subscription( iv_subscr_uuid = ls_subscr-subscr_uuid ).

          " Calculate next_run_ts based on frequency
          DATA: lv_next_date TYPE sy-datum,
                lv_next_time TYPE sy-uzeit.
          lv_next_date = sy-datum.
          lv_next_time = ls_subscr-exec_time.

          CASE ls_subscr-frequency.
            WHEN 'D'.  " Daily -> tomorrow
              lv_next_date = lv_next_date + 1.
            WHEN 'W'.  " Weekly -> +7 days
              lv_next_date = lv_next_date + 7.
            WHEN 'M'.  " Monthly -> next month, same day
              DATA(lv_month) = CONV i( lv_next_date+4(2) ) + 1.
              DATA(lv_year)  = CONV i( lv_next_date(4) ).
              IF lv_month > 12.
                lv_month = 1.
                lv_year  = lv_year + 1.
              ENDIF.
              lv_next_date(4)  = |{ lv_year  WIDTH = 4 ALIGN = RIGHT PAD = '0' }|.
              lv_next_date+4(2) = |{ lv_month WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
              " Adjust exec_day
              DATA(lv_exec_day) = CONV i( ls_subscr-exec_day ).
              IF lv_exec_day > 0 AND lv_exec_day <= 31.
                lv_next_date+6(2) = |{ lv_exec_day WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
              ENDIF.
          ENDCASE.

          " Convert to timestamp
          DATA(lv_next_ts) = VALUE timestampl( ).
          DATA(lv_tz) = COND timezone( WHEN ls_subscr-tmzone IS INITIAL
                                       THEN 'UTC'
                                       ELSE ls_subscr-tmzone ).
          CONVERT DATE lv_next_date TIME lv_next_time
            INTO TIME STAMP lv_next_ts TIME ZONE lv_tz.

          " Update subscription: next run + run count
          UPDATE zders_subscr SET
            next_run_ts = @lv_next_ts,
            last_run_ts = @lv_now,
            run_count   = run_count + 1
            WHERE subscr_uuid = @ls_subscr-subscr_uuid.

          rv_count = rv_count + 1.

        CATCH zcx_ders_job_error INTO DATA(lx_err).
          " Log error but continue with other subscriptions
          CONTINUE.
      ENDTRY.
    ENDLOOP.

    IF rv_count > 0.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

