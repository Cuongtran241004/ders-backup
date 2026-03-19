"!──────────────────────────────────────────────────────────────────────────────
"! BEHAVIOR IMPLEMENTATION CLASS: ZBP_I_DERS_USERPERM
"!
"! PURPOSE: Implements behavior logic for User Permission management
"!
"! BDEF: ZI_DERS_UserPerm
"! TYPE: Managed (Admin-only)
"!
"! FEATURES:
"! - Global authorization check (admin only)
"! - Determinations for default values and perm_type
"! - Validations for user, report, and company existence
"! - Actions for deactivate/reactivate
"!──────────────────────────────────────────────────────────────────────────────
CLASS zbp_i_ders_userperm DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_ders_userperm.
ENDCLASS.

CLASS zbp_i_ders_userperm IMPLEMENTATION.
ENDCLASS.

