"!──────────────────────────────────────────────────────────────────────────────
"! CLASS: ZCX_DERS_INVALID_TOKEN
"! PURPOSE: Exception class for DERS Download Token validation errors
"!──────────────────────────────────────────────────────────────────────────────
CLASS zcx_ders_invalid_token DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    CONSTANTS:
      " Lỗi khi Token bị sai cấu trúc JSON hoặc Base64
      BEGIN OF invalid_format,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '010', " Bạn có thể đổi mã số này cho khớp với SE91
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_format,

      " Lỗi khi Token đã quá hạn 30 ngày
      BEGIN OF token_expired,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '011',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF token_expired,

      " Lỗi khi Checksum không khớp (Dữ liệu bị sửa đổi trái phép)
      BEGIN OF tampered,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '012',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF tampered,

      " Lỗi khi User click link nhưng không có quyền với Company Code đó
      BEGIN OF not_authorized,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '013',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF not_authorized.

    DATA mv_message TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL
        message  TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

ENDCLASS.

CLASS zcx_ders_invalid_token IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING previous = previous.
    CLEAR me->textid.
    IF textid IS NOT INITIAL.
      if_t100_message~t100key = textid.
    ENDIF.
    mv_message = message.
  ENDMETHOD.

  METHOD get_text.
    IF mv_message IS NOT INITIAL.
      result = mv_message.
    ELSE.
      result = super->get_text( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
