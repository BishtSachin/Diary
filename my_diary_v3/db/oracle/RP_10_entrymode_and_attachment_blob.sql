-- ============================================================================
-- RP_10_entrymode_and_attachment_blob.sql
--   1) RP_M_REQUEST_TYPE.ENTRY_MODE — controls how a request type may be
--      raised: MANUAL (New Request form only), API (integration only) or
--      BOTH. UCCRMC Alert is API-only.
--   2) RP_ATTACHMENT_BLOB — stores request attachment bytes as a BLOB in the
--      database (replaces filesystem storage). Keyed by the storage key that
--      RP_REQUEST_ATTACHMENT.STORAGE_KEY already holds.
-- Idempotent. Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON

-- ── 1. ENTRY_MODE on request types ─────────────────────────────────────────
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME='RP_M_REQUEST_TYPE' AND COLUMN_NAME='ENTRY_MODE';
    IF n = 0 THEN
        EXECUTE IMMEDIATE q'[ALTER TABLE RP_M_REQUEST_TYPE ADD (ENTRY_MODE VARCHAR2(10) DEFAULT 'BOTH')]';
        DBMS_OUTPUT.PUT_LINE('Added RP_M_REQUEST_TYPE.ENTRY_MODE');
    END IF;
END;
/

UPDATE RP_M_REQUEST_TYPE SET ENTRY_MODE='BOTH' WHERE ENTRY_MODE IS NULL;
UPDATE RP_M_REQUEST_TYPE SET ENTRY_MODE='API'  WHERE CODE='UCCRMC_ALERT';
COMMIT;

-- Constrain to the known values (guarded — ignore if it already exists).
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM USER_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_RP_REQTYPE_ENTRYMODE';
    IF n = 0 THEN
        EXECUTE IMMEDIATE q'[ALTER TABLE RP_M_REQUEST_TYPE ADD CONSTRAINT CK_RP_REQTYPE_ENTRYMODE
                             CHECK (ENTRY_MODE IN ('MANUAL','API','BOTH'))]';
        DBMS_OUTPUT.PUT_LINE('Added CK_RP_REQTYPE_ENTRYMODE');
    END IF;
END;
/

-- ── 2. Attachment BLOB store ────────────────────────────────────────────────
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME='RP_ATTACHMENT_BLOB';
    IF n = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE RP_ATTACHMENT_BLOB (
                STORAGE_KEY VARCHAR2(80) PRIMARY KEY,
                CONTENT     BLOB NOT NULL,
                CREATED_AT  TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
            )]';
        DBMS_OUTPUT.PUT_LINE('Created RP_ATTACHMENT_BLOB');
    END IF;
END;
/

-- ── 3. Verify ───────────────────────────────────────────────────────────────
SELECT CODE, NAME, ENTRY_MODE FROM RP_M_REQUEST_TYPE WHERE CODE='UCCRMC_ALERT';
SELECT COUNT(*) AS blob_table FROM USER_TABLES WHERE TABLE_NAME='RP_ATTACHMENT_BLOB';
