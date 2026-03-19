CLASS zcl_debug_job DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_debug_job IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " Get the latest job
    SELECT job_uuid, job_type, report_id, status, error_message,
           bg_job_name, bg_job_count, created_at
      FROM zders_jobhist
      ORDER BY created_at DESCENDING
      INTO TABLE @DATA(lt_jobs)
      UP TO 1 ROWS.

    IF lt_jobs IS NOT INITIAL.
      READ TABLE lt_jobs INDEX 1 INTO DATA(ls_job).

      out->write( |Job UUID (RAW16): { ls_job-job_uuid }| ).

      " Convert to hex string
      DATA(lv_hex) = CONV string( ls_job-job_uuid ).
      out->write( |Job UUID (HEX32): { lv_hex }| ).
      out->write( |Length: { strlen( lv_hex ) }| ).

      out->write( |---| ).
      out->write( |Job Type: { ls_job-job_type }| ).
      out->write( |Report ID: { ls_job-report_id }| ).
      out->write( |Status: { ls_job-status }| ).
      out->write( |Error: { ls_job-error_message }| ).
      out->write( |BG Job Name: { ls_job-bg_job_name }| ).
      out->write( |BG Job Count: { ls_job-bg_job_count }| ).
      out->write( |---| ).

      " Check if report catalog exists
      SELECT SINGLE * FROM zders_catalog
        WHERE report_id = @ls_job-report_id
        INTO @DATA(ls_cat).

      IF sy-subrc = 0.
        out->write( |Catalog found: { ls_cat-report_name }| ).
        out->write( |CDS View: { ls_cat-cds_view_name }| ).
      ELSE.
        out->write( |ERROR: Catalog not found for report_id: { ls_job-report_id }| ).
      ENDIF.

      " Check job parameters
      SELECT * FROM zders_job_param
        WHERE parent_uuid = @ls_job-job_uuid
        INTO TABLE @DATA(lt_params).

      out->write( |Job parameters: { lines( lt_params ) }| ).
      LOOP AT lt_params INTO DATA(ls_param).
        out->write( |  - { ls_param-param_name }: { ls_param-param_value_from }| ).
      ENDLOOP.

      " Check files
      SELECT * FROM zders_file
        WHERE job_uuid = @ls_job-job_uuid
        INTO TABLE @DATA(lt_files).

      IF lt_files IS NOT INITIAL.
        LOOP AT lt_files INTO DATA(ls_file).
          out->write( |File: { ls_file-file_name } ({ xstrlen( ls_file-file_content ) } bytes)| ).
        ENDLOOP.
      ELSE.
        out->write( 'No files created' ).
      ENDIF.

    ELSE.
      out->write( 'No jobs found' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

