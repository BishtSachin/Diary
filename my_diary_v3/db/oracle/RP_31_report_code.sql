-- RP_31_report_code.sql
-- Adds RP_M_REPORT_DEF.REPORT_CODE — a stable, admin-entered short identifier
-- (unique, e.g. "RPT-KYC-01") for cross-referencing a report definition in
-- audit logs, URLs, or external callers, independent of the internal ID
-- surrogate key and the free-text (non-unique) REPORT_NAME.
--
-- Idempotent: adds the column only if missing, backfills any existing rows
-- with a generated placeholder code (RPT-<ID>) so the NOT NULL/UNIQUE
-- constraints can be applied safely, then adds those constraints only if
-- not already present.

DECLARE
    v_col_exists NUMBER := 0;
    v_constraint_exists NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_col_exists
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'RP_M_REPORT_DEF' AND COLUMN_NAME = 'REPORT_CODE';

    IF v_col_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_M_REPORT_DEF ADD REPORT_CODE VARCHAR2(50)';

        -- Backfill any pre-existing rows with a generated placeholder so
        -- SuperAdmins can rename them to a real code later without a NULL clash.
        EXECUTE IMMEDIATE q'[
            UPDATE RP_M_REPORT_DEF SET REPORT_CODE = 'RPT-' || TO_CHAR(ID)
            WHERE REPORT_CODE IS NULL]';

        EXECUTE IMMEDIATE 'ALTER TABLE RP_M_REPORT_DEF MODIFY REPORT_CODE VARCHAR2(50) NOT NULL';
    END IF;

    SELECT COUNT(*) INTO v_constraint_exists
    FROM USER_CONSTRAINTS
    WHERE TABLE_NAME = 'RP_M_REPORT_DEF' AND CONSTRAINT_NAME = 'UQ_RP_REPORT_CODE';

    IF v_constraint_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_M_REPORT_DEF ADD CONSTRAINT UQ_RP_REPORT_CODE UNIQUE (REPORT_CODE)';
    END IF;
END;
/
