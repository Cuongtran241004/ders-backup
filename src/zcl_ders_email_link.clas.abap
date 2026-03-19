CLASS zcl_ders_email_link DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " Khai báo cấu trúc cho JSON Token
    TYPES: BEGIN OF ty_token,
             job_id     TYPE string, " Chuyển UUID sang String để dễ serialize JSON
             user_id    TYPE syuname,
             company_code TYPE bukrs,
             expires_at TYPE string, " Dùng string cho ngày giờ an toàn khi parse JSON
             checksum   TYPE string,
           END OF ty_token.

     " Khai báo phương thức generate link
    METHODS generate_download_link
      IMPORTING iv_job_uuid TYPE sysuuid_x16
      RETURNING VALUE(rv_link) TYPE string.

    METHODS validate_download_token
      IMPORTING iv_token           TYPE string
      RETURNING VALUE(rv_job_uuid) TYPE sysuuid_x16
      RAISING   cx_static_check.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ders_email_link IMPLEMENTATION.
  METHOD generate_download_link.
    DATA: lv_token      TYPE string,
          lv_now        TYPE timestampl,
          lv_expiry     TYPE timestampl,
          ls_token_data TYPE ty_token.

    " 1. Lấy thông tin Job để nhét vào Token
    SELECT SINGLE bukrs FROM zders_jobhist WHERE job_uuid = @iv_job_uuid INTO @DATA(lv_bukrs).

    " 2. Tính toán Expiry (30 ngày = 2.592.000 giây) - CÁCH ĐÚNG TRONG ABAP
    GET TIME STAMP FIELD lv_now.
    TRY.
        cl_abap_tstmp=>add( EXPORTING tstmp = lv_now secs = 2592000 RECEIVING r_tstmp = lv_expiry ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        lv_expiry = lv_now.
    ENDTRY.

    " 3. Build token data
    DATA(lv_job_uuid_str) = CONV string( iv_job_uuid ).

    ls_token_data = VALUE #(
      job_id       = lv_job_uuid_str
      user_id      = sy-uname
      company_code = lv_bukrs
      expires_at   = |{ lv_expiry }|
      " Dùng cả job_id và user_id để tạo Checksum nhằm chống giả mạo chéo
      checksum     = zcl_ders_crypto=>generate_checksum( |{ lv_job_uuid_str }{ sy-uname }{ lv_bukrs }| )
    ).

    " 4. Encrypt token (JSON -> Base64)
    DATA(lv_json) = /ui2/cl_json=>serialize( ls_token_data ).
    lv_token = zcl_ders_crypto=>encrypt_base64( lv_json ).

    " 5. Build URL
    rv_link = |{ zcl_ders_crypto=>get_gateway_url( ) }/download?token={ lv_token }|.

    " 6. Store token mapping (Vào bảng zders_dl_token đã định nghĩa ở FR trước)
    DATA(ls_db_token) = VALUE zders_dl_token(
      token          = lv_token
      job_uuid       = iv_job_uuid
      created_at     = lv_now
      expires_at     = lv_expiry
      download_count = 0
    ).
    MODIFY zders_dl_token FROM @ls_db_token.
    " Không dùng COMMIT WORK ở đây vì ta sẽ gọi nó trong Determination (Late Save)
  ENDMETHOD.

  METHOD validate_download_token.
    DATA: ls_token_data   TYPE ty_token,
          lv_current_time TYPE timestampl.

    " 1. Decrypt token
    DATA(lv_json) = zcl_ders_crypto=>decrypt_base64( iv_token ).
    IF lv_json IS INITIAL.
      " Ném ngoại lệ cơ bản của SAP
      RAISE EXCEPTION TYPE ZCX_DERS_INVALID_TOKEN.
    ENDIF.

    /ui2/cl_json=>deserialize(
      EXPORTING json = lv_json
      CHANGING  data = ls_token_data
    ).

    " 2. Check expiry
    GET TIME STAMP FIELD lv_current_time.
    DATA(lv_token_expiry) = CONV timestampl( ls_token_data-expires_at ).

    IF lv_token_expiry < lv_current_time.
      " Token đã hết hạn
      RAISE EXCEPTION TYPE ZCX_DERS_INVALID_TOKEN. " Thay thế cho zcx_ders_invalid_token
    ENDIF.

    " 3. Check checksum (Chống giả mạo nội dung JSON)
    DATA(lv_expected_checksum) = zcl_ders_crypto=>generate_checksum( |{ ls_token_data-job_id }{ ls_token_data-user_id }{ ls_token_data-company_code }| ).
    IF ls_token_data-checksum <> lv_expected_checksum.
      RAISE EXCEPTION TYPE ZCX_DERS_INVALID_TOKEN.
    ENDIF.

    " 4. Verify user authorization (Quyền tải file của Company Code)
    AUTHORITY-CHECK OBJECT 'Z_DERS_USER'
      ID 'ACTVT' FIELD '03'
      ID 'BUKRS' FIELD ls_token_data-company_code.

    IF sy-subrc <> 0.
      " Ném lỗi: Không có quyền truy cập Data của Bukrs này
      RAISE EXCEPTION TYPE zcx_ders_invalid_token
        EXPORTING textid = zcx_ders_invalid_token=>not_authorized.
    ENDIF.

    " 5. Increment download count
    UPDATE zders_dl_token
      SET download_count = download_count + 1,
          last_download  = @lv_current_time
      WHERE token = @iv_token.
    COMMIT WORK AND WAIT.

    " 6. Trả về UUID hợp lệ để backend tiếp tục truy xuất file
    rv_job_uuid = CONV sysuuid_x16( ls_token_data-job_id ).
  ENDMETHOD.

ENDCLASS.
