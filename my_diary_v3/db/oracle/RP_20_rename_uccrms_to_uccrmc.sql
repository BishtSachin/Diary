-- ============================================================================
-- RP_20_rename_uccrms_to_uccrmc.sql
-- Corrects the mislabelled UCCRMC alert request type/activity: the code and
-- display name were seeded as "UCCRMS" (typo) and should read "UCCRMC".
--   * RP_M_REQUEST_TYPE  CODE 'UCCRMS_ALERT' -> 'UCCRMC_ALERT',  NAME 'UCCRMS Alert' -> 'UCCRMC Alert'
--   * RP_M_ACTIVITY (UCCRMC_ACT)             NAME 'UCCRMS Alert' -> 'UCCRMC Alert'
-- Idempotent (guarded by the old value). Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON

BEGIN
    UPDATE RP_M_REQUEST_TYPE
       SET CODE = 'UCCRMC_ALERT', NAME = 'UCCRMC Alert'
     WHERE CODE = 'UCCRMS_ALERT';
    DBMS_OUTPUT.PUT_LINE('request types renamed: '||SQL%ROWCOUNT);

    UPDATE RP_M_ACTIVITY
       SET NAME = 'UCCRMC Alert'
     WHERE CODE = 'UCCRMC_ACT' AND NAME = 'UCCRMS Alert';
    DBMS_OUTPUT.PUT_LINE('activities renamed: '||SQL%ROWCOUNT);

    COMMIT;
END;
/

SELECT CODE, NAME, ENTRY_MODE FROM RP_M_REQUEST_TYPE WHERE CODE = 'UCCRMC_ALERT';
SELECT CODE, NAME FROM RP_M_ACTIVITY WHERE CODE = 'UCCRMC_ACT';
