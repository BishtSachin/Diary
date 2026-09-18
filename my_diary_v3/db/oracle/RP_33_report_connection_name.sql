-- RP_33_report_connection_name.sql
-- Adds RP_M_REPORT_DEF.CONNECTION_NAME — the exact appsettings ConnectionStrings
-- key the admin picked from a dropdown in Report Developer (e.g. "ReportsOracleDc",
-- "ReportsOracleFinanceDb") for Oracle/SQL Server/Impala reports. Replaces the
-- earlier fixed "one connection per source type per DC/DR site" auto-resolution —
-- the admin now explicitly names which of all available connections to use.
-- Idempotent: adds the column only if missing.

DECLARE
    v_col_exists NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_col_exists
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'RP_M_REPORT_DEF' AND COLUMN_NAME = 'CONNECTION_NAME';

    IF v_col_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_M_REPORT_DEF ADD CONNECTION_NAME VARCHAR2(100)';
    END IF;
END;
/
