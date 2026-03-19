FUNCTION zf_ders_send_email_bg.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_JOB_UUID) TYPE  SYSUUID_X16
*"     VALUE(IV_SCENARIO) TYPE  CHAR10
*"----------------------------------------------------------------------
      " Khởi tạo class xử lý Notification mà bạn đã tạo ở bước trước
      DATA(lo_notif_mgr) = NEW zcl_ders_email_manager( ).

      " Phân luồng gọi hàm
      CASE iv_scenario.
        WHEN 'SUCCESS'.
          lo_notif_mgr->send_completion_notification( iv_job_uuid = iv_job_uuid ).

        WHEN 'FAILED'.
          lo_notif_mgr->send_error_notification( iv_job_uuid = iv_job_uuid ).
      ENDCASE.


*      COMMIT WORK.

ENDFUNCTION.
