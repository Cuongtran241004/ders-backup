CLASS zcl_test_fr50 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_fr50 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: lv_job_uuid TYPE sysuuid_x16,
          ls_job TYPE zders_jobhist.

    "0. Clear data
    " Lệnh DELETE không có điều kiện WHERE sẽ xóa toàn bộ các dòng trong bảng
    DELETE FROM zders_jobhist.

    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
      out->write( 'Thành công! Đã xóa sạch toàn bộ dữ liệu trong bảng ZDERS_JOBHIST.' ).
    ELSE.
      out->write( 'Bảng hiện tại đang trống, không có dữ liệu nào để xóa.' ).
    ENDIF.

    " 1. Tự động tạo UUID mới cho Job
    TRY.
        ls_job-job_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        out->write( 'Lỗi tạo UUID' ).
        RETURN.
    ENDTRY.

    " 2. Điền dữ liệu giả (Dummy Data)
    ls_job-mandt          = sy-mandt.
    ls_job-job_id         = '99990001'.
    ls_job-report_id      = 'RPT_TEST_01'.
    ls_job-user_id        = sy-uname. " Lấy user hiện tại để trích xuất đúng email của bạn
    ls_job-output_format  = 'PDF'.

    " --- CHỌN KỊCH BẢN TEST Ở ĐÂY ---
    ls_job-status         = 'C'. " Đổi thành 'F' nếu muốn test kịch bản báo lỗi

    ls_job-rows_processed = 1500.
    ls_job-error_message  = 'Dữ liệu bị thiếu ở dòng 45'. " Chỉ dùng cho test 'F'
    ls_job-error_code     = 'ERR_001'.
    GET TIME STAMP FIELD ls_job-created_at.

    " 3. Insert dữ liệu vào Database
    INSERT zders_jobhist FROM @ls_job.
    IF sy-subrc = 0.
      COMMIT WORK.
      out->write( |Đã chèn dữ liệu giả thành công. UUID: { ls_job-job_uuid }| ).
    ELSE.
      out->write( 'Lỗi khi insert vào bảng. Có thể do trùng khóa.' ).
      RETURN.
    ENDIF.

    " 4. Gọi class quản lý Notification (FR-050) để test
    DATA(lo_notif_mgr) = NEW zcl_ders_email_manager( ).
    out->write( 'Đang kích hoạt gửi mail...' ).

    IF ls_job-status = 'C'.
      lo_notif_mgr->send_completion_notification( iv_job_uuid = ls_job-job_uuid ).
      out->write( 'Đã chạy method Thành Công (Success).' ).
    ELSEIF ls_job-status = 'F'.
      lo_notif_mgr->send_error_notification( iv_job_uuid = ls_job-job_uuid ).
      out->write( 'Đã chạy method Báo Lỗi (Failed).' ).
    ENDIF.

    out->write( 'Vui lòng kiểm tra T-Code SOST để xem kết quả.' ).

*    " 4. Lấy một Job UUID có sẵn trong database để test
*    " Ta sẽ lấy UUID vừa được sinh ra trước đó (Ưu tiên các dòng chưa có status 'C' hoặc 'F')
*    SELECT SINGLE job_uuid FROM zders_jobhist
*      WHERE status <> 'C' AND status <> 'F'
*      INTO @lv_job_uuid.
*
*    " Nếu không tìm thấy dòng nào chưa hoàn thành, lấy đại dòng đầu tiên
*    IF sy-subrc <> 0.
*      SELECT SINGLE job_uuid FROM zders_jobhist INTO @lv_job_uuid.
*      IF sy-subrc <> 0.
*        out->write( 'Không tìm thấy Job nào trong bảng. Vui lòng chạy lại class ZCL_TEST_FR50_DUMMY trước.' ).
*        RETURN.
*      ENDIF.
*    ENDIF.
*
*    out->write( |Đang giả lập Fiori App cập nhật Status cho Job UUID: { lv_job_uuid }| ).
*
*    " 5. Sử dụng EML để cập nhật trạng thái (Status)
*    " Hãy thay 'zi_ders_jobhistory' và 'JobHistory' bằng đúng tên trong BDEF của bạn nếu có khác biệt
*    MODIFY ENTITIES OF zi_ders_jobhistory
*      ENTITY JobHistory
*      UPDATE FIELDS ( Status )
*      WITH VALUE #( ( %tky-JobUuid = lv_job_uuid
*                      Status       = 'C' ) ) " Sửa thành 'F' để test kịch bản báo lỗi
*      FAILED DATA(ls_failed)
*      REPORTED DATA(ls_reported).
*
*    " 6. Kiểm tra xem lệnh MODIFY có hợp lệ không
*    IF ls_failed IS NOT INITIAL.
*      out->write( 'Thất bại tại bước MODIFY ENTITIES. Kiểm tra lại khóa chính hoặc Validation.' ).
*      RETURN.
*    ENDIF.
*
*    " 7. Thực thi COMMIT ENTITIES
*    " Lệnh này RẤT QUAN TRỌNG: Nó kích hoạt chuỗi Save Sequence và gọi hàm DETERMINATION "SendNotification" của bạn
*    COMMIT ENTITIES
*      RESPONSE OF zi_ders_jobhistory
*      FAILED DATA(ls_commit_failed)
*      REPORTED DATA(ls_commit_reported).
*
*
*
*    IF ls_commit_failed IS NOT INITIAL.
*      out->write( 'Lỗi khi COMMIT ENTITIES. Luồng Determination có thể bị lỗi.' ).
*    ELSE.
*      out->write( 'Thành công! Trạng thái đã được cập nhật thành ''C'' vào Database.' ).
*      out->write( '=> Luồng Determination ON SAVE đã được kích hoạt.' ).
*      out->write( '=> Hệ thống đang đẩy tác vụ gửi mail ra Background Task...' ).
*      out->write( 'Vui lòng đợi vài giây và mở T-Code SOST để xem thành quả!' ).
*    ENDIF.

    COMMIT WORK AND WAIT.

  ENDMETHOD.
ENDCLASS.
