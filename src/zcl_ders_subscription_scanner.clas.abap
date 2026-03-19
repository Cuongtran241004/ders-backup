"!──────────────────────────────────────────────────────────────────────────────
"! CLASS: ZCL_DERS_SUBSCRIPTION_SCANNER
"! PURPOSE: Master polling job - scans ZDERS_SUBSCR for due subscriptions
"!          and triggers ZCL_DERS_JOB_SCHEDULER=>schedule_subscription for each.
"!
"! SETUP (one-time):
"!   Call ZCL_DERS_SUBSCRIPTION_SCANNER=>REGISTER_RECURRING_JOB from ADT (F9)
"!   or from SE38 → creates an APJ recurring hourly job automatically.
"!
"! FLOW:
"!   APJ triggers execute() every hour
"!   → scan_due_subscriptions()
"!      → SELECT zders_subscr WHERE status='A' AND next_run_ts <= NOW
"!      → schedule_subscription( subscr_uuid ) for each
"!      → UPDATE next_run_ts (today + frequency offset)
"!──────────────────────────────────────────────────────────────────────────────
CLASS zcl_ders_subscription_scanner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      if_apj_dt_exec_object,
      if_apj_rt_exec_object.

    CONSTANTS:
      c_scanner_template TYPE apj_job_template_name VALUE 'ZDERS_SCANNER_TEMPLATE'.

    "! One-time setup: create APJ recurring hourly job for this scanner.
    "! Call once from ADT (F9) or SE38 to register the master polling job.
    CLASS-METHODS register_recurring_job
      RAISING zcx_ders_job_error.

ENDCLASS.

CLASS zcl_ders_subscription_scanner IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    " No parameters needed - scanner reads ZDERS_SUBSCR directly
    et_parameter_def = VALUE #( ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    " Called by APJ (hourly recurring job)
    " Scan all subscriptions due for execution and schedule them
    DATA(lv_count) = zcl_ders_job_scheduler=>scan_due_subscriptions( ).

    " Log result to application log (visible in SLG1 under ZDERS)
    DATA lo_log TYPE REF TO if_bali_log.
    TRY.
        lo_log = cl_bali_log=>create_with_header(
          cl_bali_header_setter=>create(
            object    = 'ZDERS'
            subobject = 'SCANNER'
            external_id = CONV #( |SCAN_{ sy-uzeit }| )
          )
        ).

        lo_log->add_item( cl_bali_free_text_setter=>create(
          severity  = if_bali_constants=>c_severity_status
          text      = |DERS Scanner: Scheduled { lv_count } subscription(s) at { sy-datum } { sy-uzeit }|
        ) ).

        cl_bali_log_db=>get_instance( )->save_log(
          log               = lo_log
          assign_to_current_appl_job = abap_true
        ).
      CATCH cx_root.
        " Log failure is non-critical - continue silently
    ENDTRY.
  ENDMETHOD.

  METHOD register_recurring_job.
    " Register a recurring hourly APJ job using this scanner class.
    " This method should be called ONCE during system setup.
    " After that, APJ manages the recurrence automatically.

    DATA ls_start_info      TYPE cl_apj_rt_api=>ty_start_info.
    DATA ls_scheduling_info TYPE cl_apj_rt_api=>ty_scheduling_info.
    DATA ls_end_info        TYPE cl_apj_rt_api=>ty_end_info.
    DATA lv_jobname         TYPE cl_apj_rt_api=>ty_jobname.
    DATA lv_jobcount        TYPE cl_apj_rt_api=>ty_jobcount.

    " Start at current time (required for periodic — start_immediately does not work with scheduling_info)
    DATA lv_start_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_start_ts.
    ls_start_info-start_immediately = abap_false.
    ls_start_info-timestamp         = lv_start_ts.

    " Recurrence: every 1 hour
    ls_scheduling_info-periodic_granularity = 'H'.
    ls_scheduling_info-periodic_value       = 1.
    ls_scheduling_info-timezone             = 'UTC'.
    ls_scheduling_info-test_mode            = abap_false.

    " Run effectively forever (high iteration count — APJ requires a stop condition)
    ls_end_info-type           = 'NUM'.
    ls_end_info-max_iterations = 999999.

    TRY.
        cl_apj_rt_api=>schedule_job(
          EXPORTING
            iv_job_template_name   = c_scanner_template
            iv_job_text            = 'DERS Subscription Scanner (Hourly)'
            it_job_parameter_value = VALUE #( )  " No params needed
            is_start_info          = ls_start_info
            is_scheduling_info     = ls_scheduling_info
            is_end_info            = ls_end_info
          IMPORTING
            ev_jobname  = lv_jobname
            ev_jobcount = lv_jobcount
        ).

        WRITE: / |DERS Scanner registered successfully.|,
               / |  Job Name:  { lv_jobname }|,
               / |  Job Count: { lv_jobcount }|,
               / |  Frequency: Every 1 hour|,
               / |  Monitor via transaction JOBM or SM37|.

      CATCH cx_apj_rt INTO DATA(lx_apj).
        RAISE EXCEPTION TYPE zcx_ders_job_error
          EXPORTING
            textid  = zcx_ders_job_error=>scheduling_failed
            message = |Failed to register scanner: { lx_apj->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

