CLASS ZCL_DERS_JOB_CATALOG_TEMPLATE DEFINITION
    PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES IF_OO_ADT_CLASSRUN.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS ZCL_DERS_JOB_CATALOG_TEMPLATE IMPLEMENTATION.

  METHOD IF_OO_ADT_CLASSRUN~MAIN.

    CONSTANTS LC_CATALOG_NAME      TYPE CL_APJ_DT_CREATE_CONTENT=>TY_CATALOG_NAME  VALUE 'ZDERS_JOB_CATALOG_V2'.
    CONSTANTS LC_CATALOG_TEXT      TYPE CL_APJ_DT_CREATE_CONTENT=>TY_TEXT          VALUE 'My first simple application job'.
    CONSTANTS LC_CLASS_NAME        TYPE CL_APJ_DT_CREATE_CONTENT=>TY_CLASS_NAME    VALUE 'ZCL_DERS_JOB_BUSINESS_LOGIC'.

    CONSTANTS LC_TEMPLATE_NAME     TYPE CL_APJ_DT_CREATE_CONTENT=>TY_TEMPLATE_NAME VALUE 'ZDERS_JOB_TEMPLATE_V2'.
    CONSTANTS LC_TEMPLATE_TEXT     TYPE CL_APJ_DT_CREATE_CONTENT=>TY_TEXT          VALUE 'My first simple job template'.

    CONSTANTS LC_TRANSPORT_REQUEST TYPE CL_APJ_DT_CREATE_CONTENT=>TY_TRANSPORT_REQUEST VALUE 'S40K915426'.
    CONSTANTS LC_PACKAGE           TYPE CL_APJ_DT_CREATE_CONTENT=>TY_PACKAGE           VALUE 'ZPK_SP26_SAP01_DERS'.

    DATA(LO_DT) = CL_APJ_DT_CREATE_CONTENT=>GET_INSTANCE( ).

    " Create job catalog entry (corresponds to the former report incl. selection parameters)
    " Provided implementation class iv_class_name shall implement two interfaces:
    " - if_apj_dt_exec_object to provide the definition of all supported selection parameters of the job
    "   (corresponds to the former report selection parameters) and to provide the actual default values
    " - if_apj_rt_exec_object to implement the job execution
    TRY.
        LO_DT->CREATE_JOB_CAT_ENTRY(
            IV_CATALOG_NAME       = LC_CATALOG_NAME
            IV_CLASS_NAME         = LC_CLASS_NAME
            IV_TEXT               = LC_CATALOG_TEXT
            IV_CATALOG_ENTRY_TYPE = CL_APJ_DT_CREATE_CONTENT=>CLASS_BASED
            IV_TRANSPORT_REQUEST  = LC_TRANSPORT_REQUEST
            IV_PACKAGE            = LC_PACKAGE
        ).
        OUT->WRITE( |Job catalog entry created successfully| ).

      CATCH CX_APJ_DT_CONTENT INTO DATA(LX_APJ_DT_CONTENT).
        OUT->WRITE( |Creation of job catalog entry failed: { LX_APJ_DT_CONTENT->GET_TEXT( ) }| ).
    ENDTRY.

    " Create job template (corresponds to the former system selection variant) which is mandatory
    " to select the job later on in the Fiori app to schedule the job
    DATA LT_PARAMETERS TYPE IF_APJ_DT_EXEC_OBJECT=>TT_TEMPL_VAL.

*    NEW zcl_ders_job_business_logic( )->if_apj_dt_exec_object~get_parameters(
*      IMPORTING
*        et_parameter_val = lt_parameters
*    ).

    TRY.
        LO_DT->CREATE_JOB_TEMPLATE_ENTRY(
            IV_TEMPLATE_NAME     = LC_TEMPLATE_NAME
            IV_CATALOG_NAME      = LC_CATALOG_NAME
            IV_TEXT              = LC_TEMPLATE_TEXT
            IT_PARAMETERS        = LT_PARAMETERS
            IV_TRANSPORT_REQUEST = LC_TRANSPORT_REQUEST
            IV_PACKAGE           = LC_PACKAGE
        ).
        OUT->WRITE( |Job template created successfully| ).

      CATCH CX_APJ_DT_CONTENT INTO LX_APJ_DT_CONTENT.
        OUT->WRITE( |Creation of job template failed: { LX_APJ_DT_CONTENT->GET_TEXT( ) }| ).
        RETURN.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
