"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_roleperm.clas.locals_def.incl
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_roleperm DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    "═══════════════════════════════════════════════════════════════════════════
    " AUTHORIZATION
    "═══════════════════════════════════════════════════════════════════════════
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR RolePerm
      RESULT result.

    "═══════════════════════════════════════════════════════════════════════════
    " DETERMINATIONS
    "═══════════════════════════════════════════════════════════════════════════
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR RolePerm~setDefaults.

    "═══════════════════════════════════════════════════════════════════════════
    " VALIDATIONS
    "═══════════════════════════════════════════════════════════════════════════
    METHODS validateReportExists FOR VALIDATE ON SAVE
      IMPORTING keys FOR RolePerm~validateReportExists.

    "═══════════════════════════════════════════════════════════════════════════
    " ACTIONS
    "═══════════════════════════════════════════════════════════════════════════
    METHODS deactivate FOR MODIFY
      IMPORTING keys FOR ACTION RolePerm~deactivate
      RESULT result.

    METHODS reactivate FOR MODIFY
      IMPORTING keys FOR ACTION RolePerm~reactivate
      RESULT result.

    "═══════════════════════════════════════════════════════════════════════════
    " FEATURE CONTROL
    "═══════════════════════════════════════════════════════════════════════════
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR RolePerm
      RESULT result.

ENDCLASS.



"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATION
"! File: zbp_i_ders_roleperm.clas.locals_imp.incl
"!
"! BDEF Type: Managed (Admin-only)
"! Authorization: Global (Z_DERS_ADM)
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_roleperm IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_global_authorizations
  " Check admin authorization for all operations
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
  " Set default values on create
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaults.
    READ ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
        FIELDS ( IsActive CanExport CanSubscribe IsDefault )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_roleperm\\RolePerm.

    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      DATA(lv_need_update) = abap_false.
      DATA ls_update TYPE STRUCTURE FOR UPDATE zi_ders_roleperm\\RolePerm.
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

      " Default IsDefault = ' ' (not default)
      " No need to set - already initial

      IF lv_need_update = abap_true.
        APPEND ls_update TO lt_updates.
      ENDIF.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_roleperm IN LOCAL MODE
        ENTITY RolePerm
          UPDATE FIELDS ( IsActive CanExport CanSubscribe )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateReportExists
  " Check if ReportId exists in ZDERS_CATALOG and is active
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateReportExists.
    READ ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
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
        ) TO reported-roleperm.

        APPEND VALUE #( %tky = <fs_perm>-%tky ) TO failed-roleperm.

      ELSEIF ls_catalog-is_active <> abap_true.
        APPEND VALUE #(
          %tky = <fs_perm>-%tky
          %element-ReportId = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-warning
            text     = |Report '{ <fs_perm>-ReportId }' is not active|
          )
        ) TO reported-roleperm.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: deactivate
  " Soft disable permission (set is_active = ' ')
  "═══════════════════════════════════════════════════════════════════════════
  METHOD deactivate.
    READ ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    MODIFY ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
        UPDATE FIELDS ( IsActive )
        WITH VALUE #(
          FOR ls_perm IN lt_perms
          ( %tky     = ls_perm-%tky
            IsActive = abap_false
            %control-IsActive = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      APPEND VALUE #(
        %tky = <fs_perm>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Role '{ <fs_perm>-BusinessRole }' permission for report '{ <fs_perm>-ReportId }' deactivated|
        )
      ) TO reported-roleperm.
    ENDLOOP.

    result = VALUE #(
      FOR ls_perm IN lt_perms
      ( %tky   = ls_perm-%tky
        %param = ls_perm )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: reactivate
  " Re-enable permission (set is_active = 'X')
  "═══════════════════════════════════════════════════════════════════════════
  METHOD reactivate.
    READ ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_perms).

    MODIFY ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
        UPDATE FIELDS ( IsActive )
        WITH VALUE #(
          FOR ls_perm IN lt_perms
          ( %tky     = ls_perm-%tky
            IsActive = abap_true
            %control-IsActive = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Success message
    LOOP AT lt_perms ASSIGNING FIELD-SYMBOL(<fs_perm>).
      APPEND VALUE #(
        %tky = <fs_perm>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = |Role '{ <fs_perm>-BusinessRole }' permission for report '{ <fs_perm>-ReportId }' reactivated|
        )
      ) TO reported-roleperm.
    ENDLOOP.

    result = VALUE #(
      FOR ls_perm IN lt_perms
      ( %tky   = ls_perm-%tky
        %param = ls_perm )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  " Enable/disable actions based on current status
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_roleperm IN LOCAL MODE
      ENTITY RolePerm
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
