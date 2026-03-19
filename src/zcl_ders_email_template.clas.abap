CLASS zcl_ders_email_template DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " Phương thức render HTML cho email thành công
    CLASS-METHODS render_completion_email
      IMPORTING
        is_job           TYPE zders_jobhist
        iv_file_size_mb  TYPE f OPTIONAL " Truyền dung lượng file (MB) vào đây
        iv_download_link TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)   TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ders_email_template IMPLEMENTATION.

  METHOD render_completion_email.
    DATA: lv_html      TYPE string,
          lv_start_d   TYPE d,
          lv_start_t   TYPE t,
          lv_end_d     TYPE d,
          lv_end_t     TYPE t,
          lv_duration  TYPE i.

    " 1. Xử lý thời gian và ngày tháng (Chuyển Timestamp sang Date/Time cục bộ)
    CONVERT TIME STAMP is_job-started_ts TIME ZONE sy-zonlo INTO DATE lv_start_d TIME lv_start_t.
    CONVERT TIME STAMP is_job-completed_ts TIME ZONE sy-zonlo INTO DATE lv_end_d TIME lv_end_t.

    " Tính thời gian chạy (giây)
    TRY.
        cl_abap_tstmp=>subtract(
          EXPORTING tstmp1 = is_job-completed_ts
                    tstmp2 = is_job-started_ts
          RECEIVING r_secs = lv_duration ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        lv_duration = 0.
    ENDTRY.

    " Định dạng thời gian chạy ra phút:giây
    DATA(lv_min) = lv_duration DIV 60.
    DATA(lv_sec) = lv_duration MOD 60.
    DATA(lv_duration_text) = |{ lv_min } minutes { lv_sec } seconds|.

    " Định dạng chuỗi ngày giờ hiển thị
    DATA(lv_end_string) = |{ lv_end_d DATE = ISO } { lv_end_t TIME = ISO }|.
    DATA(lv_start_string) = |{ lv_start_t TIME = ISO }|.

    " Định dạng số lượng dòng (VD: 1,234,567)
    DATA(lv_rows) = |{ is_job-rows_processed NUMBER = USER }|.

    " 2. Xây dựng nội dung HTML
    " -- Phần HEAD và STYLE --
    lv_html = |<!DOCTYPE html><html><head><style>| &&
              |body \{ font-family: Arial, sans-serif; \} | &&
              |.header \{ background-color: #0070C0; color: white; padding: 20px; \} | &&
              |.content \{ padding: 20px; \} | &&
              |.summary \{ background-color: #F0F0F0; padding: 15px; margin: 10px 0; \} | &&
              |.download-btn \{ background-color: #28a745; color: white; padding: 10px 20px; text-decoration: none; display: inline-block; border-radius: 4px; \} | &&
              |</style></head><body>|.

    " -- Phần HEADER --
    lv_html = lv_html &&
              |<div class="header">| &&
              |<h1>{ is_job-report_id } - Export Complete</h1>| &&
              |<p>Job ID: { is_job-job_id } \|  Completed: { lv_end_string }</p>| &&
              |</div>|.

    " -- Phần SUMMARY --
    lv_html = lv_html &&
              |<div class="content">| &&
              |<h2>Export Summary</h2>| &&
              |<div class="summary">| &&
              |<p><strong>Status:</strong> Completed Successfully &#10003;</p>| &&
              |<p><strong>Execution Time:</strong> { lv_start_string } - { lv_end_t TIME = ISO } ({ lv_duration_text })</p>| &&
              |<p><strong>Rows Processed:</strong> { lv_rows } rows</p>| &&
              |<p><strong>Output Format:</strong> { is_job-output_format }</p>|.

    IF iv_file_size_mb IS NOT INITIAL.
      lv_html = lv_html && |<p><strong>File Size:</strong> { iv_file_size_mb DECIMALS = 2 } MB</p>|.
    ENDIF.

    lv_html = lv_html && |</div>|.

    " -- Phần PARAMETERS --
    lv_html = lv_html && |<h2>Parameters</h2><ul>|.
    " Tạm thời in chuỗi JSON thô ra. (Nếu dự án có chuẩn JSON, ta có thể dùng /ui2/cl_json để parse và loop)
    IF is_job-param_json IS NOT INITIAL.
      lv_html = lv_html && |<li>Raw Parameters: { is_job-param_json }</li>|.
    ELSE.
      lv_html = lv_html && |<li>No parameters provided.</li>|.
    ENDIF.
    lv_html = lv_html && |</ul>|.

    " -- Phần DOWNLOAD --
    lv_html = lv_html && |<h2>Download Your Report</h2>|.

    IF iv_file_size_mb <= 10. " Nhỏ hơn hoặc bằng 10MB
      lv_html = lv_html && |<p>Your report is attached to this email.</p>|.
    ELSE.
      lv_html = lv_html && |<p>Your file is too large to attach. Please download it using the link below:</p>| &&
                           |<p><a href="{ iv_download_link }" class="download-btn">Download Report</a></p>| &&
                           |<p><small>Link expires in 30 days</small></p>|.
    ENDIF.

    " -- Phần FOOTER --
    lv_html = lv_html &&
              |<hr><p><small>Need help? Contact DERS-Fiori support \| <a href="https://sap.company.com/ders">Open DERS-Fiori</a></small></p>| &&
              |</div></body></html>|.

    rv_html = lv_html.
  ENDMETHOD.

ENDCLASS.
