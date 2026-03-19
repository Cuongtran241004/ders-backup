"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_export.clas.locals_def.incl
"!
"! BDEF Type: Managed WITHOUT Draft (per SAD Section 4.5.2)
"! Rationale: Export is a simple "create and submit" operation.
"!            No need to save incomplete state - users submit immediately.
"!──────────────────────────────────────────────────────────────────────────────

"! Local Handler Class for Export Entity
CLASS lhc_export DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      "!──────────────────────────────────────────────────────────────────────
      "! VALIDATIONS
      "!──────────────────────────────────────────────────────────────────────

      validateReport FOR VALIDATE ON SAVE
        IMPORTING keys FOR Export~validateReport,

      validateFormat FOR VALIDATE ON SAVE
        IMPORTING keys FOR Export~validateFormat,

      validateEmail FOR VALIDATE ON SAVE
        IMPORTING keys FOR Export~validateEmail,

      "!──────────────────────────────────────────────────────────────────────
      "! DETERMINATIONS
      "!──────────────────────────────────────────────────────────────────────

      setDefaults FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Export~setDefaults,

      setUserId FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Export~setUserId,

      "! Generate ExportId on SAVE (not modify) to ensure uniqueness
      generateExportId FOR DETERMINE ON SAVE
        IMPORTING keys FOR Export~generateExportId,

      "!──────────────────────────────────────────────────────────────────────
      "! ACTIONS
      "!──────────────────────────────────────────────────────────────────────

      execute FOR MODIFY
        IMPORTING keys FOR ACTION Export~execute RESULT result,

      cancel FOR MODIFY
        IMPORTING keys FOR ACTION Export~cancel RESULT result,

      download FOR MODIFY
        IMPORTING keys FOR ACTION Export~download RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! AUTHORIZATION & FEATURE CONTROL
      "!──────────────────────────────────────────────────────────────────────

      get_instance_authorizations FOR INSTANCE AUTHORIZATION
        IMPORTING keys REQUEST requested_authorizations FOR Export RESULT result,

      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR Export RESULT result.

ENDCLASS.

"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATIONS
"! File: zbp_i_ders_export.clas.locals_imp.incl
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_export IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateReport
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateReport.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( ReportId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      IF <fs_export>-ReportId IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check if report exists and is active
      SELECT SINGLE is_active FROM zders_catalog
        WHERE report_id = @<fs_export>-ReportId
        INTO @DATA(lv_is_active).

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <fs_export>-%tky ) TO failed-export.
        APPEND VALUE #(
          %tky = <fs_export>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Report '{ <fs_export>-ReportId }' does not exist|
          )
          %element-ReportId = if_abap_behv=>mk-on
        ) TO reported-export.
      ELSEIF lv_is_active = abap_false.
        APPEND VALUE #( %tky = <fs_export>-%tky ) TO failed-export.
        APPEND VALUE #(
          %tky = <fs_export>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Report '{ <fs_export>-ReportId }' is not active|
          )
          %element-ReportId = if_abap_behv=>mk-on
        ) TO reported-export.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateFormat
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateFormat.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( OutputFormat ReportId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      IF <fs_export>-OutputFormat IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check if format is supported by the report
      SELECT SINGLE supported_formats FROM zders_catalog
        WHERE report_id = @<fs_export>-ReportId
        INTO @DATA(lv_supported).

      IF sy-subrc = 0 AND lv_supported IS NOT INITIAL.
        IF lv_supported NS <fs_export>-OutputFormat.
          APPEND VALUE #( %tky = <fs_export>-%tky ) TO failed-export.
          APPEND VALUE #(
            %tky = <fs_export>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = |Format '{ <fs_export>-OutputFormat }' not supported. Available: { lv_supported }|
            )
            %element-OutputFormat = if_abap_behv=>mk-on
          ) TO reported-export.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateEmail
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateEmail.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( SendEmail EmailTo )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      " If SendEmail is checked, EmailTo must be provided
      IF <fs_export>-SendEmail = abap_true AND <fs_export>-EmailTo IS INITIAL.
        APPEND VALUE #( %tky = <fs_export>-%tky ) TO failed-export.
        APPEND VALUE #(
          %tky = <fs_export>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Email address is required when Send Email is enabled'
          )
          %element-EmailTo = if_abap_behv=>mk-on
        ) TO reported-export.
      ENDIF.

      " Basic email format validation
      IF <fs_export>-EmailTo IS NOT INITIAL AND <fs_export>-EmailTo NS '@'.
        APPEND VALUE #( %tky = <fs_export>-%tky ) TO failed-export.
        APPEND VALUE #(
          %tky = <fs_export>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Invalid email format: '{ <fs_export>-EmailTo }'|
          )
          %element-EmailTo = if_abap_behv=>mk-on
        ) TO reported-export.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setDefaults
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaults.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( Status SendEmail OutputFormat )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_export\\Export.

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      APPEND VALUE #(
        %tky         = <fs_export>-%tky
        Status       = COND #( WHEN <fs_export>-Status IS INITIAL
                               THEN 'A'
                               ELSE <fs_export>-Status )
        SendEmail    = COND #( WHEN <fs_export>-SendEmail IS INITIAL
                               THEN abap_false
                               ELSE <fs_export>-SendEmail )
        OutputFormat = COND #( WHEN <fs_export>-OutputFormat IS INITIAL
                               THEN 'XLSX'
                               ELSE <fs_export>-OutputFormat )
        %control-Status       = if_abap_behv=>mk-on
        %control-SendEmail    = if_abap_behv=>mk-on
        %control-OutputFormat = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        UPDATE FIELDS ( Status SendEmail OutputFormat )
        WITH lt_updates
      REPORTED DATA(lt_reported).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setUserId
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setUserId.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( UserId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_export\\Export.

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>)
      WHERE UserId IS INITIAL.

      APPEND VALUE #(
        %tky   = <fs_export>-%tky
        UserId = sy-uname
        %control-UserId = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_export IN LOCAL MODE
        ENTITY Export
          UPDATE FIELDS ( UserId )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: generateExportId
  " Generate readable export ID: EXP-YYYYMMDD-NNNN
  "═══════════════════════════════════════════════════════════════════════════
  METHOD generateExportId.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( ExportId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_export\\Export.

    " Get today's date string
    DATA(lv_date_str) = |{ sy-datum }|.

    " Prepare search pattern and counter variable
    DATA(lv_pattern) = |EXP-{ lv_date_str }-%|.
    DATA lv_count TYPE i.

    " Get next sequence number for today
    SELECT COUNT(*) FROM zders_export
      WHERE export_id LIKE @lv_pattern
      INTO @lv_count.

    DATA(lv_seq) = lv_count + 1.

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>)
      WHERE ExportId IS INITIAL.

      APPEND VALUE #(
        %tky     = <fs_export>-%tky
        ExportId = |EXP-{ lv_date_str }-{ lv_seq WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
        %control-ExportId = if_abap_behv=>mk-on
      ) TO lt_updates.

      lv_seq = lv_seq + 1.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_export IN LOCAL MODE
        ENTITY Export
          UPDATE FIELDS ( ExportId )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: execute
  " Execute export immediately
  "═══════════════════════════════════════════════════════════════════════════
  METHOD execute.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      TRY.
          " TODO: Call report generator
          " DATA(lo_generator) = NEW zcl_ders_report_generator( ).
          " lo_generator->generate(
          "   iv_report_id     = <fs_export>-ReportId
          "   iv_output_format = <fs_export>-OutputFormat
          "   iv_param_json    = <fs_export>-ParamJson
          " ).

          APPEND VALUE #(
            %tky = <fs_export>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = |Export '{ <fs_export>-ExportId }' started successfully|
            )
          ) TO reported-export.

        CATCH cx_root INTO DATA(lx_error).
          APPEND VALUE #( %tky = <fs_export>-%tky ) TO failed-export.
          APPEND VALUE #(
            %tky = <fs_export>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = lx_error->get_text( )
            )
          ) TO reported-export.
      ENDTRY.
    ENDLOOP.

    result = VALUE #(
      FOR ls_export IN lt_exports
      ( %tky   = ls_export-%tky
        %param = ls_export )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: cancel
  "═══════════════════════════════════════════════════════════════════════════
  METHOD cancel.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    MODIFY ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          FOR ls_export IN lt_exports
          ( %tky   = ls_export-%tky
            Status = 'D'
            %control-Status = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    result = VALUE #(
      FOR ls_export IN lt_exports
      ( %tky   = ls_export-%tky
        %param = ls_export )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: download
  " Download generated file
  "═══════════════════════════════════════════════════════════════════════════
  METHOD download.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      " TODO: Implement file download logic
      " This would typically return file content via a dedicated entity

      APPEND VALUE #(
        %tky = <fs_export>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-information
          text     = |Download initiated for '{ <fs_export>-ExportId }'|
        )
      ) TO reported-export.
    ENDLOOP.

    result = VALUE #(
      FOR ls_export IN lt_exports
      ( %tky   = ls_export-%tky
        %param = ls_export )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_instance_authorizations
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_authorizations.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( UserId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      " User can manage their own exports
      DATA(lv_authorized) = COND #(
        WHEN <fs_export>-UserId = sy-uname THEN abap_true
        ELSE abap_false
      ).

      APPEND VALUE #(
        %tky = <fs_export>-%tky
        %update = COND #(
          WHEN lv_authorized = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized
        )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_export IN LOCAL MODE
      ENTITY Export
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exports).

    LOOP AT lt_exports ASSIGNING FIELD-SYMBOL(<fs_export>).
      APPEND VALUE #(
        %tky = <fs_export>-%tky

        " Execute: only for Active exports
        %action-execute = COND #(
          WHEN <fs_export>-Status = 'A'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " Cancel: not for already deleted
        %action-cancel = COND #(
          WHEN <fs_export>-Status = 'D'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

        " Download: only when completed (would need status check)
        %action-download = if_abap_behv=>fc-o-enabled

      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
