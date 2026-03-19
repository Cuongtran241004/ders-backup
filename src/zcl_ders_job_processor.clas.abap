CLASS zcl_ders_job_processor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      if_apj_dt_exec_object,
      if_apj_rt_exec_object.

    CONSTANTS:
      c_job_template TYPE apj_job_template_name VALUE 'ZDERS_JOB_TEMPLATE_V4'.

  PRIVATE SECTION.
    DATA:
      mv_job_uuid    TYPE sysuuid_x16,
      ms_job         TYPE zders_jobhist,
      ms_catalog     TYPE zders_catalog,
      mt_job_params  TYPE STANDARD TABLE OF zders_job_param WITH DEFAULT KEY,
      mt_param_defs  TYPE STANDARD TABLE OF zders_param WITH DEFAULT KEY.

    "! Load all context data for this job (JOBHIST + CATALOG + JOB_PARAM + PARAM)
    METHODS load_job_context
      RAISING zcx_ders_job_error.

    "! Build and execute the dynamic report query
    METHODS execute_report_query
      EXPORTING
        et_result    TYPE REF TO data
        ev_row_count TYPE int8
      RAISING zcx_ders_job_error.

    "! Generate file from query results (CSV -> GZIP -> ZDERS_FILE)
    METHODS generate_file
      IMPORTING
        ir_result    TYPE REF TO data
      RETURNING
        VALUE(rv_file_uuid) TYPE sysuuid_x16
      RAISING zcx_ders_job_error.

    "! Update job status in ZDERS_JOBHIST
    METHODS update_status
      IMPORTING
        iv_status        TYPE zders_jobhist-status
        iv_error_message TYPE zders_jobhist-error_message OPTIONAL
        iv_file_uuid     TYPE sysuuid_x16 OPTIONAL
        iv_rows          TYPE int8 OPTIONAL.

ENDCLASS.

CLASS zcl_ders_job_processor IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    " IF_APJ_DT_EXEC_OBJECT: Design-Time Parameter Definition
    et_parameter_def = VALUE #(
      ( selname        = 'P_JOBUUI'
        kind           = if_apj_dt_exec_object=>parameter
        param_text     = 'Job UUID'
        datatype       = 'C'
        length         = 32
        lowercase_ind  = abap_true
        changeable_ind = abap_true
        mandatory_ind  = abap_false )
    ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    " IF_APJ_RT_EXEC_OBJECT: Run-Time Job Execution
    " Extract P_JOBUUID from APJ parameters (as hex string)

    " Debug: Check what parameters we received
    DATA lv_debug_msg TYPE string.
    lv_debug_msg = |Params:{ lines( it_parameters ) }|.

    LOOP AT it_parameters INTO DATA(ls_debug).
      lv_debug_msg = lv_debug_msg && | { ls_debug-selname }={ ls_debug-low }|.
    ENDLOOP.

    READ TABLE it_parameters INTO DATA(ls_param)
      WITH KEY selname = 'P_JOBUUI'.
    IF sy-subrc <> 0.
      " Parameter not found - critical error in APJ framework
      " Cannot identify which job this is - exit immediately
      RETURN.
    ENDIF.

    " Convert hex string to RAW16
    DATA lv_uuid_str TYPE string.
    lv_uuid_str = ls_param-low.

    IF lv_uuid_str IS INITIAL.
      " UUID empty - critical error
      " Cannot identify which job this is - exit immediately
      RETURN.
    ENDIF.

    TRY.
        mv_job_uuid = CONV #( lv_uuid_str ).
      CATCH cx_root INTO DATA(lx_conv).
        " Cannot convert - try to update status if possible
        TRY.
            " Try string interpretation
            DATA lv_temp_uuid TYPE sysuuid_x16.
            lv_temp_uuid = lv_uuid_str.
            DATA(lv_conv_error) = |UUID conversion failed: { lx_conv->get_text( ) }. Received: { lv_uuid_str }|.
            " Truncate to 255 chars to avoid CX_SY_OPEN_SQL_DATA_ERROR
            IF strlen( lv_conv_error ) > 255.
              lv_conv_error = substring( val = lv_conv_error len = 255 ).
            ENDIF.
            UPDATE zders_jobhist SET
              status = 'F',
              error_message = @lv_conv_error
              WHERE job_uuid = @lv_temp_uuid.
          CATCH cx_root.
            " Cannot even update - just exit
        ENDTRY.
        RETURN.
    ENDTRY.

    TRY.
        " Step 1: Load all context data
        TRY.
            update_status( iv_status = 'R' iv_error_message = 'Loading context...' ).
          CATCH cx_root INTO DATA(lx_upd1).
            " Log if update_status itself fails
            DATA(lv_upd1_err) = |update_status failed: { lx_upd1->get_text( ) }|.
            IF strlen( lv_upd1_err ) > 255.
              lv_upd1_err = substring( val = lv_upd1_err len = 255 ).
            ENDIF.
            UPDATE zders_jobhist SET error_message = @lv_upd1_err WHERE job_uuid = @mv_job_uuid.
            RAISE EXCEPTION lx_upd1.
        ENDTRY.

        load_job_context( ).

        " Step 2: Mark job as Running
        update_status( iv_status = 'R' iv_error_message = 'Executing query...' ).

        " Step 3: Execute dynamic report query
        DATA lr_result TYPE REF TO data.
        DATA lv_rows TYPE int8.
        execute_report_query(
          IMPORTING
            et_result    = lr_result
            ev_row_count = lv_rows
        ).

        " Step 4: Generate file (CSV -> GZIP -> ZDERS_FILE)
        DATA lv_gen_msg TYPE zders_jobhist-error_message.
        lv_gen_msg = |Generating file ({ lv_rows } rows)...|.
        update_status( iv_status = 'R' iv_error_message = lv_gen_msg ).
        DATA(lv_file_uuid) = generate_file( ir_result = lr_result ).

        " Step 5: Mark job as Completed
        update_status(
          iv_status    = 'C'
          iv_rows      = lv_rows
          iv_file_uuid = lv_file_uuid
        ).

      CATCH zcx_ders_job_error INTO DATA(lx_error).
        " Mark job as Failed with error message
        " Truncate error text before passing to avoid overflow
        DATA(lv_error_msg) = lx_error->get_text( ).
        IF strlen( lv_error_msg ) > 255.
          lv_error_msg = substring( val = lv_error_msg len = 255 ).
        ENDIF.
        update_status(
          iv_status        = 'F'
          iv_error_message = CONV #( lv_error_msg )
        ).
      CATCH cx_root INTO DATA(lx_root).
        " Catch any other exception
        " Truncate error message BEFORE assigning to avoid overflow
        DATA(lv_error_text) = lx_root->get_text( ).
        DATA(lv_full_msg) = |Unexpected error: { lv_error_text }|.
        DATA lv_unexpected_error TYPE zders_jobhist-error_message.
        IF strlen( lv_full_msg ) > 255.
          lv_unexpected_error = substring( val = lv_full_msg len = 255 ).
        ELSE.
          lv_unexpected_error = lv_full_msg.
        ENDIF.
        update_status(
          iv_status        = 'F'
          iv_error_message = lv_unexpected_error
        ).
    ENDTRY.
  ENDMETHOD.

  METHOD load_job_context.
    " Load Job Context: JOBHIST -> CATALOG -> JOB_PARAM -> PARAM
    " Read Job History record
    SELECT SINGLE * FROM zders_jobhist
      WHERE job_uuid = @mv_job_uuid
      INTO @ms_job.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_ders_job_error
        EXPORTING
          textid  = zcx_ders_job_error=>job_not_found
          message = |Job UUID '{ mv_job_uuid }' not found in ZDERS_JOBHIST|.
    ENDIF.

    " Read Report Catalog (to get CDS view name)
    SELECT SINGLE * FROM zders_catalog
      WHERE report_id = @ms_job-report_id
      INTO @ms_catalog.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_ders_job_error
        EXPORTING
          textid  = zcx_ders_job_error=>report_not_found
          message = |Report '{ ms_job-report_id }' not found in ZDERS_CATALOG|.
    ENDIF.

    " Read structured job parameters (created by Scheduler)
    SELECT * FROM zders_job_param
      WHERE parent_uuid = @mv_job_uuid
      ORDER BY item_no
      INTO TABLE @mt_job_params.

    " Read parameter definitions (for field name mapping)
    SELECT * FROM zders_param
      WHERE report_id = @ms_job-report_id
      ORDER BY param_seq
      INTO TABLE @mt_param_defs.
  ENDMETHOD.

  METHOD execute_report_query.
    " Execute Report Query with dynamic SELECT
    " Build WHERE clause (type S/R/M) and CDS parameter string (type P)
    DATA(lv_where) = zcl_ders_query_builder=>build_where_clause(
      it_job_params = mt_job_params
      it_param_defs = mt_param_defs
    ).

    DATA(lv_cds_params) = zcl_ders_query_builder=>build_cds_params(
      it_job_params = mt_job_params
      it_param_defs = mt_param_defs
    ).

    " Get CDS view name from catalog
    DATA(lv_cds_name) = to_upper( ms_catalog-cds_view_name ).

    " Append CDS input parameters if any (e.g. '( P_KeyDate = ''20260313'' )')
    DATA(lv_cds_full) = COND string(
      WHEN lv_cds_params IS NOT INITIAL
      THEN lv_cds_name && lv_cds_params
      ELSE lv_cds_name
    ).

    " Create dynamic result table - RTTI must use plain view name (no params)
    DATA lr_table TYPE REF TO data.
    TRY.
        cl_abap_typedescr=>describe_by_name(
          EXPORTING  p_name         = lv_cds_name
          RECEIVING  p_descr_ref    = DATA(lo_descr)
          EXCEPTIONS type_not_found = 1 ).

        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE zcx_ders_job_error
            EXPORTING
              textid  = zcx_ders_job_error=>cds_view_not_found
              message = |CDS View '{ lv_cds_name }' not found in system|.
        ENDIF.

        DATA(lo_struct) = CAST cl_abap_structdescr( lo_descr ).
        DATA(lo_table)  = cl_abap_tabledescr=>create( p_line_type = lo_struct ).
        CREATE DATA lr_table TYPE HANDLE lo_table.

      CATCH cx_root INTO DATA(lx_type).
        RAISE EXCEPTION TYPE zcx_ders_job_error
          EXPORTING
            textid  = zcx_ders_job_error=>cds_view_not_found
            message = |Error creating dynamic table for '{ lv_cds_name }': { lx_type->get_text( ) }|.
    ENDTRY.

    " Execute dynamic SELECT with optional CDS params and WHERE clause
    FIELD-SYMBOLS <lt_result> TYPE STANDARD TABLE.
    ASSIGN lr_table->* TO <lt_result>.

    TRY.
        IF lv_where IS NOT INITIAL.
          SELECT * FROM (lv_cds_full)
            WHERE (lv_where)
            INTO TABLE @<lt_result>.
        ELSE.
          SELECT * FROM (lv_cds_full)
            INTO TABLE @<lt_result>.
        ENDIF.
      CATCH cx_sy_open_sql_data_error INTO DATA(lx_sql).
        RAISE EXCEPTION TYPE zcx_ders_job_error
          EXPORTING
            textid  = zcx_ders_job_error=>query_error
            message = |SQL error: { lx_sql->get_text( ) }. FROM: { lv_cds_full } WHERE: { lv_where }|.
      CATCH cx_sy_dynamic_osql_error INTO DATA(lx_dyn).
        RAISE EXCEPTION TYPE zcx_ders_job_error
          EXPORTING
            textid  = zcx_ders_job_error=>query_error
            message = |Dynamic SQL error: { lx_dyn->get_text( ) }. FROM: { lv_cds_full } WHERE: { lv_where }|.
    ENDTRY.

    ev_row_count = lines( <lt_result> ).
    et_result = lr_table.
  ENDMETHOD.

  METHOD generate_file.
    " Generate File: CSV -> UTF-8 -> GZIP -> ZDERS_FILE
    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN ir_result->* TO <lt_data>.

    " Step 1: Get table structure via RTTI
    DATA(lo_table_descr) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data_ref( ir_result ) ).
    DATA(lo_struct) = CAST cl_abap_structdescr( lo_table_descr->get_table_line_type( ) ).
    DATA(lt_components) = lo_struct->get_components( ).

    " Step 2: Build CSV header row
    DATA lv_csv TYPE string.
    DATA lv_sep TYPE string.
    LOOP AT lt_components INTO DATA(ls_comp).
      lv_csv = |{ lv_csv }{ lv_sep }{ ls_comp-name }|.
      lv_sep = ';'.    " Semicolon = safe delimiter
    ENDLOOP.
    lv_csv = lv_csv && cl_abap_char_utilities=>cr_lf.

    " Step 3: Build CSV data rows
    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
      CLEAR lv_sep.
      LOOP AT lt_components INTO ls_comp.
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE <ls_row>
          TO FIELD-SYMBOL(<lv_val>).
        IF sy-subrc = 0.
          DATA(lv_str_val) = CONV string( <lv_val> ).
          " Escape values containing delimiter or quotes
          IF lv_str_val CS ';' OR lv_str_val CS '"'
             OR lv_str_val CS cl_abap_char_utilities=>cr_lf.
            REPLACE ALL OCCURRENCES OF '"' IN lv_str_val WITH '""'.
            lv_str_val = |"{ lv_str_val }"|.
          ENDIF.
          lv_csv = |{ lv_csv }{ lv_sep }{ lv_str_val }|.
        ELSE.
          lv_csv = |{ lv_csv }{ lv_sep }|.
        ENDIF.
        lv_sep = ';'.
      ENDLOOP.
      lv_csv = lv_csv && cl_abap_char_utilities=>cr_lf.
    ENDLOOP.

    " Step 4: Convert CSV string to XSTRING (UTF-8)
    DATA lv_xstring TYPE xstring.
    DATA(lo_conv) = cl_abap_conv_codepage=>create_out( codepage = 'UTF-8' ).
    lv_xstring = lo_conv->convert( lv_csv ).
    DATA(lv_original_size) = xstrlen( lv_xstring ).

    " Step 5: Build metadata
    DATA(lv_file_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
    DATA(lv_now) = VALUE timestampl( ).
    GET TIME STAMP FIELD lv_now.

    DATA(lv_extension) = COND string(
      WHEN ms_job-output_format = 'XLSX' THEN 'xlsx'
      WHEN ms_job-output_format = 'PDF'  THEN 'pdf'
      ELSE 'csv'
    ).

    DATA(lv_mime) = COND string(
      WHEN ms_job-output_format = 'XLSX'
        THEN 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      WHEN ms_job-output_format = 'PDF'
        THEN 'application/pdf'
      ELSE 'text/csv'
    ).

    DATA(lv_filename) = |{ ms_job-report_id }_{ sy-datum }_{ sy-uzeit }.{ lv_extension }|.

    " Step 6: INSERT into ZDERS_FILE
    INSERT INTO zders_file VALUES @( VALUE #(
      file_uuid       = lv_file_uuid
      job_uuid        = mv_job_uuid
      file_name       = lv_filename
      file_extension  = lv_extension
      file_size_bytes = lv_original_size
      mime_type       = lv_mime
      file_content    = lv_xstring
      compressed_size = 0
      is_compressed   = abap_false
      download_count  = 0
      created_by      = sy-uname
      created_at      = lv_now
    ) ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_ders_job_error
        EXPORTING
          textid  = zcx_ders_job_error=>query_error
          message = |File INSERT into ZDERS_FILE failed (sy-subrc={ sy-subrc }). job_uuid={ mv_job_uuid }|.
    ENDIF.

    " Step 8: Return file UUID (JOBHIST updated by update_status 'C')
    rv_file_uuid = lv_file_uuid.
  ENDMETHOD.

  METHOD update_status.
    " Update job status in ZDERS_JOBHIST
    DATA lv_now TYPE timestampl.
    GET TIME STAMP FIELD lv_now.

    " Truncate error message to field max length (255 chars)
    DATA lv_safe_msg TYPE zders_jobhist-error_message.
    lv_safe_msg = iv_error_message.

    IF lv_safe_msg IS NOT INITIAL AND strlen( lv_safe_msg ) > 255.
      lv_safe_msg = substring( val = lv_safe_msg len = 255 ).
    ENDIF.

    TRY.
        CASE iv_status.
          WHEN 'R'.  " Running
            UPDATE zders_jobhist SET
              status        = @iv_status,
              started_ts    = @lv_now,
              error_message = @lv_safe_msg
              WHERE job_uuid = @mv_job_uuid.

          WHEN 'C'.  " Completed
            UPDATE zders_jobhist SET
              status         = @iv_status,
              completed_ts   = @lv_now,
              rows_processed = @iv_rows,
              file_uuid      = @iv_file_uuid,
              error_message  = ''
              WHERE job_uuid = @mv_job_uuid.

          WHEN 'F'.  " Failed
            UPDATE zders_jobhist SET
              status         = @iv_status,
              completed_ts   = @lv_now,
              error_message  = @lv_safe_msg
              WHERE job_uuid = @mv_job_uuid.
        ENDCASE.
      CATCH cx_sy_open_sql_data_error INTO DATA(lx_sql).
        " If UPDATE still fails (e.g., data too long), log to system
        " Cannot update job record - silent failure
        " This should never happen with truncation above
      CATCH cx_root INTO DATA(lx_any).
        " Catch any other DB error
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

