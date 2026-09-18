-- ============================================================================
-- RP_19_unionhub_menu.sql
-- Registers the Union Hub (Corporate Events feed) page in the RBAC catalogue and
-- grants view to EVERY role (all-employees feature, sibling of Focus 360).
--   * Module  DASH.UNIONHUB (under DASH / Dashboards)
--   * Menu    /union-hub
--   * Role permissions: CAN_VIEW = 1 for all RP_ROLE rows
-- (Posting is gated in-app to super admins / CO vertical admins; viewing is open.)
-- The EV_* content tables (EV_EVENT/EV_POST/EV_POST_IMAGE/EV_TAG/EV_ACTIVITY_LOG)
-- already exist in the shared schema — this script only wires RBAC.
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
    SELECT COUNT(*) INTO v_cnt FROM RP_RBAC_MODULE WHERE CODE = 'DASH.UNIONHUB';
    IF v_cnt = 0 THEN
        v_mod := RP_SEQ_GLOBAL.NEXTVAL;
        INSERT INTO RP_RBAC_MODULE (ID, CODE, NAME, KIND, PARENT_ID, ICON, SORT_ORDER, IS_ACTIVE)
        VALUES (v_mod, 'DASH.UNIONHUB', 'Union Hub', v_kind, v_parent, 'Groups', 21, 1);
    ELSE
        SELECT ID INTO v_mod FROM RP_RBAC_MODULE WHERE CODE = 'DASH.UNIONHUB';
    END IF;

    -- Menu
    SELECT COUNT(*) INTO v_cnt FROM RP_RBAC_MENU WHERE CODE = 'MENU.DASH.UNIONHUB';
    IF v_cnt = 0 THEN
        INSERT INTO RP_RBAC_MENU (ID, MODULE_ID, CODE, LABEL, ICON, ROUTE, SORT_ORDER, IS_ENABLED, IS_ACTIVE)
        VALUES (RP_SEQ_GLOBAL.NEXTVAL, v_mod, 'MENU.DASH.UNIONHUB', 'Union Hub',
                'Groups', '/union-hub', 21, 1, 1);
    END IF;

    -- Role permissions — grant view to every role (all employees).
    FOR r IN (SELECT ID FROM RP_ROLE) LOOP
        SELECT COUNT(*) INTO v_cnt FROM RP_RBAC_ROLE_PERM WHERE ROLE_ID = r.ID AND MODULE_ID = v_mod;
        IF v_cnt = 0 THEN
            INSERT INTO RP_RBAC_ROLE_PERM (ID, ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_MODIFY, CAN_DELETE, CAN_AUTHORIZE, UPDATED_AT_UTC, UPDATED_BY_EMP)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, r.ID, v_mod, 1, 0, 0, 0, 0, SYSTIMESTAMP, 'RP_19_SEED');
        ELSE
            UPDATE RP_RBAC_ROLE_PERM SET CAN_VIEW = 1 WHERE ROLE_ID = r.ID AND MODULE_ID = v_mod;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Union Hub RBAC registered (module '||v_mod||'), granted to all roles.');
END;
/

SELECT 'unionhub_perms='||COUNT(*) FROM RP_RBAC_ROLE_PERM p
  JOIN RP_RBAC_MODULE m ON m.ID=p.MODULE_ID WHERE m.CODE='DASH.UNIONHUB' AND p.CAN_VIEW=1;
