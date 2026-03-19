CLASS zcl_ders_email_manager DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    " Khai báo phương thức gửi mail thành công
    METHODS send_completion_notification
      IMPORTING
        iv_job_uuid TYPE sysuuid_x16. " Thay kiểu dữ liệu cho đúng với kiểu của JobID trong bảng của bạn

    " Khai báo phương thức gửi mail báo lỗi
    METHODS send_error_notification
      IMPORTING
        iv_job_uuid TYPE sysuuid_x16. " Thay kiểu dữ liệu cho đúng với kiểu của JobID

  PROTECTED SECTION.
  PRIVATE SECTION.
    " Thêm dòng này vào phần Private Section
    METHODS get_email_from_uname
      IMPORTING iv_uname TYPE syuname
      RETURNING VALUE(rv_email) TYPE ad_smtpadr.
ENDCLASS.



CLASS zcl_ders_email_manager IMPLEMENTATION.

  METHOD send_completion_notification.
    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          lo_recipient    TYPE REF TO if_recipient_bcs,
          lx_bcs          TYPE REF TO cx_bcs,
          lt_body         TYPE bcsy_text.

    " 1. Đọc thông tin Job từ Database bằng Primary Key (job_uuid)
    SELECT SINGLE * FROM zders_jobhist
      WHERE job_uuid = @iv_job_uuid
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      RETURN. " Thoát nếu không tìm thấy dữ liệu
    ENDIF.


    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        " 2. Khởi tạo các Class phụ trợ (FR-051 & FR-052)
        DATA(lo_link_mgr) = NEW zcl_ders_email_link( ).
        DATA(lv_download_link) = lo_link_mgr->generate_download_link( iv_job_uuid ).

        " GIẢ ĐỊNH: Nếu bảng của bạn chưa có trường file_size, ta gán tạm 15MB để test.
        " Nếu bạn đã thêm trường file_size vào DB, hãy thay bằng: DATA(lv_file_size) = ls_job-file_size.
        DATA(lv_file_size) = CONV f( '15.0' ).

        " 3. Xây dựng nội dung HTML
        DATA(lv_html_string) = zcl_ders_email_template=>render_completion_email(
          is_job           = ls_job
          iv_file_size_mb  = lv_file_size
          iv_download_link = lv_download_link
        ).


        " Chuyển đổi an toàn String sang Bảng 255 ký tự (Tránh lỗi cắt HTML)
        lt_body = cl_document_bcs=>string_to_soli( lv_html_string ).
*        lt_body = VALUE #(
*          ( line = '<html><body>' )
*          ( line = |<p>Kính gửi { ls_job-user_id },</p>| )
*          ( line = |<p>Tiến trình xuất báo cáo <b>{ ls_job-report_id }</b> (Mã Job: { ls_job-job_id }) đã hoàn tất.</p>| )
*          ( line = |<ul>| )
*          ( line = |<li><b>Định dạng:</b> { ls_job-output_format }</li>| )
*          ( line = |<li><b>Số dòng dữ liệu:</b> { ls_job-rows_processed }</li>| )
*          ( line = |</ul>| )
*          ( line = '<p>Vui lòng kiểm tra file đính kèm hoặc truy cập hệ thống để tải xuống.</p>' )
*          ( line = '</body></html>' )
*        ).

        " 4. Tạo Document cho Email
        lo_document = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_subject = |DERS-Fiori: { ls_job-report_id } Export Complete|
          i_text    = lt_body
        ).

        " 5. Đính kèm File (Nếu file <= 10MB)
        IF lv_file_size <= 10.
          " Giả định bạn có một Class/Method đọc file nhị phân (XSTRING) từ bảng lưu trữ file
          " DATA(lv_file_xstring) = zcl_ders_file_utils=>read_file( ls_job-file_uuid ).

          " Nếu có dữ liệu file, convert và đính kèm:
          " DATA(lt_att_content) = cl_bcs_convert=>xstring_to_solix( lv_file_xstring ).
          " lo_document->add_attachment(
          "   i_attachment_type    = ls_job-output_format
          "   i_attachment_subject = |{ ls_job-report_id }_Job{ ls_job-job_id }|
          "   i_att_content_hex    = lt_att_content
          " ).
        ENDIF.

        lo_send_request->set_document( lo_document ).

        " 4. Xác định người nhận (Lấy email từ SAP User ID)
*        DATA(lv_user_email) = me->get_email_from_uname( ls_job-user_id ).
        DATA lv_user_email TYPE string VALUE 'hieunmse182322@fpt.edu.vn'.
        IF lv_user_email IS NOT INITIAL.
          lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( lv_user_email ) ).
          lo_send_request->add_recipient( lo_recipient ).
        ENDIF.

        " 5. Cấu hình gửi
        lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).
        lo_send_request->set_send_immediately( abap_true ).

        " 6. Thực thi gửi
        DATA(lv_sent) = lo_send_request->send( ).

        " Nếu gửi thành công, cập nhật cờ email_sent vào DB (Không commit ở đây)
        IF lv_sent = abap_true.
          UPDATE zders_jobhist
            SET email_sent = @abap_true
            WHERE job_uuid = @iv_job_uuid.
        ENDIF.

*        " 6. Xác định người nhận (TO) - Lấy từ User ID gốc
*        DATA(lv_user_email) = me->get_email_from_uname( ls_job-user_id ).
*        IF lv_user_email IS NOT INITIAL.
*          lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( lv_user_email ) ).
*          lo_send_request->add_recipient( lo_recipient ).
*        ENDIF.
*
*        " Gợi ý: Nếu bạn có thêm danh sách Email CC trong chuỗi param_json,
*        " bạn có thể parse JSON ra và gọi add_recipient( i_recipient = ... i_copy = abap_true ) tại đây.
*
*        " 7. Người gửi và Cấu hình gửi ngay lập tức
*        lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).
*        lo_send_request->set_send_immediately( abap_true ).
*
*        " 8. Thực thi gửi
*        DATA(lv_sent) = lo_send_request->send( ).
*
*        " 9. Ghi Log trạng thái gửi Mail vào bảng Job History
*        IF lv_sent = abap_true.
*          UPDATE zders_jobhist
*            SET email_sent = @abap_true
*            WHERE job_uuid = @iv_job_uuid.
*        ENDIF.
*
*        " Commit lưu log và chốt hàng đợi SOST
*        COMMIT WORK.

      CATCH cx_bcs INTO lx_bcs.
        " Xử lý log lỗi nếu gửi mail thất bại
    ENDTRY.

  ENDMETHOD.

  METHOD send_error_notification.
    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          lo_recipient    TYPE REF TO if_recipient_bcs,
          lx_bcs          TYPE REF TO cx_bcs,
          lt_body         TYPE bcsy_text.

    SELECT SINGLE * FROM zders_jobhist
      WHERE job_uuid = @iv_job_uuid
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        " 1. Xây dựng nội dung Email báo lỗi (Kèm mã lỗi và thông báo từ DB)
        lt_body = VALUE #(
          ( line = '<html><body>' )
          ( line = |<p>Kính gửi { ls_job-user_id },</p>| )
          ( line = |<p>Hệ thống đã gặp sự cố khi xử lý báo cáo <b>{ ls_job-report_id }</b> (Mã Job: { ls_job-job_id }).</p>| )
          ( line = |<p style="color:red;"><b>Chi tiết lỗi:</b> [{ ls_job-error_code }] { ls_job-error_message }</p>| )
          ( line = '<p>Vui lòng liên hệ bộ phận IT hoặc quản trị viên hệ thống để được hỗ trợ.</p>' )
          ( line = '</body></html>' )
        ).

        lo_document = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_subject = |[URGENT] Lỗi xử lý báo cáo DERS: { ls_job-report_id }|
          i_text    = lt_body
        ).
        lo_send_request->set_document( lo_document ).

        " 2. Người nhận: Gửi cho User
*        DATA(lv_user_email) = get_email_from_uname( ls_job-user_id ).
        DATA lv_user_email TYPE string VALUE 'hieunmse182322@fpt.edu.vn'.
        IF lv_user_email IS NOT INITIAL.
          lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( lv_user_email ) ).
          lo_send_request->add_recipient( lo_recipient ).
        ENDIF.

*        " 3. Người nhận: Gửi cho Admin (Yêu cầu của FR-050)
*        DATA(lo_admin) = cl_cam_address_bcs=>create_internet_address( 'admin.ders@yourcompany.com' ).
*        lo_send_request->add_recipient( i_recipient = lo_admin i_copy = abap_true ). " CC cho Admin

        " 4. Ưu tiên cao (Urgency: High)
*        lo_send_request->set_express( abap_true ).

        lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).
        lo_send_request->set_send_immediately( abap_true ).

        lo_send_request->send( ).

      CATCH cx_bcs INTO lx_bcs.
        " Xử lý log lỗi
    ENDTRY.
  ENDMETHOD.

  METHOD get_email_from_uname.
    " BAPI chuẩn của SAP để lấy địa chỉ email từ User Profile (SU01)
    DATA: lt_return TYPE TABLE OF bapiret2,
          lt_smtp   TYPE TABLE OF bapiadsmtp.

    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
      EXPORTING
        username = iv_uname
      TABLES
        return   = lt_return
        addsmtp  = lt_smtp.

    " Lấy địa chỉ email đầu tiên tìm thấy
    READ TABLE lt_smtp INTO DATA(ls_smtp) INDEX 1.
    IF sy-subrc = 0.
      rv_email = ls_smtp-e_mail.
    ENDIF.
  ENDMETHOD.



ENDCLASS.
