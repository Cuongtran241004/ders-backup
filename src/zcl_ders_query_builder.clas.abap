"!──────────────────────────────────────────────────────────────────────────────
"! CLASS: ZCL_DERS_QUERY_BUILDER
"! PURPOSE: Converts ZDERS_JOB_PARAM records into dynamic SQL WHERE clause
"!          and CDS parameter string for views with input parameters
"!
"! PARAM TYPES:
"!   S = Single    → WHERE FIELD = 'value'
"!   R = Range     → WHERE FIELD BETWEEN 'from' AND 'to'
"!   M = Multiple  → WHERE FIELD IN ('v1','v2')
"!   P = CDS Param → appended to FROM: CDS_VIEW( PARAM = 'value' )
"!   N = No-filter → ignored entirely (display-only params)
"!──────────────────────────────────────────────────────────────────────────────
CLASS zcl_ders_query_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Build WHERE clause from structured job parameters (types S/R/M only)
    "! @parameter it_job_params | Records from ZDERS_JOB_PARAM for this job
    "! @parameter it_param_defs | Definitions from ZDERS_PARAM for this report
    "! @parameter rv_where      | Generated SQL WHERE clause string
    CLASS-METHODS build_where_clause
      IMPORTING
        it_job_params   TYPE STANDARD TABLE
        it_param_defs   TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_where) TYPE string.

    "! Build CDS parameter string for views with input parameters (type P)
    "! Returns e.g. '( P_KeyDate = ''20260313'' )' or '' if no P-type params
    "! @parameter it_job_params | Records from ZDERS_JOB_PARAM for this job
    "! @parameter it_param_defs | Definitions from ZDERS_PARAM for this report
    "! @parameter rv_params     | CDS parameter string to append after view name
    CLASS-METHODS build_cds_params
      IMPORTING
        it_job_params   TYPE STANDARD TABLE
        it_param_defs   TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_params) TYPE string.

  PRIVATE SECTION.
    "! Resolve system variables in parameter values
    CLASS-METHODS resolve_system_value
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

ENDCLASS.

CLASS zcl_ders_query_builder IMPLEMENTATION.

  METHOD build_where_clause.
    DATA lt_conditions TYPE TABLE OF string.

    " Iterate over parameter definitions (determines field names)
    LOOP AT it_param_defs ASSIGNING FIELD-SYMBOL(<ls_def>).
      " Get param_name from definition
      ASSIGN COMPONENT 'PARAM_NAME' OF STRUCTURE <ls_def> TO FIELD-SYMBOL(<lv_name>).
      CHECK sy-subrc = 0 AND <lv_name> IS NOT INITIAL.

      " Find matching job parameter value by param_name
      LOOP AT it_job_params ASSIGNING FIELD-SYMBOL(<ls_jp>).
        ASSIGN COMPONENT 'PARAM_NAME' OF STRUCTURE <ls_jp> TO FIELD-SYMBOL(<lv_jp_name>).
        CHECK sy-subrc = 0 AND <lv_jp_name> = <lv_name>.

        " Get values from job parameter
        ASSIGN COMPONENT 'PARAM_VALUE_FROM' OF STRUCTURE <ls_jp> TO FIELD-SYMBOL(<lv_from>).
        ASSIGN COMPONENT 'PARAM_VALUE_TO'   OF STRUCTURE <ls_jp> TO FIELD-SYMBOL(<lv_to>).
        ASSIGN COMPONENT 'PARAM_TYPE'       OF STRUCTURE <ls_jp> TO FIELD-SYMBOL(<lv_type>).

        " Skip if no value provided
        CHECK <lv_from> IS ASSIGNED AND <lv_from> IS NOT INITIAL.

        " Resolve system variables (SY-DATUM, SY-UNAME, etc.)
        DATA(lv_from) = resolve_system_value( CONV string( <lv_from> ) ).

        " Escape single quotes for SQL injection safety
        REPLACE ALL OCCURRENCES OF '''' IN lv_from WITH ''''''.

        " param_name in ZDERS_PARAM IS the CDS field name
        " (e.g., BUKRS, GJAHR, BUDAT)
        DATA(lv_field) = CONV string( <lv_name> ).

        " Use definition param_type as authoritative source if job param type is empty
        DATA lv_eff_type TYPE string.
        IF <lv_type> IS ASSIGNED AND <lv_type> IS NOT INITIAL.
          lv_eff_type = <lv_type>.
        ELSE.
          ASSIGN COMPONENT 'PARAM_TYPE' OF STRUCTURE <ls_def> TO FIELD-SYMBOL(<lv_def_type>).
          IF sy-subrc = 0. lv_eff_type = <lv_def_type>. ENDIF.
        ENDIF.

        " Build condition based on parameter type
        " 'N' = No-filter: skip WHERE entirely
        " 'P' = CDS Param: handled in FROM clause, NOT in WHERE
        IF lv_eff_type = 'N' OR lv_eff_type = 'P'. EXIT. ENDIF.

        IF lv_eff_type IS NOT INITIAL.
          CASE lv_eff_type.

            WHEN 'R'.
              " Range: FIELD BETWEEN 'from' AND 'to'
              IF <lv_to> IS ASSIGNED AND <lv_to> IS NOT INITIAL.
                DATA(lv_to) = resolve_system_value( CONV string( <lv_to> ) ).
                REPLACE ALL OCCURRENCES OF '''' IN lv_to WITH ''''''.
                APPEND |{ lv_field } BETWEEN '{ lv_from }' AND '{ lv_to }'|
                  TO lt_conditions.
              ELSE.
                " Range with no TO value: treat as Single
                APPEND |{ lv_field } = '{ lv_from }'| TO lt_conditions.
              ENDIF.

            WHEN 'M'.
              " Multiple: FIELD IN ('v1', 'v2', 'v3')
              " param_value_from contains comma-separated values
              DATA(lt_values) = VALUE string_table( ).
              SPLIT lv_from AT ',' INTO TABLE lt_values.
              DATA(lv_in_list) = ||.
              LOOP AT lt_values INTO DATA(lv_val).
                CONDENSE lv_val.
                lv_val = resolve_system_value( lv_val ).
                REPLACE ALL OCCURRENCES OF '''' IN lv_val WITH ''''''.
                IF lv_in_list IS NOT INITIAL.
                  lv_in_list = |{ lv_in_list }, '{ lv_val }'|.
                ELSE.
                  lv_in_list = |'{ lv_val }'|.
                ENDIF.
              ENDLOOP.
              IF lv_in_list IS NOT INITIAL.
                APPEND |{ lv_field } IN ({ lv_in_list })| TO lt_conditions.
              ENDIF.

            WHEN OTHERS.
              " Single (default): FIELD = 'value'
              APPEND |{ lv_field } = '{ lv_from }'| TO lt_conditions.

          ENDCASE.
        ELSE.
          " No type specified: default to Single
          APPEND |{ lv_field } = '{ lv_from }'| TO lt_conditions.
        ENDIF.
        CLEAR lv_eff_type.

        EXIT.  " Found match for this param, move to next definition
      ENDLOOP.

      UNASSIGN: <lv_from>, <lv_to>, <lv_type>.
    ENDLOOP.

    " Join all conditions with AND
    rv_where = concat_lines_of( table = lt_conditions sep = ` AND ` ).
  ENDMETHOD.

  METHOD build_cds_params.
    " Build CDS parameter string for views with input parameters (type P)
    " Example output: ( P_KeyDate = '20260313' P_Bukrs = '1000' )
    DATA lt_pairs TYPE TABLE OF string.

    LOOP AT it_param_defs ASSIGNING FIELD-SYMBOL(<ls_def>).
      ASSIGN COMPONENT 'PARAM_NAME' OF STRUCTURE <ls_def> TO FIELD-SYMBOL(<lv_name>).
      ASSIGN COMPONENT 'PARAM_TYPE' OF STRUCTURE <ls_def> TO FIELD-SYMBOL(<lv_def_type>).
      CHECK sy-subrc = 0.
      CHECK <lv_name> IS NOT INITIAL.
      CHECK CONV string( <lv_def_type> ) = 'P'.  " Only CDS parameter types

      " Find matching value in job parameters
      LOOP AT it_job_params ASSIGNING FIELD-SYMBOL(<ls_jp>).
        ASSIGN COMPONENT 'PARAM_NAME'        OF STRUCTURE <ls_jp> TO FIELD-SYMBOL(<lv_jp_name>).
        ASSIGN COMPONENT 'PARAM_VALUE_FROM'  OF STRUCTURE <ls_jp> TO FIELD-SYMBOL(<lv_jp_from>).
        CHECK sy-subrc = 0 AND <lv_jp_name> = <lv_name>.
        CHECK <lv_jp_from> IS ASSIGNED AND <lv_jp_from> IS NOT INITIAL.

        DATA(lv_val) = resolve_system_value( CONV string( <lv_jp_from> ) ).
        " Escape single quotes
        REPLACE ALL OCCURRENCES OF '''' IN lv_val WITH ''''''.
        APPEND |{ <lv_name> } = '{ lv_val }'| TO lt_pairs.
        EXIT.
      ENDLOOP.

      " Fallback to default_value if no job param supplied
      IF sy-subrc <> 0.
        ASSIGN COMPONENT 'DEFAULT_VALUE' OF STRUCTURE <ls_def> TO FIELD-SYMBOL(<lv_default>).
        IF sy-subrc = 0 AND <lv_default> IS NOT INITIAL.
          DATA(lv_def_val) = resolve_system_value( CONV string( <lv_default> ) ).
          REPLACE ALL OCCURRENCES OF '''' IN lv_def_val WITH ''''''.
          APPEND |{ <lv_name> } = '{ lv_def_val }'| TO lt_pairs.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lt_pairs IS NOT INITIAL.
      rv_params = |( { concat_lines_of( table = lt_pairs sep = ` ` ) } )|.
    ENDIF.
  ENDMETHOD.

  METHOD resolve_system_value.
    " Resolve system variable expressions to actual values
    " Supports: SY-DATUM, SY-UZEIT, SY-UNAME and variations

    DATA(lv_upper) = to_upper( iv_value ).

    " Handle various formats: SY-DATUM, sy-datum, DATUM, etc.
    CASE lv_upper.
      WHEN 'SY-DATUM' OR 'SY_DATUM' OR 'DATUM' OR 'SYST-DATUM'.
        " Return current date as YYYYMMDD string
        rv_value = |{ sy-datum }|.

      WHEN 'SY-UZEIT' OR 'SY_UZEIT' OR 'UZEIT' OR 'SYST-UZEIT'.
        " Return current time as HHMMSS string
        rv_value = |{ sy-uzeit }|.

      WHEN 'SY-UNAME' OR 'SY_UNAME' OR 'UNAME' OR 'SYST-UNAME'.
        " Return current username
        rv_value = |{ sy-uname }|.

      WHEN 'SY-MANDT' OR 'SY_MANDT' OR 'MANDT' OR 'SYST-MANDT'.
        " Return current client
        rv_value = |{ sy-mandt }|.

      WHEN OTHERS.
        " Check for date arithmetic (e.g., SY-DATUM-30)
        IF lv_upper CP 'SY-DATUM*' OR lv_upper CP 'SY_DATUM*'.
          " Extract offset if present (e.g., SY-DATUM-30 or SY-DATUM+7)
          DATA(lv_offset_str) = substring_after( val = lv_upper sub = 'DATUM' ).
          IF lv_offset_str IS NOT INITIAL.
            TRY.
                DATA(lv_offset) = CONV i( lv_offset_str ).
                DATA(lv_date) = CONV d( sy-datum + lv_offset ).
                rv_value = |{ lv_date }|.
              CATCH cx_root.
                " Invalid offset, return original value
                rv_value = iv_value.
            ENDTRY.
          ELSE.
            rv_value = |{ sy-datum }|.
          ENDIF.
        ELSE.
          " Not a system variable - return as-is
          rv_value = iv_value.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

