-- ============================================================================
-- RP_14_unittype_seed.sql
-- Makes RP_M_UNIT_TYPE contain exactly these six unit types:
--   Team Sahyog (TEAM_SAHYOG), Ask Us (ASK_US), CPCs (CPC),
--   Regional Office (RO), Zonal Office (ZO), Central Office (CO)
-- Any other unit type is removed — hard-deleted when unreferenced, otherwise
-- deactivated (IS_ACTIVE=0) so foreign keys (RP_M_UNIT / RP_M_REQTYPE_UNITTYPE
-- / UCCRMC) are not violated.
-- Idempotent. Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON

-- ── 1. Upsert the six canonical unit types ──────────────────────────────────
DECLARE
    TYPE t_rec IS RECORD (code VARCHAR2(30), name VARCHAR2(100));
    TYPE t_tab IS TABLE OF t_rec;
    us t_tab := t_tab(
        t_rec('TEAM_SAHYOG', 'Team Sahyog'),
        t_rec('ASK_US',      'Ask Us'),
        t_rec('CPC',         'CPCs'),
        t_rec('RO',          'Regional Office'),
        t_rec('ZO',          'Zonal Office'),
        t_rec('CO',          'Central Office')
    );
BEGIN
    FOR i IN 1 .. us.COUNT LOOP
        MERGE INTO RP_M_UNIT_TYPE t
        USING (SELECT us(i).code AS CODE FROM DUAL) s ON (t.CODE = s.CODE)
        WHEN MATCHED THEN UPDATE SET t.NAME = us(i).name, t.IS_ACTIVE = 1
        WHEN NOT MATCHED THEN
            INSERT (ID, CODE, NAME, IS_ACTIVE)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, us(i).code, us(i).name, 1);
    END LOOP;
    COMMIT;
END;
/

-- ── 2. Remove every other unit type (delete if free, else deactivate) ───────
DECLARE
    v_del NUMBER := 0;
    v_deact NUMBER := 0;
BEGIN
    FOR ut IN (SELECT ID, CODE FROM RP_M_UNIT_TYPE
                WHERE CODE NOT IN ('TEAM_SAHYOG','ASK_US','CPC','RO','ZO','CO')) LOOP
        BEGIN
            DELETE FROM RP_M_UNIT_TYPE WHERE ID = ut.ID;
            v_del := v_del + 1;
        EXCEPTION
            WHEN OTHERS THEN
                -- Referenced by a child row (unit / mapping) — soft-remove instead.
                UPDATE RP_M_UNIT_TYPE SET IS_ACTIVE = 0 WHERE ID = ut.ID;
                v_deact := v_deact + 1;
                DBMS_OUTPUT.PUT_LINE('Deactivated (referenced): '||ut.CODE);
        END;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Unit types — deleted: '||v_del||', deactivated: '||v_deact);
END;
/

-- ── Verify ───────────────────────────────────────────────────────────────────
SELECT CODE, NAME, IS_ACTIVE FROM RP_M_UNIT_TYPE ORDER BY IS_ACTIVE DESC, NAME;
