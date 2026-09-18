-- ============================================================================
-- RP_08_uccrmc.sql
-- UCCRMC (Unified Command Center) alert integration for the Request Portal.
--   * Adds external-alert tracking columns to RP_REQUEST
--   * Seeds the 'UCCRMC Alert' request type and a dedicated UCCRMC
--     classification chain (Unit Type -> Unit -> Vertical -> Department ->
--     Activity) so API-created alert tickets satisfy the NOT NULL FKs
--   * Wires the classification interlink mappings (RP_08 depends on RP_07)
-- Idempotent: safe to re-run.
-- Run as RP_OWNER (schema owner).
-- ============================================================================
SET SERVEROUTPUT ON
SET SQLBLANKLINES ON

-- ── 1. External-alert columns on RP_REQUEST ────────────────────────────────
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'RP_REQUEST' AND COLUMN_NAME = 'EXT_ALERT_ID';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_REQUEST ADD (EXT_ALERT_ID VARCHAR2(100))';
        DBMS_OUTPUT.PUT_LINE('Added RP_REQUEST.EXT_ALERT_ID');
    END IF;

    SELECT COUNT(*) INTO n FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'RP_REQUEST' AND COLUMN_NAME = 'EXT_SOURCE';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE RP_REQUEST ADD (EXT_SOURCE VARCHAR2(30))';
        DBMS_OUTPUT.PUT_LINE('Added RP_REQUEST.EXT_SOURCE');
    END IF;
END;
/

-- Index for fast alert-id lookups (status API). Unique per source when present.
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM USER_INDEXES WHERE INDEX_NAME = 'IX_RP_REQUEST_EXT_ALERT';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IX_RP_REQUEST_EXT_ALERT ON RP_REQUEST(EXT_SOURCE, EXT_ALERT_ID)';
        DBMS_OUTPUT.PUT_LINE('Created IX_RP_REQUEST_EXT_ALERT');
    END IF;
END;
/

-- ── 2. Seed the UCCRMC classification chain + request type ──────────────────
DECLARE
    v_rt   NUMBER;   -- request type id
    v_ut   NUMBER;   -- unit type id
    v_unit NUMBER;   -- unit id
    v_vert NUMBER;   -- vertical id
    v_dept NUMBER;   -- department id
    v_act  NUMBER;   -- activity id
    n      NUMBER;

    FUNCTION id_for(p_sql VARCHAR2) RETURN NUMBER IS
        v NUMBER;
    BEGIN
        EXECUTE IMMEDIATE p_sql INTO v;
        RETURN v;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
    END;
BEGIN
    -- Request type: 'UCCRMC Alert'
    v_rt := id_for('SELECT ID FROM RP_M_REQUEST_TYPE WHERE CODE=''UCCRMC_ALERT''');
    IF v_rt IS NULL THEN
        v_rt := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_M_REQUEST_TYPE(ID,CODE,NAME,IS_ACTIVE) VALUES(v_rt,'UCCRMC_ALERT','UCCRMC Alert',1);
    END IF;

    -- Unit type: Command Center
    v_ut := id_for('SELECT ID FROM RP_M_UNIT_TYPE WHERE CODE=''UCCRMC_UT''');
    IF v_ut IS NULL THEN
        v_ut := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_M_UNIT_TYPE(ID,CODE,NAME,IS_ACTIVE) VALUES(v_ut,'UCCRMC_UT','Command Center',1);
    END IF;

    -- Unit: UCCRMC Command Center
    v_unit := id_for('SELECT ID FROM RP_M_UNIT WHERE CODE=''UCCRMC_UNIT''');
    IF v_unit IS NULL THEN
        v_unit := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_M_UNIT(ID,UNIT_TYPE_ID,PARENT_UNIT_ID,CODE,NAME,HOLIDAY_CAL_ID,IS_ACTIVE)
        VALUES(v_unit,v_ut,NULL,'UCCRMC_UNIT','UCCRMC Command Center',NULL,1);
    END IF;

    -- Vertical: Command Center
    v_vert := id_for('SELECT ID FROM RP_M_VERTICAL WHERE CODE=''UCCRMC_VERT''');
    IF v_vert IS NULL THEN
        v_vert := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_M_VERTICAL(ID,CODE,NAME,IS_ACTIVE) VALUES(v_vert,'UCCRMC_VERT','Command Center',1);
    END IF;

    -- Department: UCCRMC Alerts
    v_dept := id_for('SELECT ID FROM RP_M_DEPARTMENT WHERE CODE=''UCCRMC_DEPT''');
    IF v_dept IS NULL THEN
        v_dept := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_M_DEPARTMENT(ID,VERTICAL_ID,CODE,NAME,IS_ACTIVE) VALUES(v_dept,v_vert,'UCCRMC_DEPT','UCCRMC Alerts',1);
    END IF;

    -- Activity: UCCRMC Alert
    v_act := id_for('SELECT ID FROM RP_M_ACTIVITY WHERE CODE=''UCCRMC_ACT''');
    IF v_act IS NULL THEN
        v_act := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_M_ACTIVITY(ID,DEPARTMENT_ID,CODE,NAME,IS_ACTIVE) VALUES(v_act,v_dept,'UCCRMC_ACT','UCCRMC Alert',1);
    END IF;

    -- Classification interlink (RP_07 tables): Request Type -> Unit Type, Unit -> Vertical
    SELECT COUNT(*) INTO n FROM RP_M_REQTYPE_UNITTYPE WHERE REQUEST_TYPE_ID=v_rt AND UNIT_TYPE_ID=v_ut;
    IF n = 0 THEN
        INSERT INTO RP_M_REQTYPE_UNITTYPE(ID,REQUEST_TYPE_ID,UNIT_TYPE_ID) VALUES(RP_MAP_SEQ.NEXTVAL,v_rt,v_ut);
    END IF;

    SELECT COUNT(*) INTO n FROM RP_M_UNIT_VERTICAL WHERE UNIT_ID=v_unit AND VERTICAL_ID=v_vert;
    IF n = 0 THEN
        INSERT INTO RP_M_UNIT_VERTICAL(ID,UNIT_ID,VERTICAL_ID) VALUES(RP_MAP_SEQ.NEXTVAL,v_unit,v_vert);
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('UCCRMC classification seeded: RT='||v_rt||' UT='||v_ut||' UNIT='||v_unit||
                         ' VERT='||v_vert||' DEPT='||v_dept||' ACT='||v_act);
END;
/

-- ── 3. Verify ───────────────────────────────────────────────────────────────
SELECT 'UCCRMC Alert type' AS item, COUNT(*) AS cnt FROM RP_M_REQUEST_TYPE WHERE CODE='UCCRMC_ALERT'
UNION ALL SELECT 'UCCRMC activity',   COUNT(*) FROM RP_M_ACTIVITY WHERE CODE='UCCRMC_ACT'
UNION ALL SELECT 'ext columns',       COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME='RP_REQUEST' AND COLUMN_NAME IN ('EXT_ALERT_ID','EXT_SOURCE');
