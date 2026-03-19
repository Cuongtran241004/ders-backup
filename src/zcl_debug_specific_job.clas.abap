CLASS zcl_debug_specific_job DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_debug_specific_job IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " Debug latest job automatically
    SELECT job_uuid FROM zders_jobhist
      ORDER BY created_at DESCENDING
      INTO @DATA(lv_uuid)
      UP TO 1 ROWS.
    ENDSELECT.

    IF sy-subrc <> 0.
      out->write( 'ERROR: No jobs found in ZDERS_JOBHIST' ).
      RETURN.
    ENDIF.

    DATA(lv_uuid_hex) = CONV string( lv_uuid ).

    out->write( |===== JOB ANALYSIS: { lv_uuid_hex } =====| ).
    out->write( | | ).

    " 1. Get job from ZDERS_JOBHIST
    SELECT SINGLE * FROM zders_jobhist
      WHERE job_uuid = @lv_uuid
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      out->write( |ERROR: Job UUID not found in ZDERS_JOBHIST| ).
      out->write( |Searched for: { lv_uuid_hex }| ).

      " Show recent jobs for comparison
      out->write( | | ).
      out->write( |Recent jobs (last 5):| ).
      SELECT job_uuid, status, created_at, error_message
        FROM zders_jobhist
        ORDER BY created_at DESCENDING
        INTO TABLE @DATA(lt_recent)
        UP TO 5 ROWS.

      LOOP AT lt_recent INTO DATA(ls_recent).
        DATA(lv_recent_hex) = CONV string( ls_recent-job_uuid ).
        out->write( |  { lv_recent_hex } - Status:{ ls_recent-status } - { ls_recent-created_at }| ).
        IF ls_recent-error_message IS NOT INITIAL.
          out->write( |    Error: { ls_recent-error_message }| ).
        ENDIF.
      ENDLOOP.

      RETURN.
    ENDIF.

    " 2. Display Job Info
    out->write( |[JOB HEADER]| ).
    out->write( |  Job Type: { ls_job-job_type } (S=Subscription, D=Download, A=Ad-hoc)| ).
    out->write( |  Report ID: { ls_job-report_id }| ).
    out->write( |  Status: { ls_job-status } (S=Scheduled, R=Running, C=Completed, F=Failed)| ).
    out->write( |  Created: { ls_job-created_at } by { ls_job-created_by }| ).

    IF ls_job-started_ts IS NOT INITIAL.
      out->write( |  Started: { ls_job-started_ts }| ).
    ENDIF.

    IF ls_job-completed_ts IS NOT INITIAL.
      out->write( |  Completed: { ls_job-completed_ts }| ).
      IF ls_job-started_ts IS NOT INITIAL.
        DATA(lv_duration) = ls_job-completed_ts - ls_job-started_ts.
        out->write( |  Duration: { lv_duration } seconds| ).
      ENDIF.
    ENDIF.

    IF ls_job-error_message IS NOT INITIAL.
      out->write( |  ERROR MESSAGE: { ls_job-error_message }| ).
    ENDIF.

    out->write( |  BG Job Name: { ls_job-bg_job_name }| ).
    out->write( |  BG Job Count: { ls_job-bg_job_count }| ).
    out->write( |  Rows Processed: { ls_job-rows_processed }| ).
    out->write( | | ).

    " 3. Check Report Catalog
    out->write( |[REPORT CATALOG]| ).
    SELECT SINGLE * FROM zders_catalog
      WHERE report_id = @ls_job-report_id
      INTO @DATA(ls_cat).

    IF sy-subrc = 0.
      out->write( |  Report Name: { ls_cat-report_name }| ).
      out->write( |  CDS View: { ls_cat-cds_view_name }| ).
      out->write( |  Module: { ls_cat-module_id }| ).
      out->write( |  Active: { ls_cat-is_active }| ).
    ELSE.
      out->write( |  ERROR: Catalog not found!| ).
    ENDIF.
    out->write( | | ).

    " 4. Check Job Parameters
    out->write( |[JOB PARAMETERS]| ).
    SELECT * FROM zders_job_param
      WHERE parent_uuid = @lv_uuid
      ORDER BY item_no
      INTO TABLE @DATA(lt_params).

    IF lt_params IS INITIAL.
      out->write( |  No parameters found| ).
    ELSE.
      out->write( |  Count: { lines( lt_params ) } parameters| ).
      LOOP AT lt_params INTO DATA(ls_param).
        out->write( |  { ls_param-item_no }. { ls_param-param_name } ({ ls_param-param_type })| ).
        out->write( |     Label: { ls_param-param_label }| ).
        out->write( |     From: { ls_param-param_value_from }| ).
        IF ls_param-param_value_to IS NOT INITIAL.
          out->write( |     To:   { ls_param-param_value_to }| ).
        ENDIF.
      ENDLOOP.
    ENDIF.
    out->write( | | ).

    " 5. Check Files
    out->write( |[FILES GENERATED]| ).
    SELECT * FROM zders_file
      WHERE job_uuid = @lv_uuid
      INTO TABLE @DATA(lt_files).

    IF lt_files IS INITIAL.
      out->write( |  No files found for this job_uuid| ).

      " Check if file exists with different job_uuid
      SELECT COUNT(*) FROM zders_file INTO @DATA(lv_file_count).
      out->write( |  Total files in ZDERS_FILE: { lv_file_count }| ).

      " Show last file record
      SELECT * FROM zders_file
        ORDER BY created_at DESCENDING
        INTO TABLE @DATA(lt_recent_files)
        UP TO 1 ROWS.
      IF lt_recent_files IS NOT INITIAL.
        READ TABLE lt_recent_files INDEX 1 INTO DATA(ls_recent_file).
        DATA(lv_file_job_hex) = CONV string( ls_recent_file-job_uuid ).
        out->write( |  Last file record:| ).
        out->write( |    File UUID: { ls_recent_file-file_uuid }| ).
        out->write( |    Job UUID in FILE: { lv_file_job_hex }| ).
        out->write( |    Job UUID expected: { lv_uuid_hex }| ).
        out->write( |    Match: { COND string( WHEN lv_file_job_hex = lv_uuid_hex THEN 'YES' ELSE 'NO - MISMATCH!' ) }| ).
        out->write( |    FileName: { ls_recent_file-file_name }| ).
        out->write( |    CreatedAt: { ls_recent_file-created_at }| ).
      ENDIF.

      " Check file_uuid in jobhist
      out->write( | | ).
      out->write( |  JobHist file_uuid: { ls_job-file_uuid }| ).
      IF ls_job-file_uuid IS INITIAL.
        out->write( |  WARNING: file_uuid in JOBHIST is empty!| ).
      ENDIF.
    ELSE.
      out->write( |  Files: { lines( lt_files ) }| ).
      LOOP AT lt_files INTO DATA(ls_file).
        out->write( |  - { ls_file-file_name }| ).
        out->write( |    File UUID: { ls_file-file_uuid }| ).
        out->write( |    Job UUID: { ls_file-job_uuid }| ).
        out->write( |    Size: { ls_file-file_size_bytes } bytes (compressed: { ls_file-compressed_size })| ).
        out->write( |    Type: { ls_file-mime_type }| ).
        out->write( |    Downloads: { ls_file-download_count }| ).
      ENDLOOP.

      " Validate file_uuid in jobhist matches
      out->write( | | ).
      out->write( |  JobHist file_uuid: { ls_job-file_uuid }| ).
      READ TABLE lt_files INDEX 1 INTO DATA(ls_first_file).
      IF ls_job-file_uuid = ls_first_file-file_uuid.
        out->write( |  OK: file_uuid in JOBHIST matches FILE record| ).
      ELSE.
        out->write( |  WARNING: file_uuid MISMATCH between JOBHIST and FILE!| ).
      ENDIF.
    ENDIF.
    out->write( | | ).

    " 6. Check Parameter Definitions
    IF ls_cat-report_id IS NOT INITIAL.
      out->write( |[PARAMETER DEFINITIONS]| ).
      SELECT * FROM zders_param
        WHERE report_id = @ls_job-report_id
        ORDER BY param_seq
        INTO TABLE @DATA(lt_param_defs).

      IF lt_param_defs IS INITIAL.
        out->write( |  No parameter definitions| ).
      ELSE.
        out->write( |  Definitions: { lines( lt_param_defs ) }| ).
        LOOP AT lt_param_defs INTO DATA(ls_def).
          out->write( |  { ls_def-param_seq }. { ls_def-param_name } ({ ls_def-param_type })| ).
          out->write( |     Label: { ls_def-param_label }| ).
          out->write( |     Data Element: { ls_def-data_element }| ).
          out->write( |     Mandatory: { ls_def-is_mandatory }| ).
          IF ls_def-default_value IS NOT INITIAL.
            out->write( |     Default: { ls_def-default_value }| ).
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    out->write( | | ).
    out->write( |===== ANALYSIS COMPLETE =====| ).

    " 7. Re-build WHERE clause and test query
    IF ls_cat-report_id IS NOT INITIAL AND ls_cat-cds_view_name IS NOT INITIAL.
      out->write( |[WHERE CLAUSE DEBUG]| ).

      DATA(lv_where) = zcl_ders_query_builder=>build_where_clause(
        it_job_params = lt_params
        it_param_defs = lt_param_defs
      ).

      IF lv_where IS INITIAL.
        out->write( |  WHERE clause: (empty - no filter, selects ALL rows)| ).
      ELSE.
        out->write( |  WHERE clause: { lv_where }| ).
      ENDIF.

      DATA(lv_cds_params) = zcl_ders_query_builder=>build_cds_params(
        it_job_params = lt_params
        it_param_defs = lt_param_defs
      ).
      IF lv_cds_params IS INITIAL.
        out->write( |  CDS params:  (none)| ).
      ELSE.
        out->write( |  CDS params:  { lv_cds_params }| ).
      ENDIF.

      " Full FROM expression
      DATA(lv_cds) = to_upper( ls_cat-cds_view_name ).
      DATA(lv_cds_full) = COND string(
        WHEN lv_cds_params IS NOT INITIAL THEN lv_cds && lv_cds_params
        ELSE lv_cds
      ).
      out->write( |  Full FROM:    { lv_cds_full }| ).

      " Count rows in the CDS view
      DATA lr_test TYPE REF TO data.
      TRY.
          cl_abap_typedescr=>describe_by_name(
            EXPORTING  p_name         = lv_cds
            RECEIVING  p_descr_ref    = DATA(lo_d)
            EXCEPTIONS type_not_found = 1 ).

          IF sy-subrc = 0.
            DATA(lo_tbl) = cl_abap_tabledescr=>create(
              p_line_type = CAST cl_abap_structdescr( lo_d ) ).
            CREATE DATA lr_test TYPE HANDLE lo_tbl.
            FIELD-SYMBOLS <lt_test> TYPE STANDARD TABLE.
            ASSIGN lr_test->* TO <lt_test>.

            IF lv_where IS NOT INITIAL.
              SELECT * FROM (lv_cds_full) WHERE (lv_where)
                INTO TABLE @<lt_test> UP TO 5 ROWS.
            ELSE.
              SELECT * FROM (lv_cds_full)
                INTO TABLE @<lt_test> UP TO 5 ROWS.
            ENDIF.

            out->write( |  Test SELECT returned: { lines( <lt_test> ) } row(s) (max 5)| ).
            IF lines( <lt_test> ) = 0.
              out->write( |  WARNING: CDS view returns 0 rows - check BUKRS value or authorization!| ).
            ENDIF.
          ELSE.
            out->write( |  ERROR: CDS view '{ lv_cds }' not found via RTTI| ).
          ENDIF.
        CATCH cx_root INTO DATA(lx_dbg).
          out->write( |  ERROR running test query: { lx_dbg->get_text( ) }| ).
      ENDTRY.
      out->write( | | ).
    ENDIF.

    out->write( |===== ANALYSIS COMPLETE =====| ).
  ENDMETHOD.
ENDCLASS.

