-- ============================================================================
-- RP_09_notification_userid_fix.sql
-- The RP_NOTIFICATION bell table was created with an EMP_CODE column, but the
-- NotificationRepo / INotificationApi path is keyed entirely by USER_ID
-- (RP_USER.ID). This left the server-to-server Notifications API (and the RP
-- notification path) unusable (ORA-00904: "USER_ID"). Align the table to the
-- repository contract: replace EMP_CODE with USER_ID (NUMBER).
-- Safe: the table holds no rows in this environment. Idempotent.
-- Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON

DECLARE
    has_user_id NUMBER;
    has_emp     NUMBER;
BEGIN
    SELECT COUNT(*) INTO has_user_id FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME='RP_NOTIFICATION' AND COLUMN_NAME='USER_ID';
    SELECT COUNT(*) INTO has_emp FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME='RP_NOTIFICATION' AND COLUMN_NAME='EMP_CODE';

    IF has_user_id = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_NOTIFICATION ADD (USER_ID NUMBER(19,0))';
        DBMS_OUTPUT.PUT_LINE('Added RP_NOTIFICATION.USER_ID');
    END IF;

    IF has_emp = 1 THEN
        -- No rows to migrate; drop the unused column.
        EXECUTE IMMEDIATE 'ALTER TABLE RP_NOTIFICATION DROP COLUMN EMP_CODE';
        DBMS_OUTPUT.PUT_LINE('Dropped RP_NOTIFICATION.EMP_CODE');
    END IF;
END;
/

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM USER_INDEXES WHERE INDEX_NAME='IX_RP_NOTIF_USER';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_RP_NOTIF_USER ON RP_NOTIFICATION(USER_ID, READ_AT)';
        DBMS_OUTPUT.PUT_LINE('Created IX_RP_NOTIF_USER');
    END IF;
END;
/

SELECT column_name FROM user_tab_columns WHERE table_name='RP_NOTIFICATION' AND column_name IN ('USER_ID','EMP_CODE');
