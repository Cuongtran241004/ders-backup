CLASS lhc_AgingSummary DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS calculateAging FOR MODIFY
      IMPORTING keys FOR ACTION AgingSummary~calculateAging RESULT result.
ENDCLASS.

CLASS lhc_AgingSummary IMPLEMENTATION.

  METHOD calculateAging.
    " 1. Lấy tham số từ Popup
    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    IF sy-subrc <> 0. RETURN. ENDIF.

    " Kiểm tra chính xác tên parameter trong Abstract Entity của bạn (thường là viết hoa/thường)
    DATA(lv_bukrs)      = ls_key-%param-company_code.
    DATA(lv_kunnr)      = ls_key-%param-customer.
    DATA(lv_key_date)  = ls_key-%param-key_date.
    DATA(lv_base_date) = ls_key-%param-base_date.

    " 2. Truy vấn dữ liệu từ VIEW TỔNG HỢP (CUST) thay vì View chi tiết (V2)
    " Để kết quả trả về khớp với bảng người dùng đang nhìn thấy
    SELECT * FROM zi_ders_ar03_cust( p_keydate = @lv_key_date, p_basedate = @lv_base_date )
    WHERE ( companycode = @lv_bukrs OR @lv_bukrs = '' )
        AND ( customer    = @lv_kunnr OR @lv_kunnr = '' )
      INTO TABLE @DATA(lt_summary_data).

    " 3. Trả kết quả về cho UI
    LOOP AT lt_summary_data ASSIGNING FIELD-SYMBOL(<fs_data>).

      APPEND VALUE #(
        %param = CORRESPONDING #( <fs_data> )
      ) TO result.

    ENDLOOP.

    " Lưu ý: Với báo cáo Read-only, bạn có thể không cần dùng bảng 'mapped'
    " trừ khi bạn thực hiện tạo mới instance (Factory Action).
    " Việc đổ dữ liệu vào 'result' là đủ để Fiori Elements refresh lại bảng.

  ENDMETHOD.

ENDCLASS.
