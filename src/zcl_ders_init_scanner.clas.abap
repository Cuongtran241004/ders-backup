CLASS zcl_ders_init_scanner DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_ders_init_scanner IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA(lv_ok) = zcl_ders_data_setup=>setup_scanner_job( ).
    IF lv_ok = abap_true.
      out->write( 'Scanner job registered OK. Check SM37 / JOBM.' ).
    ELSE.
      out->write( 'ERROR: Scanner job registration failed.' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
