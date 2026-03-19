"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_userperm.clas.locals_def.incl
"!
"! BDEF Type: Managed (Admin-only)
"! Authorization: Global (Z_DERS_ADM)
"!──────────────────────────────────────────────────────────────────────────────

"! Local Handler Class for UserPerm Entity
CLASS lhc_userperm DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS:
      "!──────────────────────────────────────────────────────────────────────
      "! AUTHORIZATION
      "!──────────────────────────────────────────────────────────────────────

      "! Global authorization check (admin only)
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR UserPerm RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! DETERMINATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Set perm_type = 'O' (Override) when admin creates
      setOverrideType FOR DETERMINE ON MODIFY
        IMPORTING keys FOR UserPerm~setOverrideType,

      "! Set default values (is_active = 'X', etc.)
      setDefaults FOR DETERMINE ON MODIFY
        IMPORTING keys FOR UserPerm~setDefaults,

      "!──────────────────────────────────────────────────────────────────────
      "! VALIDATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Validate user exists in SAP user master (USR02)
      validateUserExists FOR VALIDATE ON SAVE
        IMPORTING keys FOR UserPerm~validateUserExists,

      "! Validate report exists in ZDERS_CATALOG
      validateReportExists FOR VALIDATE ON SAVE
        IMPORTING keys FOR UserPerm~validateReportExists,

      "! Validate company code exists in T001
      validateCompanyExists FOR VALIDATE ON SAVE
        IMPORTING keys FOR UserPerm~validateCompanyExists,

      "!──────────────────────────────────────────────────────────────────────
      "! ACTIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Deactivate permission
      deactivate FOR MODIFY
        IMPORTING keys FOR ACTION UserPerm~deactivate RESULT result,

      "! Reactivate permission
      reactivate FOR MODIFY
        IMPORTING keys FOR ACTION UserPerm~reactivate RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! FEATURE CONTROL
      "!──────────────────────────────────────────────────────────────────────

      "! Dynamic enable/disable of actions based on status
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR UserPerm RESULT result.

ENDCLASS.

"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATION
"! File: zbp_i_ders_userperm.clas.locals_imp.incl
"!
"! BDEF Type: Managed (Admin-only)
"! Authorization: Global (Z_DERS_ADM)
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_userperm IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_global_authorizations
  " Check admin authorization for all operations
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_global_authorizations.
    " Check Z_DERS_ADM authorization object
    AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
      ID 'ACTVT' FIELD '02'.  " 02 = Change

    IF sy-subrc = 0.
      " User is admin - allow all operations
      result = VALUE #(
        %create      = if_abap_behv=>auth-allowed
        %update      = if_abap_behv=>auth-allowed
        %delete      = if_abap_behv=>auth-allowed
        %action-deactivate  = if_abap_behv=>auth-allowed
        %action-reactivate  = if_abap_behv=>auth-allowed
      ).
    ELSE.
      " Not admin - deny all operations
      result = VALUE #(
        %create      = if_abap_behv=>auth-unauthorized
        %update      = if_abap_behv=>auth-unauthorized
        %delete      = if_abap_behv=>auth-unauthorized
        %action-deactivate  = if_abap_behv=>auth-unauthorized
        %action-reactivate  = if_abap_behv=>auth-unauthorized
      ).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setOverrideType
  " Set perm_type = 'O' (Override) when admin manually creates permission
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setOverrideType.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        FIELDS ( PermType )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>)
      WHERE PermType IS INITIAL.

      MODIFY ENTITIES OF zi_ders_userperm IN LOCAL MODE
        ENTITY UserPerm
          UPDATE FIELDS ( PermType )
          WITH VALUE #( (
            %tky     = <fs_perm>-%tky
            PermType = 'O'  " Override - admin created
            %control-PermType = if_abap_behv=>mk-on
          ) )
        REPORTED DATA(lt_reported).
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setDefaults
  " Set default values on create
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaults.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        FIELDS ( IsActive CanExport CanSubscribe )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_userperm\\UserPerm.

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      DATA(lv_need_update) = abap_false.
      DATA ls_update TYPE STRUCTURE FOR UPDATE zi_ders_userperm\\UserPerm.
      ls_update-%tky = <fs_perm>-%tky.

      " Default IsActive = 'X'
      IF <fs_perm>-IsActive IS INITIAL.
        ls_update-IsActive = abap_true.
        ls_update-%control-IsActive = if_abap_behv=>mk-on.
        lv_need_update = abap_true.
      ENDIF.

      " Default CanExport = 'X'
      IF <fs_perm>-CanExport IS INITIAL.
        ls_update-CanExport = abap_true.
        ls_update-%control-CanExport = if_abap_behv=>mk-on.
        lv_need_update = abap_true.
      ENDIF.

      " Default CanSubscribe = 'X'
      IF <fs_perm>-CanSubscribe IS INITIAL.
        ls_update-CanSubscribe = abap_true.
        ls_update-%control-CanSubscribe = if_abap_behv=>mk-on.
        lv_need_update = abap_true.
      ENDIF.

      IF lv_need_update = abap_true.
        APPEND ls_update TO lt_updates.
      ENDIF.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_userperm IN LOCAL MODE
        ENTITY UserPerm
          UPDATE FIELDS ( IsActive CanExport CanSubscribe )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateUserExists
  " Check if UserId exists in SAP user master (USR02)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateUserExists.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        FIELDS ( UserId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      " Check if user exists in USR02
      SELECT SINGLE bname FROM usr02
        WHERE bname = @<fs_perm>-UserId
        INTO @DATA(lv_user).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <fs_perm>-%tky
          %element-UserId = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |User '{ <fs_perm>-UserId }' does not exist in SAP|
          )
        ) TO reported-userperm.

        APPEND VALUE #( %tky = <fs_perm>-%tky ) TO failed-userperm.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateReportExists
  " Check if ReportId exists in ZDERS_CATALOG and is active
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateReportExists.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        FIELDS ( ReportId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      " Check if report exists in catalog
      SELECT SINGLE report_id, is_active FROM zders_catalog
        WHERE report_id = @<fs_perm>-ReportId
        INTO @DATA(ls_catalog).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <fs_perm>-%tky
          %element-ReportId = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Report '{ <fs_perm>-ReportId }' does not exist in catalog|
          )
        ) TO reported-userperm.

        APPEND VALUE #( %tky = <fs_perm>-%tky ) TO failed-userperm.

      ELSEIF ls_catalog-is_active <> abap_true.
        APPEND VALUE #(
          %tky = <fs_perm>-%tky
          %element-ReportId = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-warning
            text     = |Report '{ <fs_perm>-ReportId }' is not active|
          )
        ) TO reported-userperm.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateCompanyExists
  " Check if Bukrs exists in T001
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateCompanyExists.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        FIELDS ( Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      " Check if company code exists in T001
      SELECT SINGLE bukrs FROM t001
        WHERE bukrs = @<fs_perm>-Bukrs
        INTO @DATA(lv_bukrs).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <fs_perm>-%tky
          %element-Bukrs = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Company Code '{ <fs_perm>-Bukrs }' does not exist|
          )
        ) TO reported-userperm.

        APPEND VALUE #( %tky = <fs_perm>-%tky ) TO failed-userperm.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: deactivate
  " Soft disable permission (set is_active = ' ')
  "═══════════════════════════════════════════════════════════════════════════
  METHOD deactivate.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      " Update status to inactive
      MODIFY ENTITIES OF zi_ders_userperm IN LOCAL MODE
        ENTITY UserPerm
          UPDATE FIELDS ( IsActive )
          WITH VALUE #( (
            %tky     = <fs_perm>-%tky
            IsActive = abap_false
            %control-IsActive = if_abap_behv=>mk-on
          ) )
        FAILED failed
        REPORTED reported.

      " Return result
      APPEND VALUE #(
        %tky   = <fs_perm>-%tky
        %param = <fs_perm>
      ) TO result.

      " Success message
      APPEND VALUE #(
        %tky = <fs_perm>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Permission for user '{ <fs_perm>-UserId }' deactivated|
        )
      ) TO reported-userperm.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: reactivate
  " Re-enable permission (set is_active = 'X')
  "═══════════════════════════════════════════════════════════════════════════
  METHOD reactivate.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      " Update status to active
      MODIFY ENTITIES OF zi_ders_userperm IN LOCAL MODE
        ENTITY UserPerm
          UPDATE FIELDS ( IsActive )
          WITH VALUE #( (
            %tky     = <fs_perm>-%tky
            IsActive = abap_true
            %control-IsActive = if_abap_behv=>mk-on
          ) )
        FAILED failed
        REPORTED reported.

      " Return result
      APPEND VALUE #(
        %tky   = <fs_perm>-%tky
        %param = <fs_perm>
      ) TO result.

      " Success message
      APPEND VALUE #(
        %tky = <fs_perm>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Permission for user '{ <fs_perm>-UserId }' reactivated|
        )
      ) TO reported-userperm.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  " Enable/disable actions based on current status
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_userperm IN LOCAL MODE
      ENTITY UserPerm
        FIELDS ( IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      APPEND VALUE #(
        %tky = <fs_perm>-%tky

        " Deactivate: enabled only if currently active
        %action-deactivate = COND #(
          WHEN <fs_perm>-IsActive = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " Reactivate: enabled only if currently inactive
        %action-reactivate = COND #(
          WHEN <fs_perm>-IsActive = abap_false
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
