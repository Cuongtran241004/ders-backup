CLASS zcl_ders_crypto DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " 1. Tạo Checksum (SHA-256) bằng Secret Key
    CLASS-METHODS generate_checksum
      IMPORTING iv_data        TYPE string
      RETURNING VALUE(rv_hash) TYPE string.

    " 2. Mã hóa JSON sang Base64 (URL Safe)
    CLASS-METHODS encrypt_base64
      IMPORTING iv_json       TYPE string
      RETURNING VALUE(rv_b64) TYPE string.

    " 3. Giải mã Base64 về JSON
    CLASS-METHODS decrypt_base64
      IMPORTING iv_b64         TYPE string
      RETURNING VALUE(rv_json) TYPE string.

    CLASS-METHODS get_gateway_url
      RETURNING VALUE(rv_url) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS: mc_secret_key TYPE xstring VALUE 'DERS_SECRET_KEY_2026!@#'.
ENDCLASS.



CLASS zcl_ders_crypto IMPLEMENTATION.
  METHOD decrypt_base64.
    " 1. Khôi phục lại chuỗi Base64 từ định dạng URL-Safe
    DATA(lv_b64) = cl_http_utility=>unescape_url( escaped = iv_b64 ).

    " 2. Giải mã Base64 thành chuỗi JSON gốc
    rv_json = cl_http_utility=>decode_base64( encoded = lv_b64 ).
  ENDMETHOD.

  METHOD encrypt_base64.
    " Chuyển String thành Base64
    rv_b64 = cl_http_utility=>encode_base64( unencoded = iv_json ).
    " Chuyển thành URL-Safe (Thay thế các ký tự +, /, = để không bị lỗi trên trình duyệt)
    rv_b64 = escape( val = rv_b64 format = cl_abap_format=>e_url ).
  ENDMETHOD.

  METHOD generate_checksum.
    " Băm dữ liệu bằng thuật toán HMAC-SHA256
    TRY.
        cl_abap_hmac=>calculate_hmac_for_char(
          EXPORTING
            if_algorithm     = 'SHA256'
            if_key           = mc_secret_key
            if_data          = iv_data
          IMPORTING
            ef_hmacb64string = rv_hash
        ).
      CATCH cx_root.
        rv_hash = 'ERROR_HASH'.
    ENDTRY.
  ENDMETHOD.

  METHOD get_gateway_url.
    " Lấy URL từ bảng cấu hình hoặc Hardcode theo hệ thống
    rv_url = 'https://sap.company.com/ders'.
  ENDMETHOD.

ENDCLASS.
