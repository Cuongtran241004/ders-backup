"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_jobhistory.clas.locals_def.incl
"!
"! BDEF: ZI_DERS_JobHistory (Separate BO - system-generated records)
"! JobHistory: Read-only + Actions (retry, cancelJob)
"! JobParam: Read-only child (snapshot, no direct behavior)
"!──────────────────────────────────────────────────────────────────────────────

"! Local Handler Class for JobHistory Entity
CLASS lhc_jobhistory DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      " Retry a failed job - creates new job with same parameters
      retry FOR MODIFY
        IMPORTING keys FOR ACTION JobHistory~retry RESULT result,

      " Cancel a running/scheduled job
      cancelJob FOR MODIFY
        IMPORTING keys FOR ACTION JobHistory~cancelJob RESULT result,

      " Instance-level authorization
      get_instance_authorizations FOR INSTANCE AUTHORIZATION
        IMPORTING keys REQUEST requested_authorizations FOR JobHistory RESULT result,

      " Dynamic enable/disable of actions based on job status
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR JobHistory RESULT result.

ENDCLASS.


"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATIONS
"! File: zbp_i_ders_jobhistory.clas.locals_imp.incl
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_jobhistory IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: retry
  " Retry a failed job - creates a new job with same parameters
  "═══════════════════════════════════════════════════════════════════════════
  METHOD retry.
    READ ENTITIES OF zi_ders_jobhistory IN LOCAL MODE
      ENTITY JobHistory
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_jobs).

    LOOP AT lt_jobs ASSIGNING FIELD-SYMBOL(<fs_job>).
      " Can only retry failed jobs
      IF <fs_job>-Status <> 'F'.
        APPEND VALUE #( %tky = <fs_job>-%tky ) TO failed-jobhistory.
        APPEND VALUE #(
          %tky = <fs_job>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Can only retry failed jobs'
          )
        ) TO reported-jobhistory.
        CONTINUE.
      ENDIF.

      TRY.
          " ── Read original job's structured parameters ──
          SELECT * FROM zders_job_param
            WHERE parent_uuid = @<fs_job>-JobUuid
            ORDER BY item_no
            INTO TABLE @DATA(lt_old_params).

          " ── Create new job via scheduler (copies params + calls APJ) ──
          DATA(lv_new_uuid) = zcl_ders_job_scheduler=>create_and_schedule_job(
            iv_job_type      = <fs_job>-JobType
            iv_source_uuid   = <fs_job>-SourceUuid
            iv_report_id     = <fs_job>-ReportId
            iv_user_id       = sy-uname
            iv_bukrs         = <fs_job>-Bukrs
            iv_output_format = <fs_job>-OutputFormat
            it_params        = lt_old_params
          ).

          " ── Update retry metadata on new job ──
          DATA(lv_new_retry_count) = <fs_job>-RetryCount + 1.
          UPDATE zders_jobhist SET
            retry_of_job = @<fs_job>-JobUuid,
            retry_count  = @lv_new_retry_count
            WHERE job_uuid = @lv_new_uuid.

          APPEND VALUE #(
            %tky = <fs_job>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = |Retry scheduled for Job { <fs_job>-JobId }|
            )
          ) TO reported-jobhistory.

        CATCH zcx_ders_job_error INTO DATA(lx_error).
          APPEND VALUE #( %tky = <fs_job>-%tky ) TO failed-jobhistory.
          APPEND VALUE #(
            %tky = <fs_job>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = lx_error->get_text( )
            )
          ) TO reported-jobhistory.
      ENDTRY.
    ENDLOOP.

    result = VALUE #(
      FOR ls_job IN lt_jobs
      ( %tky   = ls_job-%tky
        %param = ls_job )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: cancelJob
  " Cancel a running/scheduled job
  "═══════════════════════════════════════════════════════════════════════════
  METHOD cancelJob.
    READ ENTITIES OF zi_ders_jobhistory IN LOCAL MODE
      ENTITY JobHistory
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_jobs).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_jobhistory\\JobHistory.

    LOOP AT lt_jobs ASSIGNING FIELD-SYMBOL(<fs_job>).
      " Can only cancel scheduled or running jobs
      IF <fs_job>-Status <> 'S' AND <fs_job>-Status <> 'R'.
        APPEND VALUE #( %tky = <fs_job>-%tky ) TO failed-jobhistory.
        APPEND VALUE #(
          %tky = <fs_job>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Can only cancel scheduled or running jobs'
          )
        ) TO reported-jobhistory.
        CONTINUE.
      ENDIF.

      " Update status to Cancelled
      APPEND VALUE #(
        %tky   = <fs_job>-%tky
        Status = 'X'  " Cancelled
        %control-Status = if_abap_behv=>mk-on
      ) TO lt_updates.

      APPEND VALUE #(
        %tky = <fs_job>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Job { <fs_job>-JobId } has been cancelled|
        )
      ) TO reported-jobhistory.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_jobhistory IN LOCAL MODE
        ENTITY JobHistory
          UPDATE FIELDS ( Status )
          WITH lt_updates
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).
    ENDIF.

    result = VALUE #(
      FOR ls_job IN lt_jobs
      ( %tky   = ls_job-%tky
        %param = ls_job )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_instance_authorizations (ENHANCED VERSION)
  " Check authorization by specific Activity codes:
  "   16 = Execute (retry/cancel actions)
  "   03 = Display (read job history)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_authorizations.
    " Constants for Activity codes
    CONSTANTS:
      lc_actvt_display TYPE char2 VALUE '03',
      lc_actvt_execute TYPE char2 VALUE '16'.

    READ ENTITIES OF zi_ders_jobhistory IN LOCAL MODE
      ENTITY JobHistory
        FIELDS ( UserId Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_jobs).

    LOOP AT lt_jobs ASSIGNING FIELD-SYMBOL(<fs_job>).
      " ─────────────────────────────────────────────────────────────────────
      " Ownership Check: User owns job → full access
      " ─────────────────────────────────────────────────────────────────────
      DATA(lv_is_owner) = xsdbool( <fs_job>-UserId = sy-uname ).

      IF lv_is_owner = abap_true.
        " Owner has full access to their own job history
        APPEND VALUE #(
          %tky = <fs_job>-%tky
          %action-retry = if_abap_behv=>auth-allowed
          %action-cancelJob = if_abap_behv=>auth-allowed
        ) TO result.
        CONTINUE.
      ENDIF.

      " ─────────────────────────────────────────────────────────────────────
      " Non-Owner Check: Check ZDERSCOMP by specific Activity
      " ─────────────────────────────────────────────────────────────────────

      " Check Execute authorization (ACTVT = 16) for job actions
      IF requested_authorizations-%action-retry = if_abap_behv=>mk-on OR
         requested_authorizations-%action-cancelJob = if_abap_behv=>mk-on.
        AUTHORITY-CHECK OBJECT 'ZDERSCOMP'
          ID 'BUKRS' FIELD <fs_job>-Bukrs
          ID 'ACTVT' FIELD lc_actvt_execute.

        DATA(lv_execute_auth) = COND #(
          WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      " Build and append result
      APPEND VALUE #(
        %tky = <fs_job>-%tky
        %action-retry = lv_execute_auth
        %action-cancelJob = lv_execute_auth
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  " Dynamic enable/disable of job actions based on status
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_jobhistory IN LOCAL MODE
      ENTITY JobHistory
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_jobs).

    LOOP AT lt_jobs ASSIGNING FIELD-SYMBOL(<fs_job>).
      APPEND VALUE #(
        %tky = <fs_job>-%tky

        " Retry: only enabled for Failed jobs
        %action-retry = COND #(
          WHEN <fs_job>-Status = 'F'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " CancelJob: only for Scheduled or Running
        %action-cancelJob = COND #(
          WHEN <fs_job>-Status = 'S' OR <fs_job>-Status = 'R'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
