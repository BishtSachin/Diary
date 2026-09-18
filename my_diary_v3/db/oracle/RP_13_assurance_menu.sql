-- ============================================================================
-- RP_13_assurance_menu.sql
-- Registers the Assurance Snapshot page in the RBAC catalogue and grants view
-- to EVERY role (it is an all-employees dashboard, sibling of Focus 360).
--   * Module  DASH.ASSURANCE (under DASH / Dashboards)
--   * Menu    /assurance-snapshot
--   * Role permissions: CAN_VIEW = 1 for all RP_ROLE rows
-- Idempotent. Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON

DECLARE
    v_parent NUMBER;
    v_mod    NUMBER;
    v_kind   NUMBER;
    v_cnt    NUMBER;
BEGIN
    SELECT ID INTO v_parent FROM RP_RBAC_MODULE WHERE CODE = 'DASH';
    SELECT KIND INTO v_kind FROM RP_RBAC_MODULE WHERE CODE = 'DASH.EXEC';  -- same leaf-page KIND as a sibling

    -- Module
    SELECT COUNT(*) INTO v_cnt FROM RP_RBAC_MODULE WHERE CODE = 'DASH.ASSURANCE';
    IF v_cnt = 0 THEN
        v_mod := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_RBAC_MODULE (ID, CODE, NAME, KIND, PARENT_ID, ICON, SORT_ORDER, IS_ACTIVE)
        VALUES (v_mod, 'DASH.ASSURANCE', 'Assurance Snapshot', v_kind, v_parent, 'VerifiedUser', 25, 1);
    ELSE
        SELECT ID INTO v_mod FROM RP_RBAC_MODULE WHERE CODE = 'DASH.ASSURANCE';
    END IF;

    -- Menu
    SELECT COUNT(*) INTO v_cnt FROM RP_RBAC_MENU WHERE CODE = 'MENU.DASH.ASSURANCE';
    IF v_cnt = 0 THEN
        INSERT INTO RP_RBAC_MENU (ID, MODULE_ID, CODE, LABEL, ICON, ROUTE, SORT_ORDER, IS_ENABLED, IS_ACTIVE)
        VALUES (RP_SEQ_GLOBAL.NEXTVAL, v_mod, 'MENU.DASH.ASSURANCE', 'Assurance Snapshot',
                'VerifiedUser', '/assurance-snapshot', 25, 1, 1);
    END IF;

    -- Role permissions — grant view to every role (all employees).
    FOR r IN (SELECT ID FROM RP_ROLE) LOOP
        SELECT COUNT(*) INTO v_cnt FROM RP_RBAC_ROLE_PERM WHERE ROLE_ID = r.ID AND MODULE_ID = v_mod;
        IF v_cnt = 0 THEN
            INSERT INTO RP_RBAC_ROLE_PERM (ID, ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_MODIFY, CAN_DELETE, CAN_AUTHORIZE, UPDATED_AT_UTC, UPDATED_BY_EMP)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, r.ID, v_mod, 1, 0, 0, 0, 0, SYSTIMESTAMP, 'RP_13_SEED');
        ELSE
            UPDATE RP_RBAC_ROLE_PERM SET CAN_VIEW = 1 WHERE ROLE_ID = r.ID AND MODULE_ID = v_mod;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Assurance Snapshot RBAC registered (module '||v_mod||'), granted to all roles.');
END;
/

SELECT 'assurance_perms='||COUNT(*) FROM RP_RBAC_ROLE_PERM p
  JOIN RP_RBAC_MODULE m ON m.ID=p.MODULE_ID WHERE m.CODE='DASH.ASSURANCE' AND p.CAN_VIEW=1;
