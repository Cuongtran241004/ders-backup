"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_userassign.clas.locals_def.incl
"!
"! BDEF Type: Managed + Draft (Admin-only)
"! Authorization: Global (Z_DERS_ADM)
"!──────────────────────────────────────────────────────────────────────────────

"! Local Handler Class for UserAssign Entity
CLASS lhc_userassign DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS:
      "!──────────────────────────────────────────────────────────────────────
      "! AUTHORIZATION
      "!──────────────────────────────────────────────────────────────────────

      "! Global authorization check (admin only)
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR UserAssign RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! DETERMINATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Set default values on create
      setDefaults FOR DETERMINE ON MODIFY
        IMPORTING keys FOR UserAssign~setDefaults,

      "!──────────────────────────────────────────────────────────────────────
      "! VALIDATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Validate user exists in SAP
      validateUser FOR VALIDATE ON SAVE
        IMPORTING keys FOR UserAssign~validateUser,

      "! Validate company code exists in T001
      validateCompanyCode FOR VALIDATE ON SAVE
        IMPORTING keys FOR UserAssign~validateCompanyCode,

      "!──────────────────────────────────────────────────────────────────────
      "! ACTIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Deactivate user assignment
      deactivate FOR MODIFY
        IMPORTING keys FOR ACTION UserAssign~deactivate RESULT result,

      "! Reactivate user assignment
      reactivate FOR MODIFY
        IMPORTING keys FOR ACTION UserAssign~reactivate RESULT result,

      "! Generate default permissions from ZDERS_ROLE_PERM
      "! Copies role defaults to ZDERS_USER_PERM for the assigned user
      generatePermissions FOR MODIFY
        IMPORTING keys FOR ACTION UserAssign~generatePermissions,

      "!──────────────────────────────────────────────────────────────────────
      "! FEATURE CONTROL
      "!──────────────────────────────────────────────────────────────────────

      "! Dynamic enable/disable of actions based on status
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR UserAssign RESULT result.

ENDCLASS.

"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATIONS
"! File: zbp_i_ders_userassign.clas.locals_imp.incl
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_userassign IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_global_authorizations
  " Check if user has admin authority (Z_DERS_ADM)
  " This controls Create, Update, Delete operations on user assignments
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_global_authorizations.
    " Check Create authorization
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '01'.  " Create

      DATA(lv_create_auth) = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Update authorization
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '02'.  " Change

      DATA(lv_update_auth) = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Delete authorization
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '06'.  " Delete

      DATA(lv_delete_auth) = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    result = VALUE #(
      %create = lv_create_auth
      %update = lv_update_auth
      %delete = lv_delete_auth
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setDefaults
  " Set default values: IsActive = true
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaults.
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        FIELDS ( IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assignments).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_userassign\\UserAssign.

    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>)
      WHERE IsActive IS INITIAL.

      APPEND VALUE #(
        %tky     = <fs_assign>-%tky
        IsActive = abap_true
        %control-IsActive = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_userassign IN LOCAL MODE
        ENTITY UserAssign
          UPDATE FIELDS ( IsActive )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateUser
  " Check if user exists in SAP (USR02)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateUser.
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        FIELDS ( UserId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assignments).

    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>).
      IF <fs_assign>-UserId IS INITIAL.
        CONTINUE.  " Mandatory field validation handles this
      ENDIF.

      " Check if user exists in USR02
      SELECT SINGLE @abap_true FROM usr02
        WHERE bname = @<fs_assign>-UserId
        INTO @DATA(lv_exists).

      IF lv_exists = abap_false.
        APPEND VALUE #( %tky = <fs_assign>-%tky ) TO failed-userassign.
        APPEND VALUE #(
          %tky = <fs_assign>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |User '{ <fs_assign>-UserId }' does not exist in SAP|
          )
          %element-UserId = if_abap_behv=>mk-on
        ) TO reported-userassign.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateCompanyCode
  " Check if company code exists in T001
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateCompanyCode.
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        FIELDS ( Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assignments).

    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>).
      IF <fs_assign>-Bukrs IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check if company code exists
      SELECT SINGLE @abap_true FROM t001
        WHERE bukrs = @<fs_assign>-Bukrs
        INTO @DATA(lv_exists).

      IF lv_exists = abap_false.
        APPEND VALUE #( %tky = <fs_assign>-%tky ) TO failed-userassign.
        APPEND VALUE #(
          %tky = <fs_assign>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Company code '{ <fs_assign>-Bukrs }' does not exist|
          )
          %element-Bukrs = if_abap_behv=>mk-on
        ) TO reported-userassign.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: deactivate
  " Deactivate user assignment (IsActive → false)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD deactivate.
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assignments).

    MODIFY ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        UPDATE FIELDS ( IsActive )
        WITH VALUE #(
          FOR ls_assign IN lt_assignments
          ( %tky     = ls_assign-%tky
            IsActive = abap_false
            %control-IsActive = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>).
      APPEND VALUE #(
        %tky = <fs_assign>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |User '{ <fs_assign>-UserId }' assignment for '{ <fs_assign>-Bukrs }' deactivated|
        )
      ) TO reported-userassign.
    ENDLOOP.

    result = VALUE #(
      FOR ls_assign IN lt_assignments
      ( %tky   = ls_assign-%tky
        %param = ls_assign )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: reactivate
  " Reactivate user assignment (IsActive → true)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD reactivate.
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assignments).

    MODIFY ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        UPDATE FIELDS ( IsActive )
        WITH VALUE #(
          FOR ls_assign IN lt_assignments
          ( %tky     = ls_assign-%tky
            IsActive = abap_true
            %control-IsActive = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>).
      APPEND VALUE #(
        %tky = <fs_assign>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |User '{ <fs_assign>-UserId }' assignment for '{ <fs_assign>-Bukrs }' reactivated|
        )
      ) TO reported-userassign.
    ENDLOOP.

    result = VALUE #(
      FOR ls_assign IN lt_assignments
      ( %tky   = ls_assign-%tky
        %param = ls_assign )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  " Dynamic enable/disable of actions based on status
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
        FIELDS ( IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assignments).

    LOOP AT lt_assignments ASSIGNING FIELD-SYMBOL(<fs_assign>).
      APPEND VALUE #(
        %tky = <fs_assign>-%tky

        " Deactivate: only enabled for active assignments
        %action-deactivate = COND #(
          WHEN <fs_assign>-IsActive = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " Reactivate: only enabled for inactive assignments
        %action-reactivate = COND #(
          WHEN <fs_assign>-IsActive = abap_false
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: generatePermissions
  " Reads role defaults from ZDERS_ROLE_PERM and creates user permissions
  " in ZDERS_USER_PERM with perm_type = 'D' (Default)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD generatePermissions.
    " Read user assignments being processed
    READ ENTITIES OF zi_ders_userassign IN LOCAL MODE
      ENTITY UserAssign
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_assign)
      FAILED DATA(ls_failed).

    DATA lv_perm_count TYPE i.

    LOOP AT lt_assign ASSIGNING FIELD-SYMBOL(<fs_assign>).
      " Skip if no business role assigned
      IF <fs_assign>-BusinessRole IS INITIAL.
        APPEND VALUE #(
          %tky = <fs_assign>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-warning
            text     = |No business role assigned for user '{ <fs_assign>-UserId }'. Assign a role first.|
          )
        ) TO reported-userassign.
        CONTINUE.
      ENDIF.

      " 1. Get role defaults from ZDERS_ROLE_PERM
      SELECT business_role, report_id, can_export, can_subscribe
        FROM zders_role_perm
        WHERE business_role = @<fs_assign>-BusinessRole
          AND is_default    = @abap_true
          AND is_active     = @abap_true
        INTO TABLE @DATA(lt_role_perm).

      IF lt_role_perm IS INITIAL.
        APPEND VALUE #(
          %tky = <fs_assign>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-warning
            text     = |No default permissions found for role '{ <fs_assign>-BusinessRole }'|
          )
        ) TO reported-userassign.
        CONTINUE.
      ENDIF.

      " 2. Delete outdated default permissions ('D') that no longer belong to the new role
      " We only touch 'D' (Default), we leave 'O' (Override by Admin) intact.
      DATA lt_valid_reports TYPE RANGE OF zders_user_perm-report_id.
      LOOP AT lt_role_perm ASSIGNING FIELD-SYMBOL(<fs_valid>).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <fs_valid>-report_id ) TO lt_valid_reports.
      ENDLOOP.

      IF lt_valid_reports IS NOT INITIAL.
        DELETE FROM zders_user_perm
          WHERE user_id   = @<fs_assign>-UserId
            AND bukrs     = @<fs_assign>-Bukrs
            AND perm_type = 'D'
            AND report_id NOT IN @lt_valid_reports.
      ELSE.
        " If new role has no valid reports, delete all old default permissions
        DELETE FROM zders_user_perm
          WHERE user_id   = @<fs_assign>-UserId
            AND bukrs     = @<fs_assign>-Bukrs
            AND perm_type = 'D'.
      ENDIF.

      " 3. Create/Update user permissions from role defaults
      DATA lv_created TYPE i VALUE 0.
      DATA lv_updated TYPE i VALUE 0.

      " Get current timestamp for create/update operations
      GET TIME STAMP FIELD DATA(lv_timestamp).

      LOOP AT lt_role_perm ASSIGNING FIELD-SYMBOL(<fs_role>).
        " Check if permission already exists (to avoid duplicates or to update if it exists)
        SELECT SINGLE perm_type FROM zders_user_perm
          WHERE user_id   = @<fs_assign>-UserId
            AND report_id = @<fs_role>-report_id
            AND bukrs     = @<fs_assign>-Bukrs
          INTO @DATA(lv_existing_perm_type).

        IF sy-subrc = 0.
          " It exists. If it's a 'D' (Default), we update it in case role flags changed
          " If it's 'O' (Override), we don't touch it.
          IF lv_existing_perm_type = 'D'.
            UPDATE zders_user_perm
              SET can_export    = @<fs_role>-can_export,
                  can_subscribe = @<fs_role>-can_subscribe,
                  is_active     = @abap_true,
                  changed_at    = @lv_timestamp,
                  changed_by    = @sy-uname
              WHERE user_id   = @<fs_assign>-UserId
                AND report_id = @<fs_role>-report_id
                AND bukrs     = @<fs_assign>-Bukrs.
            IF sy-subrc = 0.
              lv_updated = lv_updated + 1.
            ENDIF.
          ENDIF.
        ELSE.
          " Insert new permission record
          INSERT INTO zders_user_perm VALUES @(
            VALUE #(
              mandt         = sy-mandt
              user_id       = <fs_assign>-UserId
              report_id     = <fs_role>-report_id
              bukrs         = <fs_assign>-Bukrs
              can_export    = <fs_role>-can_export
              can_subscribe = <fs_role>-can_subscribe
              perm_type     = 'D'         " Default from role
              is_active     = abap_true
              created_by    = sy-uname
              created_at    = lv_timestamp
              changed_by    = sy-uname
              changed_at    = lv_timestamp
            )
          ).

          IF sy-subrc = 0.
            lv_created = lv_created + 1.
          ENDIF.
        ENDIF.
      ENDLOOP.

      lv_perm_count = lv_perm_count + lv_created + lv_updated.

      " 4. Success message per user
      APPEND VALUE #(
        %tky = <fs_assign>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |User '{ <fs_assign>-UserId }': { lv_created } added, { lv_updated } updated from role '{ <fs_assign>-BusinessRole }'|
        )
      ) TO reported-userassign.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
