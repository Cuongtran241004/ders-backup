"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS DEFINITIONS
"! File: zbp_i_ders_catalog.clas.locals_def.incl
"!──────────────────────────────────────────────────────────────────────────────

"! Local Handler Class for Catalog Entity
CLASS lhc_catalog DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    "! Table types for RAP operations
    TYPES:
      tt_catalog_create TYPE TABLE FOR CREATE zi_ders_catalog\\Catalog,
      tt_catalog_update TYPE TABLE FOR UPDATE zi_ders_catalog\\Catalog.

    METHODS:
      "!──────────────────────────────────────────────────────────────────────
      "! VALIDATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Validate module exists and is active in value table
      validateModule FOR VALIDATE ON SAVE
        IMPORTING keys FOR Catalog~validateModule,

      "! Validate CDS view exists in DDIC
      validateCdsView FOR VALIDATE ON SAVE
        IMPORTING keys FOR Catalog~validateCdsView,

      "! Validate supported formats (XLSX,PDF,CSV)
      validateFormats FOR VALIDATE ON SAVE
        IMPORTING keys FOR Catalog~validateFormats,

      "!──────────────────────────────────────────────────────────────────────
      "! DETERMINATIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Set default values on create
      setDefaults FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Catalog~setDefaults,

      "! Calculate derived fields (SupportsExcel, SupportsPdf)
      calculateDerivedFields FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Catalog~calculateDerivedFields,

      "!──────────────────────────────────────────────────────────────────────
      "! ACTIONS
      "!──────────────────────────────────────────────────────────────────────

      "! Activate report - make available to users
      activateReport FOR MODIFY
        IMPORTING keys FOR ACTION Catalog~activateReport RESULT result,

      "! Deactivate report - hide from users
      deactivateReport FOR MODIFY
        IMPORTING keys FOR ACTION Catalog~deactivateReport RESULT result,

      "! Create report from existing template
      createFromTemplate FOR MODIFY
        IMPORTING keys FOR ACTION Catalog~createFromTemplate RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! AUTHORIZATION
      "!──────────────────────────────────────────────────────────────────────

      "! Global authorization check (admin only)
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR Catalog RESULT result,

      "!──────────────────────────────────────────────────────────────────────
      "! FEATURE CONTROL
      "!──────────────────────────────────────────────────────────────────────

      "! Instance-based feature control for actions
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR Catalog RESULT result.

ENDCLASS.


"! Local Handler Class for Parameter Entity
CLASS lhc_parameter DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      "! Validate parameter type is S/R/M
      validateParamType FOR VALIDATE ON SAVE
        IMPORTING keys FOR Parameter~validateParamType,

      "! Validate data element exists in DDIC
      validateDataElement FOR VALIDATE ON SAVE
        IMPORTING keys FOR Parameter~validateDataElement,

      "! Set default parameter type to 'S' (Single)
      setDefaultParamType FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Parameter~setDefaultParamType.

ENDCLASS.

"!──────────────────────────────────────────────────────────────────────────────
"! LOCAL HANDLER CLASS IMPLEMENTATIONS
"! File: zbp_i_ders_catalog.clas.locals_imp.incl
"!──────────────────────────────────────────────────────────────────────────────

CLASS lhc_catalog IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateModule
  " Check if module exists and is active in ZDERS_MODULE_VT
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateModule.
    " Read catalog entries to validate
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ModuleId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    IF lt_catalogs IS INITIAL.
      RETURN.
    ENDIF.

    " Load valid modules from value table
    SELECT module_id FROM zders_module_vt
      WHERE is_active = @abap_true
      INTO TABLE @DATA(lt_valid_modules).

    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<fs_catalog>).
      " Check if module is valid and active
      IF NOT line_exists( lt_valid_modules[ module_id = <fs_catalog>-ModuleId ] ).
        APPEND VALUE #(
          %tky = <fs_catalog>-%tky
        ) TO failed-catalog.

        APPEND VALUE #(
          %tky = <fs_catalog>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Module '{ <fs_catalog>-ModuleId }' is not valid or inactive|
          )
          %element-ModuleId = if_abap_behv=>mk-on
        ) TO reported-catalog.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateCdsView
  " Check if CDS view exists in DDIC (DDDDLSRC table)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateCdsView.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( CdsViewName )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<fs_catalog>).
      " Skip if empty (mandatory validation handles this)
      IF <fs_catalog>-CdsViewName IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check if CDS view exists in DDIC
      DATA(lv_exists) = abap_false.
      SELECT SINGLE @abap_true FROM ddddlsrc
        WHERE ddlname = @<fs_catalog>-CdsViewName
        INTO @lv_exists.

      IF lv_exists = abap_false.
        APPEND VALUE #( %tky = <fs_catalog>-%tky ) TO failed-catalog.

        APPEND VALUE #(
          %tky = <fs_catalog>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |CDS View '{ <fs_catalog>-CdsViewName }' does not exist|
          )
          %element-CdsViewName = if_abap_behv=>mk-on
        ) TO reported-catalog.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateFormats
  " Validate comma-separated format string (XLSX,PDF,CSV)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateFormats.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( SupportedFormats )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    " Load valid formats from value table
    SELECT format_id FROM zders_format_vt
      WHERE is_active = @abap_true
      INTO TABLE @DATA(lt_valid_formats).

    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<fs_catalog>).
      " Skip if empty - not mandatory
      IF <fs_catalog>-SupportedFormats IS INITIAL.
        CONTINUE.
      ENDIF.

      " Parse comma-separated formats
      SPLIT <fs_catalog>-SupportedFormats AT ',' INTO TABLE DATA(lt_formats).

      LOOP AT lt_formats INTO DATA(lv_format).
        lv_format = to_upper( condense( lv_format ) ).

        IF NOT line_exists( lt_valid_formats[ format_id = lv_format ] ).
          APPEND VALUE #( %tky = <fs_catalog>-%tky ) TO failed-catalog.

          APPEND VALUE #(
            %tky = <fs_catalog>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = |Format '{ lv_format }' is not supported. Valid: XLSX, PDF, CSV|
            )
            %element-SupportedFormats = if_abap_behv=>mk-on
          ) TO reported-catalog.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setDefaults
  " Set default values on create: IsActive=true, MaxRows=100000, etc.
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaults.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( IsActive MaxRows EstimatedRuntime SupportedFormats )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_catalog\\Catalog.

    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<fs_catalog>).
      APPEND VALUE #(
        %tky              = <fs_catalog>-%tky

        " Default IsActive = true
        IsActive          = COND #( WHEN <fs_catalog>-IsActive IS INITIAL
                                    THEN abap_true
                                    ELSE <fs_catalog>-IsActive )

        " Default MaxRows = 100,000
        MaxRows           = COND #( WHEN <fs_catalog>-MaxRows IS INITIAL
                                    THEN 100000
                                    ELSE <fs_catalog>-MaxRows )

        " Default EstimatedRuntime = 60 seconds
        EstimatedRuntime  = COND #( WHEN <fs_catalog>-EstimatedRuntime IS INITIAL
                                    THEN 60
                                    ELSE <fs_catalog>-EstimatedRuntime )

        " Default SupportedFormats = XLSX,PDF,CSV (all formats)
        SupportedFormats  = COND #( WHEN <fs_catalog>-SupportedFormats IS INITIAL
                                    THEN 'XLSX,PDF,CSV'
                                    ELSE <fs_catalog>-SupportedFormats )

        %control-IsActive          = if_abap_behv=>mk-on
        %control-MaxRows           = if_abap_behv=>mk-on
        %control-EstimatedRuntime  = if_abap_behv=>mk-on
        %control-SupportedFormats  = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    MODIFY ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        UPDATE FIELDS ( IsActive MaxRows EstimatedRuntime SupportedFormats )
        WITH lt_updates
      REPORTED DATA(lt_reported).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: calculateDerivedFields
  " Calculate SupportsExcel, SupportsPdf based on SupportedFormats
  " Note: These are virtual fields in CDS, so no DB update needed
  "═══════════════════════════════════════════════════════════════════════════
  METHOD calculateDerivedFields.
    " No action needed - derived fields calculated in CDS view
    " This determination handles any complex logic not possible in CDS
    " Currently a placeholder for future extension
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: activateReport
  " Activate report - make it available for users to export/subscribe
  "═══════════════════════════════════════════════════════════════════════════
  METHOD activateReport.
    " Read current state
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ReportId IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    " Update to Active
    MODIFY ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        UPDATE FIELDS ( IsActive )
        WITH VALUE #(
          FOR ls_catalog IN lt_catalogs
          ( %tky     = ls_catalog-%tky
            IsActive = abap_true
            %control-IsActive = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    " Return result
    result = VALUE #(
      FOR ls_catalog IN lt_catalogs
      ( %tky   = ls_catalog-%tky
        %param = ls_catalog )
    ).

    " Log audit event
    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<fs_catalog>).
      " TODO: Call audit log helper class
      " zcl_ders_audit_log=>log(
      "   iv_event       = 'CATALOG_ACTIVATE'
      "   iv_object_type = 'CATALOG'
      "   iv_object_id   = CONV #( <fs_catalog>-ReportId )
      "   iv_user        = sy-uname
      " ).
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: deactivateReport
  " Deactivate report - hide from users
  " Precondition: No active subscriptions for this report
  "═══════════════════════════════════════════════════════════════════════════
  METHOD deactivateReport.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ReportId IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    " Check for active subscriptions BEFORE deactivating
    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<fs_catalog>).
      SELECT COUNT(*) FROM zders_subscr
        WHERE report_id = @<fs_catalog>-ReportId
          AND status = 'A'  " Active subscriptions only
        INTO @DATA(lv_active_subscr).

      IF lv_active_subscr > 0.
        " Cannot deactivate - has active subscriptions
        APPEND VALUE #( %tky = <fs_catalog>-%tky ) TO failed-catalog.

        APPEND VALUE #(
          %tky = <fs_catalog>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Cannot deactivate: { lv_active_subscr } active subscription(s) exist. Please cancel them first.|
          )
        ) TO reported-catalog.
        RETURN.
      ENDIF.
    ENDLOOP.

    " All checks passed - Update to Inactive
    MODIFY ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        UPDATE FIELDS ( IsActive )
        WITH VALUE #(
          FOR ls_catalog IN lt_catalogs
          ( %tky     = ls_catalog-%tky
            IsActive = abap_false
            %control-IsActive = if_abap_behv=>mk-on )
        )
      FAILED failed
      REPORTED reported.

    result = VALUE #(
      FOR ls_catalog IN lt_catalogs
      ( %tky   = ls_catalog-%tky
        %param = ls_catalog )
    ).
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " ACTION: createFromTemplate (Static)
  " Create a new report by copying from an existing template
  "═══════════════════════════════════════════════════════════════════════════
  METHOD createFromTemplate.
    DATA lt_creates TYPE TABLE FOR CREATE zi_ders_catalog\\Catalog.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      " Read template report
      SELECT SINGLE * FROM zders_catalog
        WHERE report_id = @<fs_key>-%param-TemplateReportId
        INTO @DATA(ls_template).

      IF sy-subrc <> 0.
        APPEND VALUE #( %cid = <fs_key>-%cid ) TO failed-catalog.
        APPEND VALUE #(
          %cid = <fs_key>-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Template report '{ <fs_key>-%param-TemplateReportId }' not found|
          )
        ) TO reported-catalog.
        CONTINUE.
      ENDIF.

      " Check if new report ID already exists
      SELECT SINGLE @abap_true FROM zders_catalog
        WHERE report_id = @<fs_key>-%param-NewReportId
        INTO @DATA(lv_exists).

      IF lv_exists = abap_true.
        APPEND VALUE #( %cid = <fs_key>-%cid ) TO failed-catalog.
        APPEND VALUE #(
          %cid = <fs_key>-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Report ID '{ <fs_key>-%param-NewReportId }' already exists|
          )
        ) TO reported-catalog.
        CONTINUE.
      ENDIF.

      " Create new report from template
      APPEND VALUE #(
        %cid              = <fs_key>-%cid
        ReportId          = <fs_key>-%param-NewReportId
        ModuleId          = ls_template-module_id
        ReportName        = <fs_key>-%param-NewReportName
        Description       = ls_template-description
        CdsViewName       = ls_template-cds_view_name
        SupportedFormats  = ls_template-supported_formats
        MaxRows           = ls_template-max_rows
        EstimatedRuntime  = ls_template-estimated_runtime
        IsActive          = abap_true
        %control          = VALUE #(
          ReportId          = if_abap_behv=>mk-on
          ModuleId          = if_abap_behv=>mk-on
          ReportName        = if_abap_behv=>mk-on
          Description       = if_abap_behv=>mk-on
          CdsViewName       = if_abap_behv=>mk-on
          SupportedFormats  = if_abap_behv=>mk-on
          MaxRows           = if_abap_behv=>mk-on
          EstimatedRuntime  = if_abap_behv=>mk-on
          IsActive          = if_abap_behv=>mk-on
        )
      ) TO lt_creates.
    ENDLOOP.

    " Execute create
    MODIFY ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        CREATE FIELDS (
          ReportId ModuleId ReportName Description
          CdsViewName SupportedFormats MaxRows
          EstimatedRuntime IsActive
        )
        WITH lt_creates
      MAPPED DATA(lt_mapped)
      FAILED failed
      REPORTED reported.

    " Build result
    result = VALUE #(
      FOR ls_mapped IN lt_mapped-catalog
      ( %cid   = ls_mapped-%cid )
    ).

    " Copy parameters if requested
    LOOP AT keys ASSIGNING <fs_key>
      WHERE %param-CopyParameters = abap_true.

      " Read template parameters
      SELECT * FROM zders_param
        WHERE report_id = @<fs_key>-%param-TemplateReportId
        INTO TABLE @DATA(lt_template_params).

      " Create parameters for new report
      IF lt_template_params IS NOT INITIAL.
        MODIFY ENTITIES OF zi_ders_catalog IN LOCAL MODE
          ENTITY Catalog
            CREATE BY \_Parameters
            FIELDS ( ParamName ParamLabel ParamType DataElement
                     IsMandatory DefaultValue AuthObject AuthField F4CdsView )
            WITH VALUE #(
              ( %tky-ReportId = <fs_key>-%param-NewReportId
                %target = VALUE #(
                  FOR ls_param IN lt_template_params INDEX INTO lv_idx
                  ( %cid         = |PARAM{ lv_idx }|
                    ParamName    = ls_param-param_name
                    ParamLabel   = ls_param-param_label
                    ParamType    = ls_param-param_type
                    DataElement  = ls_param-data_element
                    IsMandatory  = ls_param-is_mandatory
                    DefaultValue = ls_param-default_value
                    AuthObject   = ls_param-auth_object
                    AuthField    = ls_param-auth_field
                    F4CdsView    = ls_param-f4_cds_view
                  )
                )
              )
            )
          FAILED DATA(lt_param_failed)
          REPORTED DATA(lt_param_reported).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " AUTHORIZATION: get_global_authorizations
  " Check if user has admin rights to manage catalog (admin only)
  " Uses Z_DERS_ADM authorization object with different activities
  " All users have read-only access (controlled by DCL)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_global_authorizations.
    " Check Create authorization (ACTVT = 01)
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '01'.  " Create

      result-%create = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Update authorization (ACTVT = 02)
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '02'.  " Change

      result-%update = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Delete authorization (ACTVT = 06)
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '06'.  " Delete

      result-%delete = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Activate Report action (ACTVT = 02)
    IF requested_authorizations-%action-activateReport = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '02'.  " Change

      result-%action-activateReport = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Deactivate Report action (ACTVT = 02)
    IF requested_authorizations-%action-deactivateReport = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '02'.  " Change

      result-%action-deactivateReport = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    " Check Create From Template action (ACTVT = 01)
    IF requested_authorizations-%action-createFromTemplate = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'Z_DERS_ADM'
        ID 'ACTVT' FIELD '01'.  " Create

      result-%action-createFromTemplate = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " FEATURE CONTROL: get_instance_features
  " Dynamic enable/disable of actions based on instance state
  "═══════════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    " Build feature table in a single VALUE expression
    result = VALUE #(
      FOR <fs_catalog> IN lt_catalogs
      ( %tky = <fs_catalog>-%tky

        " Activate: enabled only when currently inactive
        %action-activateReport = COND #(
          WHEN <fs_catalog>-IsActive = abap_false
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )

        " Deactivate: enabled only when currently active
        %action-deactivateReport = COND #(
          WHEN <fs_catalog>-IsActive = abap_true
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled
        )
      )
    ).
  ENDMETHOD.

ENDCLASS.


"!══════════════════════════════════════════════════════════════════════════════
"! PARAMETER HANDLER IMPLEMENTATION
"!══════════════════════════════════════════════════════════════════════════════
CLASS lhc_parameter IMPLEMENTATION.

  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateParamType
  " Ensure parameter type is S (Single), R (Range), or M (Multiple)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateParamType.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Parameter
        FIELDS ( ParamType )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_params).

    LOOP AT lt_params ASSIGNING FIELD-SYMBOL(<fs_param>).
      " Skip if initial (determination will set default)
      IF <fs_param>-ParamType IS INITIAL.
        CONTINUE.
      ENDIF.

      " Validate against allowed values
      IF <fs_param>-ParamType NOT IN VALUE rseloption(
        ( sign = 'I' option = 'EQ' low = 'S' )  " Single Value
        ( sign = 'I' option = 'EQ' low = 'R' )  " Range
        ( sign = 'I' option = 'EQ' low = 'M' )  " Multiple Selection
      ).
        APPEND VALUE #( %tky = <fs_param>-%tky ) TO failed-parameter.
        APPEND VALUE #(
          %tky = <fs_param>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Invalid parameter type '{ <fs_param>-ParamType }'. Valid values: S (Single), R (Range), M (Multiple)|
          )
          %element-ParamType = if_abap_behv=>mk-on
        ) TO reported-parameter.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " VALIDATION: validateDataElement
  " Check if data element exists in DDIC (DD04L)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD validateDataElement.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Parameter
        FIELDS ( DataElement )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_params).

    LOOP AT lt_params ASSIGNING FIELD-SYMBOL(<fs_param>).
      IF <fs_param>-DataElement IS NOT INITIAL.
        " Check if data element exists in DDIC
        SELECT SINGLE @abap_true FROM dd04l
          WHERE rollname = @<fs_param>-DataElement
          INTO @DATA(lv_exists).

        IF lv_exists = abap_false.
          APPEND VALUE #( %tky = <fs_param>-%tky ) TO failed-parameter.
          APPEND VALUE #(
            %tky = <fs_param>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = |Data element '{ <fs_param>-DataElement }' does not exist in DDIC|
            )
            %element-DataElement = if_abap_behv=>mk-on
          ) TO reported-parameter.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "═══════════════════════════════════════════════════════════════════════════
  " DETERMINATION: setDefaultParamType
  " Set default parameter type to 'S' (Single Value)
  "═══════════════════════════════════════════════════════════════════════════
  METHOD setDefaultParamType.
    READ ENTITIES OF zi_ders_catalog IN LOCAL MODE
      ENTITY Parameter
        FIELDS ( ParamType )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_params).

    DATA lt_updates TYPE TABLE FOR UPDATE zi_ders_catalog\\Parameter.

    LOOP AT lt_params ASSIGNING FIELD-SYMBOL(<fs_param>)
      WHERE ParamType IS INITIAL.

      APPEND VALUE #(
        %tky       = <fs_param>-%tky
        ParamType  = 'S'  " Default to Single Value
        %control-ParamType = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ders_catalog IN LOCAL MODE
        ENTITY Parameter
          UPDATE FIELDS ( ParamType )
          WITH lt_updates
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
