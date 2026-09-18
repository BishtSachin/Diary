-- RP_30_report_impala_source.sql
-- Adds 'IMPALA' as a valid RP_M_REPORT_DEF.SOURCE_TYPE, for Hive/Impala reached
-- through an Apache Knox gateway via the Cloudera Impala ODBC driver (basic auth).
-- Idempotent: drops and recreates the CK_RP_REPORT_SRC check constraint only if
-- its current definition doesn't already include IMPALA.

DECLARE
    v_needs_update NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_needs_update
    FROM USER_CONSTRAINTS
    WHERE CONSTRAINT_NAME = 'CK_RP_REPORT_SRC'
      AND SEARCH_CONDITION_VC NOT LIKE '%IMPALA%';

    IF v_needs_update > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_M_REPORT_DEF DROP CONSTRAINT CK_RP_REPORT_SRC';
        EXECUTE IMMEDIATE
            'ALTER TABLE RP_M_REPORT_DEF ADD CONSTRAINT CK_RP_REPORT_SRC ' ||
            'CHECK (SOURCE_TYPE IN (''FILE_PATH'',''SFTP'',''ORACLE_DB'',''SQLSERVER_DB'',''IMPALA''))';
    END IF;
END;
/
