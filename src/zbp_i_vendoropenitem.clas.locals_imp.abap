CLASS lhc_ZI_VENDOROPENITEM DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ zi_vendoropenitem RESULT result.

    METHODS ExportExcel FOR MODIFY
      IMPORTING keys FOR ACTION zi_vendoropenitem~ExportExcel RESULT result.

ENDCLASS.

CLASS lhc_ZI_VENDOROPENITEM IMPLEMENTATION.



METHOD ExportExcel.
    DATA: lt_items     TYPE TABLE OF ZI_VENDOROPENITEM,
          lv_uuid_x16  TYPE sysuuid_x16,
          lv_uuid_c36  TYPE sysuuid_c36,
          lv_file_name TYPE string.

    " 1. Đọc tham số từ Popup (ZPARA_ap01)
    " Lưu ý: Phải có khoảng trắng trong dấu ngoặc vuông [ 1 ]
    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_key>) INDEX 1.
    IF sy-subrc <> 0. RETURN. ENDIF.

    DATA(ls_para) = <ls_key>-%param.

    " 2. Truy vấn dữ liệu thực tế dựa trên tham số người dùng nhập
    SELECT * FROM ZI_VENDOROPENITEM
      WHERE CompanyCode = @ls_para-CompanyCode
        AND PostingDate <= @ls_para-KeyDate
        AND ( @ls_para-Vendor = '' OR Supplier = @ls_para-Vendor )
      INTO TABLE @lt_items.

    IF lt_items IS INITIAL.
      APPEND VALUE #( %cid = <ls_key>-%cid
                      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-warning
                                                    text     = 'Không có dữ liệu cho điều kiện đã chọn' ) ) TO reported-vendoropenitem.
      RETURN.
    ENDIF.

    TRY.
        " 3. Sử dụng abap2xlsx để tạo báo cáo
        DATA(lo_excel)     = NEW zcl_excel( ).
        DATA(lo_worksheet) = lo_excel->get_active_worksheet( ).
        lo_worksheet->set_title( 'AP Aging' ).

        " --- Định dạng Header chuẩn ---
        DATA(lo_style_header) = lo_excel->add_new_style( ).
        lo_style_header->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
        lo_style_header->fill->fgcolor-rgb = '0047AB'. " Màu xanh SAP
        lo_style_header->font->color-rgb   = zcl_excel_style_font=>c_family_modern.
        lo_style_header->font->bold        = abap_true.

        " --- Ghi tiêu đề báo cáo ---
        lo_worksheet->set_cell( ip_column = 'A' ip_row = 1 ip_value = 'BÁO CÁO CHI TIẾT CÔNG NỢ PHẢI TRẢ' ).
        lo_worksheet->set_cell( ip_column = 'A' ip_row = 2 ip_value = |Ngày chốt: { ls_para-KeyDate DATE = USER }| ).
        lo_worksheet->set_cell( ip_column = 'A' ip_row = 3 ip_value = |Công ty: { ls_para-CompanyCode }| ).

        " --- Đổ dữ liệu bảng từ dòng số 5 ---
        lo_worksheet->bind_table(
            ip_table          = lt_items
            is_table_settings = VALUE #( top_left_column = 'A' top_left_row = 5 table_style = zcl_excel_table=>builtinstyle_medium2 )
        ).

        " --- Render file sang Binary (XLSX) ---
        DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ).
        DATA(lv_file_content) = lo_writer->write_file( lo_excel ).

      CATCH cx_root INTO DATA(lo_err).
        APPEND VALUE #( %cid = <ls_key>-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Lỗi render Excel: ' && lo_err->get_text( ) ) ) TO reported-vendoropenitem.
        RETURN.
    ENDTRY.

    " 4. Lưu file vào Persistent Store (ZI_ExcelStore)
    lv_uuid_x16 = cl_system_uuid=>create_uuid_x16_static( ).
    lv_file_name = |AP_Report_{ ls_para-CompanyCode }_{ sy-datum }.xlsx|.

    INSERT zders_excelstore FROM @( VALUE #(
        file_id         = lv_uuid_x16
        attachment      = lv_file_content
        mimetype        = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        filename        = lv_file_name
        last_changed_at = cl_abap_context_info=>get_system_time( )
    ) ).

    " 5. Xây dựng URL Download (Chuyển GUID sang dạng C36 có dấu gạch ngang)
    cl_system_uuid=>convert_uuid_x16_static(
      EXPORTING uuid     = lv_uuid_x16
      IMPORTING uuid_c36 = lv_uuid_c36 ).

    " URL chuẩn OData V4 (Phải khớp với Service Binding đã Publish)
    DATA(lv_download_url) = |/sap/opu/odata4/sap/zui_vendor_openitem/srvd/sap/zui_vendor_openitem/0001/| &&
                        |ExcelStore(file_id={ lv_url_guid },IsActiveEntity=true)/attachment|.

    " 6. Trả kết quả về cho UI qua tham số result
    APPEND VALUE #( %cid   = <ls_key>-%cid
                    %param = VALUE #( file_id     = lv_uuid_x16
                                      DownloadUrl = lv_download_url ) ) TO result.

    " Hiển thị thông báo Toast thành công
    APPEND VALUE #( %cid = <ls_key>-%cid
                    %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                  text     = 'File Excel đã sẵn sàng!' ) ) TO reported-vendoropenitem.
ENDMETHOD.


METHOD read.
  " Đọc dữ liệu từ CDS View dựa trên các keys được truyền vào
  READ ENTITIES OF zi_vendoropenitem IN LOCAL MODE
    ENTITY zi_vendoropenitem
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_items)
    FAILED failed.

  " Trả kết quả về cho tham số result của phương thức
  result = CORRESPONDING #( lt_items ).
ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_VENDOROPENITEM DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_VENDOROPENITEM IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
