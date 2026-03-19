CLASS lhc_AgingReport DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS calculateAging FOR MODIFY
      IMPORTING keys FOR ACTION AgingReport~calculateAging RESULT result.
ENDCLASS.

CLASS lhc_AgingReport IMPLEMENTATION.

  METHOD calculateAging.
    " 1. Lấy tham số từ Popup
    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    IF sy-subrc <> 0. RETURN. ENDIF.

    DATA(lv_key_date)  = ls_key-%param-key_date.
    DATA(lv_base_date) = ls_key-%param-base_date.

    " 2. Truy vấn dữ liệu từ CDS View dựa trên Parameter người dùng nhập
    SELECT * FROM zi_ders_ar03_v2( p_keydate = @lv_key_date, p_basedate = @lv_base_date )
      INTO TABLE @DATA(lt_report_data).

    " 3. Trả kết quả về cho UI thông qua tham số RESULT
    " Đối với Factory Action, chúng ta cần map %cid_ref từ keys và dữ liệu vào result
    LOOP AT lt_report_data ASSIGNING FIELD-SYMBOL(<fs_data>).
      APPEND VALUE #(
        %param   = CORRESPONDING #( <fs_data> )
      ) TO result.

      APPEND VALUE #(
        CompanyCode = <fs_data>-CompanyCode
        FiscalYear  = <fs_data>-FiscalYear
        AccountingDocument = <fs_data>-AccountingDocument
        AccountingDocumentItem = <fs_data>-AccountingDocumentItem
        Ledger = <fs_data>-Ledger
      ) TO mapped-agingreport.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
