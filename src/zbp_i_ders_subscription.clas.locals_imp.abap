"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_subscription.clas.locals_def.incl
"!
"! BDEF Type: Managed + Draft (per SAD Section 4.3 & 4.5)
"! NOTE: JobHistory is now a separate BO with its own BIMP (ZBP_I_DERS_JOBHISTORY)
"!──────────────────────────────────────────────────────────────────────────────

"! Local Handler Class for Subscription Entity
CLASS lhc_subscription DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    " Static table to track subscriptions that already had params created in this LUW
    " Prevents duplicate CBA calls when determination triggers multiple times
    CLASS-DATA: gt_params_created_for TYPE SORTED TABLE OF sysuuid_x16 WITH UNIQUE KEY table_line.

    METHODS:
      "!──────────────────────────────────────────────────────────────────────
      "! VALIDATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Validate report exists and is active
      validateReport FOR VALIDATE ON SAVE
        IMPORTING keys FOR Subscription~validateReport,

      "! Validate company code exists in T001
      validateCompanyCode FOR VALIDATE ON SAVE
        IMPORTING keys FOR Subscription~validateCompanyCode,

      "! Validate schedule configuration (exec day valid for frequency)
      validateSchedule FOR VALIDATE ON SAVE
        IMPORTING keys FOR Subscription~validateSchedule,

      "! Validate email format
      validateEmail FOR VALIDATE ON SAVE
        IMPORTING keys FOR Subscription~validateEmail,

      "! Validate user has permission to subscribe to this report
      validateReportPermission FOR VALIDATE ON SAVE
        IMPORTING keys FOR Subscription~validateReportPermission,

      "!──────────────────────────────────────────────────────────────────────
      "! DETERMINATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Set default values on create
      setDefaults FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Subscription~setDefaults,

      "! Set UserId to current user
      setUserId FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Subscription~setUserId,

      "! Calculate next run timestamp based on schedule
      calculateNextRun FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Subscription~calculateNextRun,

      "! Copy parameters from ZDERS_PARAM template when ReportId changes
      copyParamsFromTemplate FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Subscription~copyParamsFromTemplate,

      "!──────────────────────────────────────────────────────────────────────
      "! ACTIONS (Names match BDEF: resumeSubscription, cancelSubscription)
      "!──────────────────────────────────────────────────────────────────────

      "! Pause subscription (Status → 'P')
      pause FOR MODIFY
        IMPORTING keys FOR ACTION Subscription~pause RESULT result,

      "! Resume subscription (Status → 'A')
      resumeSubscription FOR MODIFY
        IMPORTING keys FOR ACTION Subscription~resumeSubscription RESULT result,

      "! Execute subscription immediately
      executeNow FOR MODIFY
        IMPORTING keys FOR ACTION Subscription~executeNow RESULT result,

      "! Cancel subscription (Status → 'D', soft delete)
      cancelSubscription FOR MODIFY
        IMPORTING keys FOR ACTION Subscription~cancelSubscription RESULT result,

      "! Create quick subscription with minimal parameters
      createQuickSubscription FOR MODIFY
        IMPORTING keys FOR ACTION Subscription~createQuickSubscription RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! AUTHORIZATION
      "!──────────────────────────────────────────────────────────────────────

      "! Instance-level authorization (user owns subscription OR is admin)
      get_instance_authorizations FOR INSTANCE AUTHORIZATION
        IMPORTING keys REQUEST requested_authorizations FOR Subscription RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! FEATURE CONTROL
      "!──────────────────────────────────────────────────────────────────────

      "! Dynamic enable/disable of actions based on status
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR Subscription RESULT result.

ENDCLASS.

"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATIONS
"! File: zbp_i_ders_subscription.clas.locals_imp.incl
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_subscription IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateReport
  " Check if report exists and is active in catalog
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateReport.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( ReportId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      IF <fs_subscr>-ReportId IS INITIAL.
        CONTINUE.  " Mandatory field validation handles this
      ENDIF.

      " Check if report exists and is active
      SELECT SINGLE is_active FROM zders_catalog
        WHERE report_id = @<fs_subscr>-ReportId
        INTO @DATA(lv_is_active).

      IF sy-subrc <> 0.
        " Report doesn't exist
        APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Report '{ <fs_subscr>-ReportId }' does not exist in catalog|
          )
          %element-ReportId = if_abap_behv=>mk-on
        ) TO reported-subscription.
      ELSEIF lv_is_active = abap_false.
        " Report exists but is inactive
        APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Report '{ <fs_subscr>-ReportId }' is not active|
          )
          %element-ReportId = if_abap_behv=>mk-on
        ) TO reported-subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateCompanyCode
  " Check if company code exists in T001
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateCompanyCode.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      IF <fs_subscr>-Bukrs IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check if company code exists
      SELECT SINGLE @abap_true FROM t001
        WHERE bukrs = @<fs_subscr>-Bukrs
        INTO @DATA(lv_exists).

      IF lv_exists = abap_false.
        APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Company code '{ <fs_subscr>-Bukrs }' does not exist|
          )
          %element-Bukrs = if_abap_behv=>mk-on
        ) TO reported-subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateSchedule
  " Validate schedule configuration based on frequency
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateSchedule.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Frequency ExecDay ExecTime )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      " Validate ExecDay based on Frequency
      CASE <fs_subscr>-Frequency.
        WHEN 'W'.  " Weekly - day must be 1-7 (Mon-Sun)
          DATA(lv_day) = CONV i( <fs_subscr>-ExecDay ).
          IF lv_day < 1 OR lv_day > 7.
            APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
            APPEND VALUE #(
              %tky = <fs_subscr>-%tky
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text     = 'Weekly execution day must be 1-7 (1=Monday, 7=Sunday)'
              )
              %element-ExecDay = if_abap_behv=>mk-on
            ) TO reported-subscription.
          ENDIF.

        WHEN 'M'.  " Monthly - day must be 1-31
          lv_day = CONV i( <fs_subscr>-ExecDay ).
          IF lv_day < 1 OR lv_day > 31.
            APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
            APPEND VALUE #(
              %tky = <fs_subscr>-%tky
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text     = 'Monthly execution day must be 1-31'
              )
              %element-ExecDay = if_abap_behv=>mk-on
            ) TO reported-subscription.
          ENDIF.

        WHEN 'D'.  " Daily - ExecDay not used
          " No validation needed for daily
      ENDCASE.

      " Validate time is provided
      IF <fs_subscr>-ExecTime IS INITIAL.
        APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Execution time is required'
          )
          %element-ExecTime = if_abap_behv=>mk-on
        ) TO reported-subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateEmail
  " Basic email format validation
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateEmail.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( EmailTo )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      IF <fs_subscr>-EmailTo IS NOT INITIAL.
        " Basic email format check (contains @)
        IF <fs_subscr>-EmailTo NS '@'.
          APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = |Invalid email format: '{ <fs_subscr>-EmailTo }'|
            )
            %element-EmailTo = if_abap_behv=>mk-on
          ) TO reported-subscription.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateReportPermission
  " Check if current user has permission to subscribe to this report
  " Looks up ZDERS_USER_PERM for user + report + company code
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateReportPermission.
    " Read subscriptions being created/updated
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( ReportId Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      " Skip if ReportId or Bukrs not yet provided
      IF <fs_subscr>-ReportId IS INITIAL OR <fs_subscr>-Bukrs IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check user has permission in ZDERS_USER_PERM
      SELECT SINGLE can_subscribe
        FROM zders_user_perm
        WHERE user_id   = @sy-uname
          AND report_id = @<fs_subscr>-ReportId
          AND bukrs     = @<fs_subscr>-Bukrs
          AND is_active = @abap_true
        INTO @DATA(lv_can_subscribe).

      IF sy-subrc <> 0.
        " No permission record found at all
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |You do not have permission to access report '{ <fs_subscr>-ReportId }' for company '{ <fs_subscr>-Bukrs }'|
          )
          %element-ReportId = if_abap_behv=>mk-on
        ) TO reported-subscription.

        APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.

      ELSEIF lv_can_subscribe <> abap_true.
        " Permission exists but can_subscribe is not granted
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |You do not have subscription permission for report '{ <fs_subscr>-ReportId }'. Contact your administrator.|
          )
          %element-ReportId = if_abap_behv=>mk-on
        ) TO reported-subscription.

        APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setDefaults
  " Set default values: Status='A', Timezone=system default
  " NOTE: Only updates when fields are actually INITIAL to avoid infinite loops
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaults.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Status Tmzone RunCount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_subscription\\Subscription.

    " Get system timezone
    DATA(lv_system_timezone) = CONV timezone( sy-zonlo ).
    IF lv_system_timezone IS INITIAL.
      lv_system_timezone = 'UTC'.
    ENDIF.

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      " Only update if at least one field needs defaulting
      DATA(lv_needs_update) = abap_false.
      IF <fs_subscr>-Status IS INITIAL OR
         <fs_subscr>-Tmzone IS INITIAL OR
         <fs_subscr>-RunCount IS INITIAL.
        lv_needs_update = abap_true.
      ENDIF.

      CHECK lv_needs_update = abap_true.

      APPEND VALUE #(
        %tky     = <fs_subscr>-%tky

        " Default Status = Active (only if initial)
        Status   = COND #( WHEN <fs_subscr>-Status IS INITIAL
                           THEN 'A'
                           ELSE <fs_subscr>-Status )

        " Default Timezone = system timezone (only if initial)
        Tmzone   = COND #( WHEN <fs_subscr>-Tmzone IS INITIAL
                           THEN lv_system_timezone
                           ELSE <fs_subscr>-Tmzone )

        " Default RunCount = 0 (only if initial)
        RunCount = COND #( WHEN <fs_subscr>-RunCount IS INITIAL
                           THEN 0
                           ELSE <fs_subscr>-RunCount )

        %control-Status   = if_abap_behv=>mk-on
        %control-Tmzone   = if_abap_behv=>mk-on
        %control-RunCount = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    " Only call MODIFY if there's something to update
    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status Tmzone RunCount )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setUserId
  " Automatically set UserId to current user on create
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setUserId.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( UserId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_subscription\\Subscription.

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>)
      WHERE UserId IS INITIAL.

      APPEND VALUE #(
        %tky   = <fs_subscr>-%tky
        UserId = sy-uname
        %control-UserId = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( UserId )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: calculateNextRun
  " Calculate next run timestamp based on schedule configuration
  " NOTE: Only updates if NextRunTs is INITIAL to avoid infinite loops
  "═══════════════════════════════════════════════════════════════════════════
  METHOD calculateNextRun.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Frequency ExecDay ExecTime Tmzone Status NextRunTs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_subscription\\Subscription.

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      " Only calculate for Active subscriptions with no NextRunTs yet
      IF <fs_subscr>-Status <> 'A'.
        CONTINUE.
      ENDIF.

      " Skip if NextRunTs already set (avoid infinite loop)
      IF <fs_subscr>-NextRunTs IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      " Skip if ExecTime not provided yet
      IF <fs_subscr>-ExecTime IS INITIAL.
        CONTINUE.
      ENDIF.

      " Calculate simple next run
      DATA: lv_date TYPE sy-datum,
            lv_time TYPE sy-uzeit.

      lv_date = sy-datum.
      lv_time = <fs_subscr>-ExecTime.

      " If time has passed today, schedule for tomorrow
      IF sy-uzeit >= <fs_subscr>-ExecTime.
        lv_date = lv_date + 1.
      ENDIF.

      " Convert to timestamp
      DATA(lv_next_run) = VALUE timestampl( ).
      DATA(lv_tz) = COND timezone( WHEN <fs_subscr>-Tmzone IS INITIAL
                                   THEN 'UTC'
                                   ELSE <fs_subscr>-Tmzone ).
      CONVERT DATE lv_date TIME lv_time
        INTO TIME STAMP lv_next_run TIME ZONE lv_tz.

      APPEND VALUE #(
        %tky      = <fs_subscr>-%tky
        NextRunTs = lv_next_run
        %control-NextRunTs = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( NextRunTs )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: copyParamsFromTemplate
  " When user selects Report, auto-populate parameter child records from ZDERS_PARAM
  " NOTE: Simplified version - creates params on new subscription only
  "═══════════════════════════════════════════════════════════════════════════
  METHOD copyParamsFromTemplate.
    " DEBUG: Log entry point
    DATA(lv_debug) = abap_true.  " Set to abap_false to disable debug messages

    " Read modified subscriptions with their existing params
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( ReportId SubscrUuid )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions)
      ENTITY Subscription BY \_Params
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_params).

    " DEBUG: Log how many subscriptions received
    IF lv_debug = abap_true.
      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-information
          text     = |DEBUG: copyParams triggered. Subscriptions: { lines( lt_subscriptions ) }, ExistingParams: { lines( lt_existing_params ) }|
        )
      ) TO reported-subscription.
    ENDIF.

    " For each subscription with ReportId
    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>)
         WHERE ReportId IS NOT INITIAL.

      " DEBUG: Log ReportId being processed
      IF lv_debug = abap_true.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-information
            text     = |DEBUG: Processing ReportId='{ <fs_subscr>-ReportId }', UUID='{ <fs_subscr>-SubscrUuid }', IsDraft='{ <fs_subscr>-%is_draft }'|
          )
        ) TO reported-subscription.
      ENDIF.

      " Skip if we already created params for this subscription in this LUW
      " (determination can be triggered multiple times)
      IF line_exists( gt_params_created_for[ table_line = <fs_subscr>-SubscrUuid ] ).
        IF lv_debug = abap_true.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-warning
              text     = |DEBUG: SKIPPED - Already processed this UUID in current LUW|
            )
          ) TO reported-subscription.
        ENDIF.
        CONTINUE.
      ENDIF.

      " Skip if params already exist (avoid recreating on every update)
      DATA(lv_has_params) = xsdbool(
        line_exists( lt_existing_params[ SubscrUuid = <fs_subscr>-SubscrUuid ] )
      ).
      IF lv_has_params = abap_true.
        IF lv_debug = abap_true.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-warning
              text     = |DEBUG: SKIPPED - Params already exist for this subscription|
            )
          ) TO reported-subscription.
        ENDIF.
        CONTINUE.
      ENDIF.

      " Read parameter template from ZDERS_PARAM
      SELECT FROM zders_param
        FIELDS param_seq,
               param_name,
               data_element,
               is_mandatory,
               default_value
        WHERE report_id = @<fs_subscr>-ReportId
        ORDER BY param_seq
        INTO TABLE @DATA(lt_param_template).

      " DEBUG: Log template query result
      IF lv_debug = abap_true.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-information
            text     = |DEBUG: ZDERS_PARAM query for '{ <fs_subscr>-ReportId }' returned { lines( lt_param_template ) } rows (sy-subrc={ sy-subrc })|
          )
        ) TO reported-subscription.

        " Log the actual ParamSeq values
        DATA(lv_seqs) = ||.
        LOOP AT lt_param_template ASSIGNING FIELD-SYMBOL(<ls_debug_tmpl>).
          lv_seqs = |{ lv_seqs }{ <ls_debug_tmpl>-param_seq },|.
        ENDLOOP.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-information
            text     = |DEBUG: ParamSeq values from template: { lv_seqs }|
          )
        ) TO reported-subscription.
      ENDIF.

      " Check for existing draft params (might be left over from previous attempt)
      DATA lv_draft_count TYPE i.
      SELECT COUNT(*) FROM zders_d_sub_prm
        WHERE subscruuid = @<fs_subscr>-SubscrUuid
        INTO @lv_draft_count.
      IF lv_draft_count > 0.
        IF lv_debug = abap_true.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-warning
              text     = |DEBUG: Found { lv_draft_count } existing draft param records in ZDERS_D_SUB_PRM!|
            )
          ) TO reported-subscription.
        ENDIF.
        " Skip - params already exist in draft table
        CONTINUE.
      ENDIF.

      " DEBUG: Check template before creating
      IF lv_debug = abap_true.
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-information
            text     = |DEBUG: Template check - lines={ lines( lt_param_template ) }, DraftCnt={ lv_draft_count }|
          )
        ) TO reported-subscription.
      ENDIF.

      " Use lines() instead of sy-subrc to check template
      IF lines( lt_param_template ) > 0.
        " Build CBA table - ONE entry per parent, ALL targets at once
        DATA lt_param_create TYPE TABLE FOR CREATE zi_ders_subscription\_Params.
        DATA lv_idx TYPE i.

        lv_idx = 0.

        " One CBA entry for this subscription
        APPEND INITIAL LINE TO lt_param_create ASSIGNING FIELD-SYMBOL(<ls_cba>).
        <ls_cba>-%tky-SubscrUuid = <fs_subscr>-SubscrUuid.
        <ls_cba>-%tky-%is_draft = <fs_subscr>-%is_draft.  " Also set %is_draft in %tky
        <ls_cba>-%is_draft = <fs_subscr>-%is_draft.

        " All targets at once - one per param template
        LOOP AT lt_param_template ASSIGNING FIELD-SYMBOL(<ls_tmpl>).
          lv_idx = lv_idx + 1.

          APPEND INITIAL LINE TO <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_target>).
          " Keep draft/activity consistent for all target rows
          <ls_target>-%cid            = <ls_tmpl>-param_seq.
          <ls_target>-%is_draft       = <fs_subscr>-%is_draft.
          <ls_target>-ParamSeq        = <ls_tmpl>-param_seq.     " Child key
          <ls_target>-ParamName       = <ls_tmpl>-param_name.
          <ls_target>-DataElement     = <ls_tmpl>-data_element.
          <ls_target>-IsMandatory     = <ls_tmpl>-is_mandatory.
          <ls_target>-DefaultValue    = <ls_tmpl>-default_value.
          <ls_target>-ParamValue      = <ls_tmpl>-default_value.
          <ls_target>-%control-ParamSeq     = if_abap_behv=>mk-on.
          <ls_target>-%control-ParamName    = if_abap_behv=>mk-on.
          <ls_target>-%control-DataElement  = if_abap_behv=>mk-on.
          <ls_target>-%control-IsMandatory  = if_abap_behv=>mk-on.
          <ls_target>-%control-DefaultValue = if_abap_behv=>mk-on.
          <ls_target>-%control-ParamValue   = if_abap_behv=>mk-on.

          " DEBUG: Log each param
          IF lv_debug = abap_true.
            APPEND VALUE #(
              %tky = <fs_subscr>-%tky
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = |DEBUG: Target { lv_idx }: Seq={ <ls_tmpl>-param_seq }, Name={ <ls_tmpl>-param_name }|
              )
            ) TO reported-subscription.
          ENDIF.
        ENDLOOP.

        " DEBUG: Log CBA structure before call
        IF lv_debug = abap_true.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-information
              text     = |DEBUG: CBA has { lines( lt_param_create ) } entries, targets={ lines( <ls_cba>-%target ) }|
            )
          ) TO reported-subscription.
        ENDIF.

        " Create ALL params in ONE MODIFY call
        MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
          ENTITY Subscription
            CREATE BY \_Params
            FROM lt_param_create
          MAPPED DATA(lt_mapped)
          FAILED DATA(lt_failed)
          REPORTED DATA(lt_reported).

        " Mark this subscription as processed (prevent duplicate calls)
        INSERT <fs_subscr>-SubscrUuid INTO TABLE gt_params_created_for.

        " DEBUG: Log result
        IF lv_debug = abap_true.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = COND #( WHEN lt_failed-subscriptionparam IS INITIAL
                                 THEN if_abap_behv_message=>severity-success
                                 ELSE if_abap_behv_message=>severity-error )
              text     = |DEBUG: CBA result - Mapped={ lines( lt_mapped-subscriptionparam ) }, Failed={ lines( lt_failed-subscriptionparam ) }|
            )
          ) TO reported-subscription.

          " Log each failed param
          LOOP AT lt_failed-subscriptionparam ASSIGNING FIELD-SYMBOL(<ls_fail>).
            APPEND VALUE #(
              %tky = <fs_subscr>-%tky
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text     = |DEBUG FAIL: CID={ <ls_fail>-%cid }, Cause={ <ls_fail>-%fail-cause }|
              )
            ) TO reported-subscription.
          ENDLOOP.

          " Log error messages
          LOOP AT lt_reported-subscriptionparam ASSIGNING FIELD-SYMBOL(<ls_rep>).
            IF <ls_rep>-%msg IS BOUND.
              APPEND VALUE #(
                %tky = <fs_subscr>-%tky
                %msg = <ls_rep>-%msg
              ) TO reported-subscription.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ELSE.
        " DEBUG: No template found
        IF lv_debug = abap_true.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-warning
              text     = |DEBUG: NO PARAMS in ZDERS_PARAM for report '{ <fs_subscr>-ReportId }'|
            )
          ) TO reported-subscription.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: pause
  " Pause subscription - stops scheduled execution
  "═══════════════════════════════════════════════════════════════════════════
  METHOD pause.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    " Update status to Paused
    MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          FOR ls_subscr IN lt_subscriptions
          ( %tky   = ls_subscr-%tky
            Status = 'P'  " Paused
            %control-Status = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      APPEND VALUE #(
        %tky = <fs_subscr>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Subscription '{ <fs_subscr>-SubscrName }' has been paused|
        )
      ) TO reported-subscription.
    ENDLOOP.

    result = VALUE #(
      FOR ls_subscr IN lt_subscriptions
      ( %tky   = ls_subscr-%tky
        %param = ls_subscr )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: resumeSubscription
  " Resume paused subscription - recalculates next run
  "═══════════════════════════════════════════════════════════════════════════
  METHOD resumeSubscription.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_subscription\\Subscription.

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      " Calculate new next run timestamp
      DATA: lv_date TYPE sy-datum,
            lv_time TYPE sy-uzeit.

      lv_date = sy-datum.
      lv_time = <fs_subscr>-ExecTime.

      IF sy-uzeit >= <fs_subscr>-ExecTime.
        lv_date = lv_date + 1.
      ENDIF.

      DATA(lv_next_run) = VALUE timestampl( ).
      CONVERT DATE lv_date TIME lv_time
        INTO TIME STAMP lv_next_run TIME ZONE <fs_subscr>-Tmzone.

      APPEND VALUE #(
        %tky      = <fs_subscr>-%tky
        Status    = 'A'  " Active
        NextRunTs = lv_next_run
        %control-Status    = if_abap_behv=>mk-on
        %control-NextRunTs = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        UPDATE FIELDS ( Status NextRunTs )
        WITH lt_updates
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_subscriptions ASSIGNING <fs_subscr>.
      APPEND VALUE #(
        %tky = <fs_subscr>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Subscription '{ <fs_subscr>-SubscrName }' has been resumed|
        )
      ) TO reported-subscription.
    ENDLOOP.

    result = VALUE #(
      FOR ls_subscr IN lt_subscriptions
      ( %tky   = ls_subscr-%tky
        %param = ls_subscr )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: executeNow
  " Execute subscription immediately - creates a one-time job
  " NOTE: For demo - just shows success message
  "       Full implementation would use ZCL_DERS_JOB_SCHEDULER
  "═══════════════════════════════════════════════════════════════════════════
  METHOD executeNow.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      TRY.
          " ── Call Job Scheduler ──
          " Creates ZDERS_JOBHIST + copies ZDERS_SUB_PARAM → ZDERS_JOB_PARAM
          " Then calls CL_APJ_RT_API=>SCHEDULE_JOB
          zcl_ders_job_scheduler=>schedule_subscription(
            iv_subscr_uuid = <fs_subscr>-SubscrUuid
          ).

          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = |Job scheduled successfully for '{ <fs_subscr>-SubscrName }'|
            )
          ) TO reported-subscription.

        CATCH zcx_ders_job_error INTO DATA(lx_error).
          APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-subscription.
          APPEND VALUE #(
            %tky = <fs_subscr>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = lx_error->get_text( )
            )
          ) TO reported-subscription.
      ENDTRY.
    ENDLOOP.

    result = VALUE #(
      FOR ls_subscr IN lt_subscriptions
      ( %tky   = ls_subscr-%tky
        %param = ls_subscr )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: cancelSubscription
  " Cancel subscription - soft delete (Status → 'D')
  "═══════════════════════════════════════════════════════════════════════════
  METHOD cancelSubscription.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    " Update status to Deleted
    MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          FOR ls_subscr IN lt_subscriptions
          ( %tky   = ls_subscr-%tky
            Status = 'D'  " Deleted
            %control-Status = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      APPEND VALUE #(
        %tky = <fs_subscr>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Subscription '{ <fs_subscr>-SubscrName }' has been cancelled|
        )
      ) TO reported-subscription.
    ENDLOOP.

    result = VALUE #(
      FOR ls_subscr IN lt_subscriptions
      ( %tky   = ls_subscr-%tky
        %param = ls_subscr )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: createQuickSubscription (Static)
  " Create subscription with minimal parameters
  "═══════════════════════════════════════════════════════════════════════════
  METHOD createQuickSubscription.
    DATA lt_creates TYPE TABLE FOR CREATE zi_ders_subscription\\Subscription.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      " NOTE: SubscrUuid is managed numbering - RAP generates it automatically
      APPEND VALUE #(
        %cid          = <fs_key>-%cid
        UserId        = sy-uname
        SubscrName    = <fs_key>-%param-SubscrName
        ReportId      = <fs_key>-%param-ReportId
        Bukrs         = <fs_key>-%param-Bukrs
        OutputFormat  = <fs_key>-%param-OutputFormat
        Frequency     = <fs_key>-%param-Frequency
        ExecTime      = <fs_key>-%param-ExecTime
        EmailTo       = <fs_key>-%param-EmailTo
        Status        = 'A'  " Active
        %control      = VALUE #(
          UserId        = if_abap_behv=>mk-on
          SubscrName    = if_abap_behv=>mk-on
          ReportId      = if_abap_behv=>mk-on
          Bukrs         = if_abap_behv=>mk-on
          OutputFormat  = if_abap_behv=>mk-on
          Frequency     = if_abap_behv=>mk-on
          ExecTime      = if_abap_behv=>mk-on
          EmailTo       = if_abap_behv=>mk-on
          Status        = if_abap_behv=>mk-on
        )
      ) TO lt_creates.
    ENDLOOP.

    " Create subscriptions
    MODIFY ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        CREATE FIELDS (
          UserId SubscrName ReportId Bukrs
          OutputFormat Frequency ExecTime EmailTo Status
        )
        WITH lt_creates
      MAPPED DATA(lt_mapped)
      FAILED failed
      REPORTED reported.

    result = VALUE #(
      FOR ls_mapped IN lt_mapped-subscription
      ( %cid = ls_mapped-%cid )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_instance_authorizations (ENHANCED VERSION)
  " Check authorization by specific Activity codes:
  "   03 = Display (read)
  "   02 = Change (update)
  "   06 = Delete
  "   16 = Execute (actions)
  "   01 = Create (for CBA - handled separately)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_authorizations.
    " Constants for Activity codes
    CONSTANTS:
      lc_actvt_display TYPE char2 VALUE '03',
      lc_actvt_change  TYPE char2 VALUE '02',
      lc_actvt_delete  TYPE char2 VALUE '06',
      lc_actvt_execute TYPE char2 VALUE '16'.

    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( UserId Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      " ─────────────────────────────────────────────────────────────────────
      " Ownership Check: User owns subscription → full access
      " ─────────────────────────────────────────────────────────────────────
      DATA(lv_is_owner) = xsdbool( <fs_subscr>-UserId = sy-uname ).

      IF lv_is_owner = abap_true.
        " Owner has full access to their own subscriptions
        APPEND VALUE #(
          %tky = <fs_subscr>-%tky
          %update = if_abap_behv=>auth-allowed
          %delete = if_abap_behv=>auth-allowed
          %action-pause = if_abap_behv=>auth-allowed
          %action-resumeSubscription = if_abap_behv=>auth-allowed
          %action-executeNow = if_abap_behv=>auth-allowed
          %action-cancelSubscription = if_abap_behv=>auth-allowed
        ) TO result.
        CONTINUE.
      ENDIF.

      " ─────────────────────────────────────────────────────────────────────
      " Non-Owner Check: Check ZDERSCOMP by specific Activity
      " ─────────────────────────────────────────────────────────────────────

      " Check Update authorization (ACTVT = 02)
      IF requested_authorizations-%update = if_abap_behv=>mk-on.
        AUTHORITY-CHECK OBJECT 'ZDERSCOMP'
          ID 'BUKRS' FIELD <fs_subscr>-Bukrs
          ID 'ACTVT' FIELD lc_actvt_change.
        DATA(lv_update_auth) = COND #(
          WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      " Check Delete authorization (ACTVT = 06)
      IF requested_authorizations-%delete = if_abap_behv=>mk-on.
        AUTHORITY-CHECK OBJECT 'ZDERSCOMP'
          ID 'BUKRS' FIELD <fs_subscr>-Bukrs
          ID 'ACTVT' FIELD lc_actvt_delete.
        DATA(lv_delete_auth) = COND #(
          WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      " Check Execute authorization (ACTVT = 16) for actions
      IF requested_authorizations-%action-pause = if_abap_behv=>mk-on OR
         requested_authorizations-%action-resumeSubscription = if_abap_behv=>mk-on OR
         requested_authorizations-%action-executeNow = if_abap_behv=>mk-on.
        AUTHORITY-CHECK OBJECT 'ZDERSCOMP'
          ID 'BUKRS' FIELD <fs_subscr>-Bukrs
          ID 'ACTVT' FIELD lc_actvt_execute.
        DATA(lv_execute_auth) = COND #(
          WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      " Check Cancel authorization (ACTVT = 06 - same as delete)
      IF requested_authorizations-%action-cancelSubscription = if_abap_behv=>mk-on.
        AUTHORITY-CHECK OBJECT 'ZDERSCOMP'
          ID 'BUKRS' FIELD <fs_subscr>-Bukrs
          ID 'ACTVT' FIELD lc_actvt_delete.
        DATA(lv_cancel_auth) = COND #(
          WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      " Build and append result
      APPEND VALUE #(
        %tky = <fs_subscr>-%tky
        %update = lv_update_auth
        %delete = lv_delete_auth
        %action-pause = lv_execute_auth
        %action-resumeSubscription = lv_execute_auth
        %action-executeNow = lv_execute_auth
        %action-cancelSubscription = lv_cancel_auth
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  " Dynamic enable/disable of actions based on status
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_subscription IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).

    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      APPEND VALUE #(
        %tky = <fs_subscr>-%tky

        " Pause: only enabled for Active subscriptions
        %action-pause = COND #(
          WHEN <fs_subscr>-Status = 'A'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " Resume: only enabled for Paused subscriptions
        %action-resumeSubscription = COND #(
          WHEN <fs_subscr>-Status = 'P'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " ExecuteNow: enabled for Active or Paused
        %action-executeNow = COND #(
          WHEN <fs_subscr>-Status = 'A' OR <fs_subscr>-Status = 'P'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " Cancel: disabled for already Deleted
        %action-cancelSubscription = COND #(
          WHEN <fs_subscr>-Status = 'D'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

" NOTE: JobHistory handler moved to separate BIMP: ZBP_I_DERS_JOBHISTORY
" See: zbp_i_ders_jobhistory.clas.locals_imp.incl
