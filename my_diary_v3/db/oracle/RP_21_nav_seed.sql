-- ============================================================================
-- RP_21_nav_seed.sql
-- Turns the RBAC mapping tables into the SIDEBAR navigation model, so the whole
-- sidebar (modules, sub-menus, order, icons, visibility) is driven from the DB
-- and edited from the Access Management pages (/admin/rbac/modules, /menus,
-- /role-permissions) — no source changes needed to realign the sidebar.
--
--   RP_RBAC_MODULE  = top-level sidebar modules (the switch groups)
--   RP_RBAC_MENU    = sidebar links under a module
--                     ROUTE conventions:
--                        <path>              → in-app route
--                        sso:<Key>           → SSO portal (AskUs / SuggestionPortal / Qlik)
--                        ext:<Key>           → external config URL (EscalationMatrix)
--                        heading:<Text>      → non-clickable section heading
--                     ICON = MudBlazor Material icon name, or img:<name> for an image
--   RP_RBAC_ROLE_PERM = which roles may VIEW each module (drives visibility)
--
-- Idempotent: clears the nav tree and reseeds. Run as RP_OWNER.
-- NOTE: the previous fine-grained module taxonomy is replaced; nothing enforced
-- it at runtime (page access uses [Authorize]/AppAdmin/SuperAdmin policies).
-- ============================================================================
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
    v_mod NUMBER;

    PROCEDURE add_menu(p_mod NUMBER, p_code VARCHAR2, p_label VARCHAR2,
                       p_icon VARCHAR2, p_route VARCHAR2, p_sort NUMBER) IS
    BEGIN
        INSERT INTO RP_RBAC_MENU(ID,MODULE_ID,CODE,LABEL,ICON,ROUTE,SORT_ORDER,IS_ENABLED,IS_ACTIVE)
        VALUES(RP_SEQ_GLOBAL.NEXTVAL,p_mod,p_code,p_label,p_icon,p_route,p_sort,1,1);
    END;

    FUNCTION add_module(p_code VARCHAR2, p_name VARCHAR2, p_icon VARCHAR2, p_sort NUMBER)
        RETURN NUMBER IS
        v NUMBER;
    BEGIN
        v := RP_SEQ_GLOBAL.NEXTVAL;
        -- KIND=5 (Dashboard) => role-permissions page shows only the View toggle.
        INSERT INTO RP_RBAC_MODULE(ID,CODE,NAME,KIND,PARENT_ID,ICON,SORT_ORDER,IS_ACTIVE)
        VALUES(v,p_code,p_name,5,NULL,p_icon,p_sort,1);
        RETURN v;
    END;
BEGIN
    -- ── clear existing tree (children first) ───────────────────────────────
    DELETE FROM RP_RBAC_USER_PERM;
    DELETE FROM RP_RBAC_ROLE_PERM;
    DELETE FROM RP_RBAC_MENU;
    DELETE FROM RP_RBAC_MODULE;

    -- ── MAIN (its menus render as the top direct links) ────────────────────
    v_mod := add_module('NAV.MAIN','Main','Home',0);
    add_menu(v_mod,'NAV.MAIN.HOME','Home','Home','Landing_Dashboard_V2_1',10);
    add_menu(v_mod,'NAV.MAIN.DEPT','Departments','Business','departmentsnew',20);
    add_menu(v_mod,'NAV.MAIN.DL','Downloads','Download','downloads2',30);

    -- ── Focus 360° ─────────────────────────────────────────────────────────
    v_mod := add_module('NAV.FOCUS360','Focus 360°','TrackChanges',10);
    add_menu(v_mod,'NAV.F360.KPI','Key Performance Indicator','Speed','dashboard_new_1',10);
    add_menu(v_mod,'NAV.F360.FOCUS','Focus 360°','CenterFocusStrong','focus360',20);
    add_menu(v_mod,'NAV.F360.BUS','Business 360°','_360','business-new',30);

    -- ── Assurance 360 ──────────────────────────────────────────────────────
    v_mod := add_module('NAV.ASSURANCE360','Assurance 360','VerifiedUser',20);
    add_menu(v_mod,'NAV.A360.SNAP','Assurance Snapshot','VerifiedUser','assurance-snapshot',10);
    add_menu(v_mod,'NAV.A360.CORNER','Assurance Corner','SpaceDashboard','Dashboards2',20);

    -- ── MIS ────────────────────────────────────────────────────────────────
    v_mod := add_module('NAV.MIS','MIS','Analytics',30);
    add_menu(v_mod,'NAV.MIS.MIS','MIS','Analytics','MIS',10);
    add_menu(v_mod,'NAV.MIS.QLIK','Qlik Dashboard','InsertChart','qlik-dashboard',20);
    add_menu(v_mod,'NAV.MIS.QLIKSSO','Qlik','img:qlik','sso:Qlik',30);

    -- ── Applications ───────────────────────────────────────────────────────
    v_mod := add_module('NAV.APPS','Applications','Apps',40);
    add_menu(v_mod,'NAV.APP.GRID','Applications','Widgets','app-portal1',10);
    add_menu(v_mod,'NAV.APP.ASKUS','Ask Us','QuestionAnswer','sso:AskUs',20);
    add_menu(v_mod,'NAV.APP.SUGG','Suggestions','Lightbulb','sso:SuggestionPortal',30);
    add_menu(v_mod,'NAV.APP.ESC','Escalation Matrix','ReportProblem','ext:EscalationMatrix',40);

    -- ── Request Portal ─────────────────────────────────────────────────────
    v_mod := add_module('NAV.RP','Request Portal','Assignment',50);
    add_menu(v_mod,'NAV.RP.NEW','New Request','AddCircleOutline','requests/new',10);
    add_menu(v_mod,'NAV.RP.MINE','My Requests','Inbox','requests/mine',20);
    add_menu(v_mod,'NAV.RP.INBOX','Handler Inbox','AssignmentInd','handler/inbox',30);
    add_menu(v_mod,'NAV.RP.MYDASH','My Dashboard','DashboardCustomize','dashboards/handler',40);
    add_menu(v_mod,'NAV.RP.OVER','Request Dashboard','BarChart','oversight/dashboard',50);
    add_menu(v_mod,'NAV.RP.SLA','SLA Breach Report','Timer','reports/sla',60);
    add_menu(v_mod,'NAV.RP.INQ','Request Inquiry','ManageSearch','inquiry/requests',70);
    add_menu(v_mod,'NAV.RP.ESC','Escalation Matrix','Escalator','requests/escalation-matrix',80);

    -- ── Notifications ──────────────────────────────────────────────────────
    v_mod := add_module('NAV.NOTIF','Notifications','Notifications',60);
    add_menu(v_mod,'NAV.NT.HUB','Union Hub','Groups','union-hub',10);
    add_menu(v_mod,'NAV.NT.MINE','My Notifications','NotificationsNone','notifications',20);
    add_menu(v_mod,'NAV.NT.BCAST','Broadcast','Campaign','admin/broadcast',30);
    add_menu(v_mod,'NAV.NT.TPL','Notification Templates','Email','admin/templates',40);

    -- ── Access Management (App Admin) ──────────────────────────────────────
    v_mod := add_module('NAV.ACCESS','Access Management','AdminPanelSettings',70);
    add_menu(v_mod,'NAV.AC.PERMS','Role Permissions','Tune','admin/rbac/role-permissions',10);
    add_menu(v_mod,'NAV.AC.MODS','Modules & Sub-modules','AccountTree','admin/rbac/modules',20);
    add_menu(v_mod,'NAV.AC.MENUS','Menus','Menu','admin/rbac/menus',30);
    add_menu(v_mod,'NAV.AC.AUDIT','RBAC Audit Log','HistoryEdu','admin/rbac/audit',40);
    add_menu(v_mod,'NAV.AC.RIGHTS','Admin Rights','Key','admin/rbac/admin-rights',50);

    -- ── Admin Portal (App Admin) ───────────────────────────────────────────
    v_mod := add_module('NAV.ADMIN','Admin Portal','ManageAccounts',80);
    add_menu(v_mod,'NAV.AP.H1','REQUEST CONFIG',NULL,'heading:REQUEST CONFIG',5);
    add_menu(v_mod,'NAV.AP.CLASS','Classification Mapping','Hub','admin/classification-map',10);
    add_menu(v_mod,'NAV.AP.SLA','SLA Configuration','AvTimer','admin/sla',20);
    add_menu(v_mod,'NAV.AP.HOL','Holiday Calendar','EventBusy','admin/holidays',30);
    add_menu(v_mod,'NAV.AP.ROUTE','Routing Rules','AltRoute','admin/routing',40);
    add_menu(v_mod,'NAV.AP.ESC','Escalation Matrix','Escalator','admin/escalation-matrix',50);
    add_menu(v_mod,'NAV.AP.H2','OPERATIONS & AUDIT',NULL,'heading:OPERATIONS & AUDIT',55);
    add_menu(v_mod,'NAV.AP.REQ','All Requests','Search','admin/requests',60);
    add_menu(v_mod,'NAV.AP.SETUP','Setup Audit Log','ManageHistory','admin/setup-audit',70);
    add_menu(v_mod,'NAV.AP.AUDIT','Audit Search','History','admin/audit',80);
    add_menu(v_mod,'NAV.AP.DELEG','Delegations','SwapHoriz','admin/delegations',90);

    -- ── API Admin (App Admin) ──────────────────────────────────────────────
    v_mod := add_module('NAV.API','API Admin','Api',90);
    add_menu(v_mod,'NAV.API.NOTIF','Notifications API','CloudSync','admin/api-help',10);
    add_menu(v_mod,'NAV.API.UCCRMC','UCCRMC Alerts API','Report','admin/api-help/uccrmc',20);

    -- ── Masters (Super Admin) ──────────────────────────────────────────────
    v_mod := add_module('NAV.MASTERS','Masters','Storage',100);
    add_menu(v_mod,'NAV.MS.H1','PEOPLE & ORG',NULL,'heading:PEOPLE & ORG',5);
    add_menu(v_mod,'NAV.MS.EMP','Employee Master','Person','masters/employees',10);
    add_menu(v_mod,'NAV.MS.BR','Branch / Sol ID Master','AccountBalance','masters/branches',20);
    add_menu(v_mod,'NAV.MS.UNIT','Units','Apartment','masters/units',30);
    add_menu(v_mod,'NAV.MS.H2','ACCESS',NULL,'heading:ACCESS',35);
    add_menu(v_mod,'NAV.MS.USERS','Users','People','masters/users',40);
    add_menu(v_mod,'NAV.MS.ROLES','Roles','Badge','masters/roles',50);
    add_menu(v_mod,'NAV.MS.ALLOC','Role Allocation','HowToReg','masters/role-allocation',60);
    add_menu(v_mod,'NAV.MS.REQT','Request Types & Units','Category','admin/masters',70);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Nav modules/menus seeded.');
END;
/

-- ── Role → module VIEW grants (visibility) ─────────────────────────────────
-- Public modules: every role can view.
INSERT INTO RP_RBAC_ROLE_PERM(ID,ROLE_ID,MODULE_ID,CAN_VIEW,CAN_ADD,CAN_MODIFY,CAN_DELETE,CAN_AUTHORIZE,UPDATED_AT_UTC,UPDATED_BY_EMP)
SELECT RP_SEQ_GLOBAL.NEXTVAL, r.ID, m.ID, 1,0,0,0,0, SYSTIMESTAMP,'RP_21'
FROM RP_ROLE r CROSS JOIN RP_RBAC_MODULE m
WHERE m.CODE IN ('NAV.MAIN','NAV.FOCUS360','NAV.ASSURANCE360','NAV.MIS','NAV.APPS','NAV.RP','NAV.NOTIF');

-- Admin modules: App Admin + Super Admin.
INSERT INTO RP_RBAC_ROLE_PERM(ID,ROLE_ID,MODULE_ID,CAN_VIEW,CAN_ADD,CAN_MODIFY,CAN_DELETE,CAN_AUTHORIZE,UPDATED_AT_UTC,UPDATED_BY_EMP)
SELECT RP_SEQ_GLOBAL.NEXTVAL, r.ID, m.ID, 1,0,0,0,0, SYSTIMESTAMP,'RP_21'
FROM RP_ROLE r CROSS JOIN RP_RBAC_MODULE m
WHERE m.CODE IN ('NAV.ACCESS','NAV.ADMIN','NAV.API') AND r.CODE IN ('APP_ADMIN','SUPER_ADMIN');

-- Masters: Super Admin only.
INSERT INTO RP_RBAC_ROLE_PERM(ID,ROLE_ID,MODULE_ID,CAN_VIEW,CAN_ADD,CAN_MODIFY,CAN_DELETE,CAN_AUTHORIZE,UPDATED_AT_UTC,UPDATED_BY_EMP)
SELECT RP_SEQ_GLOBAL.NEXTVAL, r.ID, m.ID, 1,0,0,0,0, SYSTIMESTAMP,'RP_21'
FROM RP_ROLE r CROSS JOIN RP_RBAC_MODULE m
WHERE m.CODE = 'NAV.MASTERS' AND r.CODE = 'SUPER_ADMIN';

COMMIT;

SELECT 'modules='||COUNT(*) FROM RP_RBAC_MODULE;
SELECT 'menus='||COUNT(*) FROM RP_RBAC_MENU;
SELECT 'role_perms='||COUNT(*) FROM RP_RBAC_ROLE_PERM;
