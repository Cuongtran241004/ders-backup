CLASS zcl_test_fr52_token DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_fr52_token IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA: lv_job_uuid TYPE sysuuid_x16,
          lo_link_mgr TYPE REF TO zcl_ders_email_link.

    " 1. Lấy đại một Job UUID có sẵn trong hệ thống để test
    SELECT SINGLE job_uuid FROM zders_jobhist INTO @lv_job_uuid.

    IF sy-subrc <> 0.
      out->write( 'Bảng ZDERS_JOBHIST đang trống. Vui lòng tạo 1 dòng dữ liệu mẫu trước.' ).
      RETURN.
    ENDIF.

    out->write( |--- BƯỚC 1: TẠO LINK DOWNLOAD ---| ).
    out->write( |Đang test với Job UUID: { lv_job_uuid }| ).

    " Khởi tạo Manager và tạo Link
    lo_link_mgr = NEW #( ).
    DATA(lv_download_link) = lo_link_mgr->generate_download_link( lv_job_uuid ).

    " Chốt lưu vào Database
    COMMIT WORK AND WAIT.

    out->write( '=> Link tải xuống đã được sinh ra:' ).
    out->write( lv_download_link ).
    out->write( |\n| ).


    " 2. Kiểm tra trong Database xem có lưu chưa
    out->write( |--- BƯỚC 2: KIỂM TRA DATABASE ---| ).
    " Dùng Regex (biểu thức chính quy) để cắt lấy cái Token loằng ngoằng nằm sau chữ 'token='
    FIND REGEX 'token=(.*)' IN lv_download_link SUBMATCHES DATA(lv_token).

    IF lv_token IS NOT INITIAL.
      SELECT SINGLE * FROM zders_dl_token
        WHERE token = @lv_token
        INTO @DATA(ls_db_token).

      IF sy-subrc = 0.
         out->write( '=> THÀNH CÔNG! Token đã được lưu an toàn vào bảng ZDERS_DL_TOKEN.' ).
         out->write( |=> Ngày hết hạn (Expiry): { ls_db_token-expires_at }| ).
      ELSE.
         out->write( '=> LỖI: Không tìm thấy Token trong DB. Hãy kiểm tra lại lệnh MODIFY.' ).
      ENDIF.
      out->write( |\n| ).


      " 3. Test giải mã và Validate Token (Giả lập lúc User click vào link)
      out->write( |--- BƯỚC 3: GIẢ LẬP USER CLICK LINK ---| ).
      TRY.
          " Hàm validate sẽ giải mã Base64 -> Check Hạn 30 ngày -> Check Chữ ký Hash -> Trả về UUID
          DATA(lv_validated_uuid) = lo_link_mgr->validate_download_token( lv_token ).

          out->write( '=> XÁC THỰC THÀNH CÔNG! Token hoàn toàn hợp lệ.' ).
          out->write( |=> Hệ thống đã giải mã ngược ra Job UUID: { lv_validated_uuid }| ).

          IF lv_validated_uuid = lv_job_uuid.
             out->write( '=> CHUẨN XÁC 100%: UUID giải mã hoàn toàn khớp với ban đầu!' ).
          ENDIF.

        CATCH zcx_ders_invalid_token INTO DATA(lx_error).
          " Nếu bạn bị nhảy vào đây kèm lỗi "Not Authorized",
          " có nghĩa là tài khoản SAP của bạn chưa được phân quyền Object 'Z_DERS_USER' cho Bukrs tương ứng.
          out->write( |=> LỖI XÁC THỰC TOKEN: { lx_error->get_text( ) }| ).
      ENDTRY.

    ENDIF.
  ENDMETHOD.

ENDCLASS.
