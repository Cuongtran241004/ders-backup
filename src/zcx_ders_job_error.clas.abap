"!──────────────────────────────────────────────────────────────────────────────
"! CLASS: ZCX_DERS_JOB_ERROR
"! PURPOSE: Exception class for DERS background job processing errors
"! NOTE: Must be created FIRST as other classes depend on it
"!──────────────────────────────────────────────────────────────────────────────
CLASS zcx_ders_job_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF job_not_found,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF job_not_found,

      BEGIN OF report_not_found,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF report_not_found,

      BEGIN OF cds_view_not_found,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF cds_view_not_found,

      BEGIN OF subscription_not_found,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF subscription_not_found,

      BEGIN OF export_not_found,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF export_not_found,

      BEGIN OF scheduling_failed,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF scheduling_failed,

      BEGIN OF query_error,
        msgid TYPE symsgid VALUE 'ZDERS',
        msgno TYPE symsgno VALUE '007',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF query_error.

    DATA mv_message TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL
        message  TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

ENDCLASS.

CLASS zcx_ders_job_error IMPLEMENTATION.

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

