-- ============================================================================
-- Request Portal — Complete Seed Data v3.0
-- Schema   : RP_OWNER
-- Run after: 01_schema.sql
-- Run order: 01_schema.sql → 02_seed.sql → 04_superadmin.sql → 05_uat_data.sql
--
-- ROLE ARCHITECTURE (3 tiers):
--   Tier 1 — Organisational role (DERIVED at login from VW_STAFF_USER_SUMMARY):
--     BRANCH_USER  BRANCH_HEAD  RO_USER  RO_HEAD  ZO_USER  ZO_HEAD
--     CO_USER  CO_HEAD  CO_VERT_ADMIN  APP_ADMIN
--   Tier 2 — Super Admin (from RP_RBAC_SUPER_ADMIN, max 2):
--     SUPER_ADMIN
--   Tier 3 — Vertical process levels (ASSIGNED by CO_VERT_ADMIN, stored in
--             RP_RBAC_VERTICAL_LEVEL, additive to org role):
--     VERT_L1  VERT_L2  VERT_L3  VERT_L4  VERT_L5
-- ============================================================================

SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------------
-- 1. ROLES  (16 total)
-- ---------------------------------------------------------------------------
MERGE INTO RP_ROLE t USING (
  -- Tier 1 — Organisational (derived from view)
  SELECT 'BRANCH_USER'    AS CODE, 'Branch User'                    AS NAME FROM DUAL UNION ALL
  SELECT 'BRANCH_HEAD',            'Branch Head'                            FROM DUAL UNION ALL
  SELECT 'RO_USER',                'Regional Office User'                   FROM DUAL UNION ALL
  SELECT 'RO_HEAD',                'Regional Office Head'                   FROM DUAL UNION ALL
  SELECT 'ZO_USER',                'Zonal Office User'                      FROM DUAL UNION ALL
  SELECT 'ZO_HEAD',                'Zonal Office Head'                      FROM DUAL UNION ALL
  SELECT 'CO_USER',                'Corporate Office User'                  FROM DUAL UNION ALL
  SELECT 'CO_HEAD',                'Corporate Office Head'                  FROM DUAL UNION ALL
  SELECT 'CO_VERT_ADMIN',          'CO Vertical Admin'                      FROM DUAL UNION ALL
  SELECT 'APP_ADMIN',              'Application Admin'                      FROM DUAL UNION ALL
  -- Tier 2 — Super Admin
  SELECT 'SUPER_ADMIN',            'Super Admin'                            FROM DUAL UNION ALL
  -- Tier 3 — Vertical process levels (assigned by CO_VERT_ADMIN)
  SELECT 'VERT_L1',                'Vertical Level 1'                       FROM DUAL UNION ALL
  SELECT 'VERT_L2',                'Vertical Level 2'                       FROM DUAL UNION ALL
  SELECT 'VERT_L3',                'Vertical Level 3'                       FROM DUAL UNION ALL
  SELECT 'VERT_L4',                'Vertical Level 4'                       FROM DUAL UNION ALL
  SELECT 'VERT_L5',                'Vertical Level 5 (Oversight)'           FROM DUAL
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, CODE, NAME)
  VALUES (RP_SEQ_GLOBAL.NEXTVAL, s.CODE, s.NAME)
WHEN MATCHED THEN UPDATE SET NAME = s.NAME;

-- ---------------------------------------------------------------------------
-- 2. REQUEST TYPES
-- ---------------------------------------------------------------------------
MERGE INTO RP_M_REQUEST_TYPE t USING (
  SELECT 'GRIEVANCE' AS CODE, 'Grievance' AS NAME FROM DUAL UNION ALL
  SELECT 'REQUEST',           'Request'           FROM DUAL UNION ALL
  SELECT 'INQUIRY',           'Inquiry'           FROM DUAL
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, CODE, NAME)
  VALUES (RP_SEQ_GLOBAL.NEXTVAL, s.CODE, s.NAME);

-- ---------------------------------------------------------------------------
-- 3. UNIT TYPES  (5: BRANCH + the 4 as per VW_STAFF_USER_SUMMARY UNIT_TYPE)
-- ---------------------------------------------------------------------------
MERGE INTO RP_M_UNIT_TYPE t USING (
  SELECT 'BRANCH' AS CODE, 'Branch'           AS NAME FROM DUAL UNION ALL
  SELECT 'RO',             'Regional Office'          FROM DUAL UNION ALL
  SELECT 'ZO',             'Zonal Office'             FROM DUAL UNION ALL
  SELECT 'CO',             'Corporate Office'         FROM DUAL UNION ALL
  SELECT 'ADMIN',          'Administration'           FROM DUAL
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, CODE, NAME)
  VALUES (RP_SEQ_GLOBAL.NEXTVAL, s.CODE, s.NAME);

-- ---------------------------------------------------------------------------
-- 4. DEFAULT HOLIDAY CALENDAR
-- ---------------------------------------------------------------------------
MERGE INTO RP_M_HOLIDAY_CAL t USING (
  SELECT 'NATIONAL' AS CODE, 'National Holiday Calendar' AS NAME FROM DUAL
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, CODE, NAME)
  VALUES (RP_SEQ_GLOBAL.NEXTVAL, s.CODE, s.NAME);

-- ---------------------------------------------------------------------------
-- 5. DEFAULT SLA — 2 working days per level (L1–L5) for every request type
-- ---------------------------------------------------------------------------
DECLARE
  CURSOR c IS SELECT ID FROM RP_M_REQUEST_TYPE;
  v_exists NUMBER;
BEGIN
  FOR r IN c LOOP
    FOR lvl IN 1..5 LOOP
      SELECT COUNT(*) INTO v_exists
        FROM RP_M_SLA_CONFIG
       WHERE REQUEST_TYPE_ID = r.ID AND LEVEL_NO = lvl;
      IF v_exists = 0 THEN
        INSERT INTO RP_M_SLA_CONFIG (ID, REQUEST_TYPE_ID, LEVEL_NO, WORKING_DAYS)
        VALUES (RP_SEQ_GLOBAL.NEXTVAL, r.ID, lvl, 2);
      END IF;
    END LOOP;
  END LOOP;
END;
/

-- ---------------------------------------------------------------------------
-- 6. NOTIFICATION TEMPLATES
-- ---------------------------------------------------------------------------
MERGE INTO RP_M_NOTIF_TEMPLATE t USING (
  SELECT 'Created'            AS EC, 1 AS CH FROM DUAL UNION ALL
  SELECT 'Escalated',                1        FROM DUAL UNION ALL
  SELECT 'Resolved',                 1        FROM DUAL UNION ALL
  SELECT 'Closed',                   1        FROM DUAL UNION ALL
  SELECT 'ClarificationSought',      1        FROM DUAL UNION ALL
  SELECT 'Reopened',                 1        FROM DUAL UNION ALL
  SELECT 'Broadcast',                1        FROM DUAL
) s ON (t.EVENT_CODE = s.EC AND t.CHANNEL = s.CH)
WHEN NOT MATCHED THEN INSERT (ID, EVENT_CODE, CHANNEL, SUBJECT, BODY)
  VALUES (
    RP_SEQ_GLOBAL.NEXTVAL, s.EC, s.CH,
    CASE s.EC
      WHEN 'Created'             THEN '[#{{ReqNo}}] {{Subject}} — created'
      WHEN 'Escalated'           THEN '[#{{ReqNo}}] Escalated to Level {{CurrentLevel}}'
      WHEN 'Resolved'            THEN '[#{{ReqNo}}] Resolved'
      WHEN 'Closed'              THEN '[#{{ReqNo}}] Closed'
      WHEN 'ClarificationSought' THEN '[#{{ReqNo}}] Clarification needed'
      WHEN 'Reopened'            THEN '[#{{ReqNo}}] Reopened'
      WHEN 'Broadcast'           THEN '{{Subject}}'
    END,
    CASE s.EC
      WHEN 'Created'             THEN 'Hello {{RecipientName}},' || CHR(10) || CHR(10) || 'Request #{{ReqNo}} has been created by {{RaisedByName}}.' || CHR(10) || 'Type: {{RequestTypeName}}' || CHR(10) || 'Subject: {{Subject}}' || CHR(10) || CHR(10) || 'Please log in to the Request Portal to act.'
      WHEN 'Escalated'           THEN 'Hello {{RecipientName}},' || CHR(10) || CHR(10) || 'Request #{{ReqNo}} has been escalated to Level {{CurrentLevel}} due to SLA breach.' || CHR(10) || 'Please take action.'
      WHEN 'Resolved'            THEN 'Hello {{RecipientName}},' || CHR(10) || CHR(10) || 'Request #{{ReqNo}} has been resolved. Please review and provide feedback.'
      WHEN 'Closed'              THEN 'Hello {{RecipientName}},' || CHR(10) || CHR(10) || 'Request #{{ReqNo}} is now closed.'
      WHEN 'ClarificationSought' THEN 'Hello {{RecipientName}},' || CHR(10) || CHR(10) || 'Clarification has been requested on request #{{ReqNo}}.'
      WHEN 'Reopened'            THEN 'Hello {{RecipientName}},' || CHR(10) || CHR(10) || 'Request #{{ReqNo}} has been reopened.'
      WHEN 'Broadcast'           THEN '{{Message}}'
    END
  );

-- ---------------------------------------------------------------------------
-- 7. RBAC MODULE TREE
-- ---------------------------------------------------------------------------

-- Root modules
MERGE INTO RP_RBAC_MODULE t USING (
  SELECT 'MASTERS' AS CODE,'Masters'       AS NAME,1 AS KIND,'Settings'           AS ICON,10  AS SORT_ORDER FROM DUAL UNION ALL
  SELECT 'OPS',            'Operations',           1,         'Assignment',                 20              FROM DUAL UNION ALL
  SELECT 'INQ',            'Inquiry',              2,         'ManageSearch',               30              FROM DUAL UNION ALL
  SELECT 'REPORTS',        'Reports',              3,         'Description',                40              FROM DUAL UNION ALL
  SELECT 'MIS',            'MIS',                  4,         'QueryStats',                 50              FROM DUAL UNION ALL
  SELECT 'DASH',           'Dashboards',           5,         'Dashboard',                  60              FROM DUAL UNION ALL
  SELECT 'ADMIN',          'Administration',       1,         'AdminPanelSettings',         90              FROM DUAL
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, CODE, NAME, KIND, PARENT_ID, ICON, SORT_ORDER, IS_ACTIVE)
  VALUES (RP_SEQ_GLOBAL.NEXTVAL, s.CODE, s.NAME, s.KIND, NULL, s.ICON, s.SORT_ORDER, 1);

-- Child modules
MERGE INTO RP_RBAC_MODULE t USING (
  SELECT CODE, NAME, KIND, PARENT_CODE, ICON, SORT_ORDER FROM (
    -- Masters
    SELECT 'MASTERS.USERS'       AS CODE,'Users'                  AS NAME,1 AS KIND,'MASTERS' AS PARENT_CODE,'PersonOutline'       AS ICON,10  AS SORT_ORDER FROM DUAL UNION ALL
    SELECT 'MASTERS.ROLES',             'Roles',                        1,           'MASTERS',               'BadgeOutlined',           20             FROM DUAL UNION ALL
    SELECT 'MASTERS.UNITS',             'Units',                        1,           'MASTERS',               'AccountTree',             30             FROM DUAL UNION ALL
    SELECT 'MASTERS.VERTICALS',         'Verticals',                    1,           'MASTERS',               'Hub',                     40             FROM DUAL UNION ALL
    SELECT 'MASTERS.DEPARTMENTS',       'Departments',                  1,           'MASTERS',               'GroupWork',               50             FROM DUAL UNION ALL
    SELECT 'MASTERS.ACTIVITIES',        'Activities',                   1,           'MASTERS',               'LocalActivity',           60             FROM DUAL UNION ALL
    SELECT 'MASTERS.REQTYPES',          'Request Types',                1,           'MASTERS',               'Category',                70             FROM DUAL UNION ALL
    SELECT 'MASTERS.HOLIDAYS',          'Holiday Calendar',             1,           'MASTERS',               'Event',                   80             FROM DUAL UNION ALL
    SELECT 'MASTERS.SLA',               'SLA Configuration',            1,           'MASTERS',               'Schedule',                90             FROM DUAL UNION ALL
    SELECT 'MASTERS.NOTIFTPL',          'Notification Templates',       1,           'MASTERS',               'Mail',                    100            FROM DUAL UNION ALL
    SELECT 'MASTERS.ROUTING',           'Routing Rules',                1,           'MASTERS',               'AltRoute',                110            FROM DUAL UNION ALL
    -- Operations
    SELECT 'OPS.NEW',                   'New Request',                  1,           'OPS',                   'Add',                     10             FROM DUAL UNION ALL
    SELECT 'OPS.MINE',                  'My Requests',                  1,           'OPS',                   'InboxOutlined',           20             FROM DUAL UNION ALL
    SELECT 'OPS.ASSIGNED',              'Assigned to Me',               1,           'OPS',                   'AssignmentInd',           30             FROM DUAL UNION ALL
    SELECT 'OPS.TEAM',                  'Team Queue',                   1,           'OPS',                   'Groups',                  40             FROM DUAL UNION ALL
    SELECT 'OPS.DELEGATE',              'Delegations',                  1,           'OPS',                   'SwapHoriz',               50             FROM DUAL UNION ALL
    SELECT 'OPS.BROADCAST',             'Broadcast',                    1,           'OPS',                   'Campaign',                60             FROM DUAL UNION ALL
    -- Inquiry
    SELECT 'INQ.REQ',                   'Request Inquiry',              2,           'INQ',                   'Search',                  10             FROM DUAL UNION ALL
    SELECT 'INQ.USER',                  'User Inquiry',                 2,           'INQ',                   'PersonSearch',            20             FROM DUAL UNION ALL
    SELECT 'INQ.AUDIT',                 'Audit Inquiry',                2,           'INQ',                   'HistoryToggleOff',        30             FROM DUAL UNION ALL
    -- Reports
    SELECT 'REPORTS.DAILY',             'Daily Operations',             3,           'REPORTS',               'Today',                   10             FROM DUAL UNION ALL
    SELECT 'REPORTS.SLA',               'SLA Breach Report',            3,           'REPORTS',               'Timer',                   20             FROM DUAL UNION ALL
    SELECT 'REPORTS.AGING',             'Aging Report',                 3,           'REPORTS',               'HourglassEmpty',          30             FROM DUAL UNION ALL
    -- MIS
    SELECT 'MIS.VOL',                   'Volume MIS',                   4,           'MIS',                   'BarChart',                10             FROM DUAL UNION ALL
    SELECT 'MIS.PROD',                  'Productivity MIS',             4,           'MIS',                   'TrendingUp',              20             FROM DUAL UNION ALL
    -- Dashboards
    SELECT 'DASH.OPS',                  'Operations Dashboard',         5,           'DASH',                  'Speed',                   10             FROM DUAL UNION ALL
    SELECT 'DASH.EXEC',                 'Executive Dashboard',          5,           'DASH',                  'Insights',                20             FROM DUAL UNION ALL
    -- Administration
    SELECT 'ADMIN.RIGHTS',              'Admin Rights',                 1,           'ADMIN',                 'AdminPanelSettings',      10             FROM DUAL UNION ALL
    SELECT 'ADMIN.MODULES',             'Modules & Sub-modules',        1,           'ADMIN',                 'AccountTree',             20             FROM DUAL UNION ALL
    SELECT 'ADMIN.MENUS',               'Menus',                        1,           'ADMIN',                 'Menu',                    30             FROM DUAL UNION ALL
    SELECT 'ADMIN.ROLEPERMS',           'Role Permissions',             1,           'ADMIN',                 'VerifiedUser',            40             FROM DUAL UNION ALL
    SELECT 'ADMIN.USEROVER',            'User Overrides',               1,           'ADMIN',                 'ManageAccounts',          50             FROM DUAL UNION ALL
    SELECT 'ADMIN.VERT_ASSIGN',         'Vertical Level Assignment',    1,           'ADMIN',                 'SupervisedUserCircle',    55             FROM DUAL UNION ALL
    SELECT 'ADMIN.AUDIT',               'RBAC Audit Log',               2,           'ADMIN',                 'HistoryEdu',              60             FROM DUAL
  )
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, CODE, NAME, KIND, PARENT_ID, ICON, SORT_ORDER, IS_ACTIVE)
  VALUES (
    RP_SEQ_GLOBAL.NEXTVAL, s.CODE, s.NAME, s.KIND,
    (SELECT ID FROM RP_RBAC_MODULE WHERE CODE = s.PARENT_CODE),
    s.ICON, s.SORT_ORDER, 1
  );

-- ---------------------------------------------------------------------------
-- 8. RBAC MENUS
-- ---------------------------------------------------------------------------
MERGE INTO RP_RBAC_MENU t USING (
  SELECT CODE, LABEL, MOD_CODE, ROUTE, ICON, SORT_ORDER FROM (
    SELECT 'MENU.NEWREQ'       AS CODE,'New Request'              AS LABEL,'OPS.NEW'              AS MOD_CODE,'/requests/new'                     AS ROUTE,'Add'                    AS ICON,10  AS SORT_ORDER FROM DUAL UNION ALL
    SELECT 'MENU.MINE',               'My Requests',                       'OPS.MINE',                        '/requests/mine',                           'InboxOutlined',              20             FROM DUAL UNION ALL
    SELECT 'MENU.ASSIGNED',           'Assigned to Me',                    'OPS.ASSIGNED',                    '/requests/assigned',                       'AssignmentInd',              30             FROM DUAL UNION ALL
    SELECT 'MENU.TEAM',               'Team Queue',                        'OPS.TEAM',                        '/requests/team',                           'Groups',                     40             FROM DUAL UNION ALL
    SELECT 'MENU.DELEGATE',           'Delegations',                       'OPS.DELEGATE',                    '/requests/delegations',                    'SwapHoriz',                  50             FROM DUAL UNION ALL
    SELECT 'MENU.BROADCAST',          'Broadcast',                         'OPS.BROADCAST',                   '/admin/broadcast',                         'Campaign',                   60             FROM DUAL UNION ALL
    SELECT 'MENU.INQ.REQ',            'Request Inquiry',                   'INQ.REQ',                         '/inquiry/requests',                        'Search',                     10             FROM DUAL UNION ALL
    SELECT 'MENU.INQ.USER',           'User Inquiry',                      'INQ.USER',                        '/inquiry/users',                           'PersonSearch',               20             FROM DUAL UNION ALL
    SELECT 'MENU.REP.SLA',            'SLA Report',                        'REPORTS.SLA',                     '/reports/sla',                             'Timer',                      20             FROM DUAL UNION ALL
    SELECT 'MENU.DASH.OPS',           'Operations Dashboard',              'DASH.OPS',                        '/dashboards/ops',                          'Speed',                      10             FROM DUAL UNION ALL
    SELECT 'MENU.DASH.EXEC',          'Executive Dashboard',               'DASH.EXEC',                       '/dashboards/exec',                         'Insights',                   20             FROM DUAL UNION ALL
    SELECT 'MENU.MAS.USERS',          'Users',                             'MASTERS.USERS',                   '/masters/users',                           'PersonOutline',              10             FROM DUAL UNION ALL
    SELECT 'MENU.MAS.ROLES',          'Roles',                             'MASTERS.ROLES',                   '/masters/roles',                           'BadgeOutlined',              20             FROM DUAL UNION ALL
    SELECT 'MENU.MAS.UNITS',          'Units',                             'MASTERS.UNITS',                   '/masters/units',                           'AccountTree',                30             FROM DUAL UNION ALL
    SELECT 'MENU.MAS.HOL',            'Holiday Calendar',                  'MASTERS.HOLIDAYS',                '/masters/holidays',                        'Event',                      80             FROM DUAL UNION ALL
    SELECT 'MENU.MAS.SLA',            'SLA Configuration',                 'MASTERS.SLA',                     '/masters/sla',                             'Schedule',                   90             FROM DUAL UNION ALL
    SELECT 'MENU.MAS.NOTIF',          'Notification Templates',            'MASTERS.NOTIFTPL',                '/masters/notif-templates',                 'Mail',                       100            FROM DUAL UNION ALL
    SELECT 'MENU.MAS.ROUTING',        'Routing Rules',                     'MASTERS.ROUTING',                 '/masters/routing',                         'AltRoute',                   110            FROM DUAL UNION ALL
    SELECT 'MENU.ADM.RIGHTS',         'Admin Rights',                      'ADMIN.RIGHTS',                    '/admin/rbac/admin-rights',                 'AdminPanelSettings',         10             FROM DUAL UNION ALL
    SELECT 'MENU.ADM.MODULES',        'Modules & Sub-modules',             'ADMIN.MODULES',                   '/admin/rbac/modules',                      'AccountTree',                20             FROM DUAL UNION ALL
    SELECT 'MENU.ADM.MENUS',          'Menus',                             'ADMIN.MENUS',                     '/admin/rbac/menus',                        'Menu',                       30             FROM DUAL UNION ALL
    SELECT 'MENU.ADM.PERMS',          'Role Permissions',                  'ADMIN.ROLEPERMS',                 '/admin/rbac/role-permissions',             'VerifiedUser',               40             FROM DUAL UNION ALL
    SELECT 'MENU.ADM.VERT_ASSIGN',    'Vertical Level Assignment',         'ADMIN.VERT_ASSIGN',               '/admin/rbac/vertical-assignment',          'SupervisedUserCircle',       55             FROM DUAL UNION ALL
    SELECT 'MENU.ADM.AUDIT',          'RBAC Audit Log',                    'ADMIN.AUDIT',                     '/admin/rbac/audit',                        'HistoryEdu',                 60             FROM DUAL
  )
) s ON (t.CODE = s.CODE)
WHEN NOT MATCHED THEN INSERT (ID, MODULE_ID, CODE, LABEL, ICON, ROUTE, SORT_ORDER, IS_ENABLED, IS_ACTIVE)
  VALUES (
    RP_SEQ_GLOBAL.NEXTVAL,
    (SELECT ID FROM RP_RBAC_MODULE WHERE CODE = s.MOD_CODE),
    s.CODE, s.LABEL, s.ICON, s.ROUTE, s.SORT_ORDER, 1, 1
  );

-- ---------------------------------------------------------------------------
-- 9. BASELINE ROLE × MODULE PERMISSION GRID
--
-- Permission logic:
--   Org roles (BRANCH_USER..CO_HEAD): access proportional to hierarchy level.
--   CO_VERT_ADMIN: full operational control + vertical assignment in ADMIN.
--   VERT_L1..L5: additive to org role; enables ticket-processing capabilities.
--   APP_ADMIN / SUPER_ADMIN: full access to everything.
-- ---------------------------------------------------------------------------
DECLARE
  -- Grant or update a role→module permission row
  PROCEDURE grant_perm(
    p_role_code   IN VARCHAR2,
    p_module_code IN VARCHAR2,
    p_view        IN NUMBER DEFAULT 0,
    p_add         IN NUMBER DEFAULT 0,
    p_mod         IN NUMBER DEFAULT 0,
    p_del         IN NUMBER DEFAULT 0,
    p_auth        IN NUMBER DEFAULT 0
  ) IS
    v_role_id   NUMBER(19);
    v_module_id NUMBER(19);
  BEGIN
    BEGIN
      SELECT ID INTO v_role_id   FROM RP_ROLE        WHERE CODE = p_role_code;
      SELECT ID INTO v_module_id FROM RP_RBAC_MODULE WHERE CODE = p_module_code;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('WARN: skip grant ' || p_role_code || '->' || p_module_code);
      RETURN;
    END;
    MERGE INTO RP_RBAC_ROLE_PERM t
    USING (SELECT v_role_id AS RID, v_module_id AS MID FROM DUAL) s
    ON (t.ROLE_ID = s.RID AND t.MODULE_ID = s.MID)
    WHEN MATCHED THEN UPDATE SET
      CAN_VIEW=p_view, CAN_ADD=p_add, CAN_MODIFY=p_mod,
      CAN_DELETE=p_del, CAN_AUTHORIZE=p_auth,
      UPDATED_AT_UTC=SYSTIMESTAMP, UPDATED_BY_EMP='SEED'
    WHEN NOT MATCHED THEN INSERT
      (ID,ROLE_ID,MODULE_ID,CAN_VIEW,CAN_ADD,CAN_MODIFY,CAN_DELETE,CAN_AUTHORIZE,UPDATED_AT_UTC,UPDATED_BY_EMP)
      VALUES (RP_SEQ_GLOBAL.NEXTVAL,s.RID,s.MID,p_view,p_add,p_mod,p_del,p_auth,SYSTIMESTAMP,'SEED');
  END;

  PROCEDURE view_only(p_role IN VARCHAR2, p_mod IN VARCHAR2) IS
  BEGIN grant_perm(p_role, p_mod, 1,0,0,0,0); END;

  PROCEDURE full_access(p_role IN VARCHAR2, p_mod IN VARCHAR2) IS
  BEGIN grant_perm(p_role, p_mod, 1,1,1,1,1); END;

  -- Grant full access for APP_ADMIN and SUPER_ADMIN to all modules
  PROCEDURE admin_full IS
    CURSOR c IS SELECT CODE FROM RP_RBAC_MODULE;
  BEGIN
    FOR m IN c LOOP
      full_access('APP_ADMIN',   m.CODE);
      full_access('SUPER_ADMIN', m.CODE);
    END LOOP;
  END;

BEGIN
  -- ── BRANCH_USER: raise requests + view own + basic dashboard ─────────────
  grant_perm('BRANCH_USER','OPS',     1,1,0,0,0);
  grant_perm('BRANCH_USER','OPS.NEW', 1,1,0,0,0);
  grant_perm('BRANCH_USER','OPS.MINE',1,0,0,0,0);
  view_only('BRANCH_USER','INQ');      view_only('BRANCH_USER','INQ.REQ');
  view_only('BRANCH_USER','DASH');     view_only('BRANCH_USER','DASH.OPS');

  -- ── BRANCH_HEAD: + can see team queue + act on assigned tickets ──────────
  grant_perm('BRANCH_HEAD','OPS',         1,1,0,0,0);
  grant_perm('BRANCH_HEAD','OPS.NEW',     1,1,0,0,0);
  grant_perm('BRANCH_HEAD','OPS.MINE',    1,0,0,0,0);
  grant_perm('BRANCH_HEAD','OPS.ASSIGNED',1,0,1,0,0);
  grant_perm('BRANCH_HEAD','OPS.TEAM',    1,0,0,0,0);
  view_only('BRANCH_HEAD','INQ');         view_only('BRANCH_HEAD','INQ.REQ');
  view_only('BRANCH_HEAD','DASH');        view_only('BRANCH_HEAD','DASH.OPS');

  -- ── RO_USER: branch-head level ops ───────────────────────────────────────
  grant_perm('RO_USER','OPS',         1,1,0,0,0);
  grant_perm('RO_USER','OPS.NEW',     1,1,0,0,0);
  grant_perm('RO_USER','OPS.MINE',    1,0,0,0,0);
  grant_perm('RO_USER','OPS.ASSIGNED',1,0,1,0,0);
  grant_perm('RO_USER','OPS.TEAM',    1,0,0,0,0);
  view_only('RO_USER','INQ');         view_only('RO_USER','INQ.REQ');
  view_only('RO_USER','DASH');        view_only('RO_USER','DASH.OPS');
  view_only('RO_USER','REPORTS');     view_only('RO_USER','REPORTS.SLA');

  -- ── RO_HEAD: + delegation + user inquiry + reports ───────────────────────
  grant_perm('RO_HEAD','OPS',           1,1,0,0,0);
  grant_perm('RO_HEAD','OPS.NEW',       1,1,0,0,0);
  grant_perm('RO_HEAD','OPS.MINE',      1,0,0,0,0);
  grant_perm('RO_HEAD','OPS.ASSIGNED',  1,0,1,0,0);
  grant_perm('RO_HEAD','OPS.TEAM',      1,0,1,0,0);
  grant_perm('RO_HEAD','OPS.DELEGATE',  1,1,1,0,0);
  view_only('RO_HEAD','INQ');           view_only('RO_HEAD','INQ.REQ');
  view_only('RO_HEAD','INQ.USER');
  view_only('RO_HEAD','DASH');          view_only('RO_HEAD','DASH.OPS');
  view_only('RO_HEAD','REPORTS');       view_only('RO_HEAD','REPORTS.SLA');
  view_only('RO_HEAD','REPORTS.AGING');

  -- ── ZO_USER: RO_HEAD level + MIS ─────────────────────────────────────────
  grant_perm('ZO_USER','OPS',           1,1,0,0,0);
  grant_perm('ZO_USER','OPS.NEW',       1,1,0,0,0);
  grant_perm('ZO_USER','OPS.MINE',      1,0,0,0,0);
  grant_perm('ZO_USER','OPS.ASSIGNED',  1,0,1,0,0);
  grant_perm('ZO_USER','OPS.TEAM',      1,0,0,0,0);
  grant_perm('ZO_USER','OPS.DELEGATE',  1,1,1,0,0);
  view_only('ZO_USER','INQ');           view_only('ZO_USER','INQ.REQ');
  view_only('ZO_USER','INQ.USER');      view_only('ZO_USER','INQ.AUDIT');
  view_only('ZO_USER','REPORTS');       view_only('ZO_USER','REPORTS.SLA');
  view_only('ZO_USER','REPORTS.AGING');
  view_only('ZO_USER','MIS');           view_only('ZO_USER','MIS.VOL');
  view_only('ZO_USER','DASH');          view_only('ZO_USER','DASH.OPS');
  view_only('ZO_USER','DASH.EXEC');

  -- ── ZO_HEAD: + modify team queue ─────────────────────────────────────────
  grant_perm('ZO_HEAD','OPS',           1,1,0,0,0);
  grant_perm('ZO_HEAD','OPS.NEW',       1,1,0,0,0);
  grant_perm('ZO_HEAD','OPS.MINE',      1,0,0,0,0);
  grant_perm('ZO_HEAD','OPS.ASSIGNED',  1,0,1,0,0);
  grant_perm('ZO_HEAD','OPS.TEAM',      1,0,1,0,0);
  grant_perm('ZO_HEAD','OPS.DELEGATE',  1,1,1,0,0);
  view_only('ZO_HEAD','INQ');           view_only('ZO_HEAD','INQ.REQ');
  view_only('ZO_HEAD','INQ.USER');      view_only('ZO_HEAD','INQ.AUDIT');
  view_only('ZO_HEAD','REPORTS');       view_only('ZO_HEAD','REPORTS.DAILY');
  view_only('ZO_HEAD','REPORTS.SLA');   view_only('ZO_HEAD','REPORTS.AGING');
  view_only('ZO_HEAD','MIS');           view_only('ZO_HEAD','MIS.VOL');
  view_only('ZO_HEAD','MIS.PROD');
  view_only('ZO_HEAD','DASH');          view_only('ZO_HEAD','DASH.OPS');
  view_only('ZO_HEAD','DASH.EXEC');

  -- ── CO_USER: ZO_HEAD level ────────────────────────────────────────────────
  grant_perm('CO_USER','OPS',           1,1,0,0,0);
  grant_perm('CO_USER','OPS.NEW',       1,1,0,0,0);
  grant_perm('CO_USER','OPS.MINE',      1,0,0,0,0);
  grant_perm('CO_USER','OPS.ASSIGNED',  1,0,1,0,0);
  grant_perm('CO_USER','OPS.TEAM',      1,0,0,0,0);
  grant_perm('CO_USER','OPS.DELEGATE',  1,1,1,0,0);
  view_only('CO_USER','INQ');           view_only('CO_USER','INQ.REQ');
  view_only('CO_USER','INQ.USER');      view_only('CO_USER','INQ.AUDIT');
  view_only('CO_USER','REPORTS');       view_only('CO_USER','REPORTS.DAILY');
  view_only('CO_USER','REPORTS.SLA');   view_only('CO_USER','REPORTS.AGING');
  view_only('CO_USER','MIS');           view_only('CO_USER','MIS.VOL');
  view_only('CO_USER','MIS.PROD');
  view_only('CO_USER','DASH');          view_only('CO_USER','DASH.OPS');
  view_only('CO_USER','DASH.EXEC');

  -- ── CO_HEAD: + authorize delegations + can view broadcast ────────────────
  grant_perm('CO_HEAD','OPS',           1,1,0,0,0);
  grant_perm('CO_HEAD','OPS.NEW',       1,1,0,0,0);
  grant_perm('CO_HEAD','OPS.MINE',      1,0,0,0,0);
  grant_perm('CO_HEAD','OPS.ASSIGNED',  1,0,1,0,0);
  grant_perm('CO_HEAD','OPS.TEAM',      1,0,1,0,0);
  grant_perm('CO_HEAD','OPS.DELEGATE',  1,1,1,0,1);
  grant_perm('CO_HEAD','OPS.BROADCAST', 1,0,0,0,0);
  view_only('CO_HEAD','INQ');           view_only('CO_HEAD','INQ.REQ');
  view_only('CO_HEAD','INQ.USER');      view_only('CO_HEAD','INQ.AUDIT');
  view_only('CO_HEAD','REPORTS');       view_only('CO_HEAD','REPORTS.DAILY');
  view_only('CO_HEAD','REPORTS.SLA');   view_only('CO_HEAD','REPORTS.AGING');
  view_only('CO_HEAD','MIS');           view_only('CO_HEAD','MIS.VOL');
  view_only('CO_HEAD','MIS.PROD');
  view_only('CO_HEAD','DASH');          view_only('CO_HEAD','DASH.OPS');
  view_only('CO_HEAD','DASH.EXEC');

  -- ── CO_VERT_ADMIN: full ops + broadcast + vertical-level assignment ───────
  -- Can reassign tickets, manage delegations for their vertical, send broadcast.
  -- Access to ADMIN.VERT_ASSIGN restricted to their own vertical in application.
  grant_perm('CO_VERT_ADMIN','OPS',             1,1,0,0,0);
  grant_perm('CO_VERT_ADMIN','OPS.NEW',         1,1,0,0,0);
  grant_perm('CO_VERT_ADMIN','OPS.MINE',        1,0,0,0,0);
  grant_perm('CO_VERT_ADMIN','OPS.ASSIGNED',    1,0,1,0,1);
  grant_perm('CO_VERT_ADMIN','OPS.TEAM',        1,0,1,0,1);
  grant_perm('CO_VERT_ADMIN','OPS.DELEGATE',    1,1,1,1,1);
  grant_perm('CO_VERT_ADMIN','OPS.BROADCAST',   1,1,1,0,1);
  view_only('CO_VERT_ADMIN','INQ');             view_only('CO_VERT_ADMIN','INQ.REQ');
  view_only('CO_VERT_ADMIN','INQ.USER');        view_only('CO_VERT_ADMIN','INQ.AUDIT');
  view_only('CO_VERT_ADMIN','REPORTS');         view_only('CO_VERT_ADMIN','REPORTS.DAILY');
  view_only('CO_VERT_ADMIN','REPORTS.SLA');     view_only('CO_VERT_ADMIN','REPORTS.AGING');
  view_only('CO_VERT_ADMIN','MIS');             view_only('CO_VERT_ADMIN','MIS.VOL');
  view_only('CO_VERT_ADMIN','MIS.PROD');
  view_only('CO_VERT_ADMIN','DASH');            view_only('CO_VERT_ADMIN','DASH.OPS');
  view_only('CO_VERT_ADMIN','DASH.EXEC');
  -- Vertical level assignment (their vertical only — scoped in application code)
  grant_perm('CO_VERT_ADMIN','ADMIN',            1,0,0,0,0);
  grant_perm('CO_VERT_ADMIN','ADMIN.VERT_ASSIGN',1,1,1,1,0);

  -- ── VERT_L1: entry-level vertical processor ───────────────────────────────
  grant_perm('VERT_L1','OPS',         1,1,0,0,0);
  grant_perm('VERT_L1','OPS.NEW',     1,1,0,0,0);
  grant_perm('VERT_L1','OPS.MINE',    1,0,0,0,0);
  grant_perm('VERT_L1','OPS.ASSIGNED',1,0,1,0,0);
  grant_perm('VERT_L1','OPS.TEAM',    1,0,0,0,0);
  view_only('VERT_L1','INQ');         view_only('VERT_L1','INQ.REQ');
  view_only('VERT_L1','DASH');        view_only('VERT_L1','DASH.OPS');

  -- ── VERT_L2: + delegation + inquiry audit + reports ───────────────────────
  grant_perm('VERT_L2','OPS',          1,1,0,0,0);
  grant_perm('VERT_L2','OPS.NEW',      1,1,0,0,0);
  grant_perm('VERT_L2','OPS.MINE',     1,0,0,0,0);
  grant_perm('VERT_L2','OPS.ASSIGNED', 1,0,1,0,0);
  grant_perm('VERT_L2','OPS.TEAM',     1,0,0,0,0);
  grant_perm('VERT_L2','OPS.DELEGATE', 1,1,1,0,0);
  view_only('VERT_L2','INQ');          view_only('VERT_L2','INQ.REQ');
  view_only('VERT_L2','INQ.AUDIT');
  view_only('VERT_L2','REPORTS');      view_only('VERT_L2','REPORTS.SLA');
  view_only('VERT_L2','DASH');         view_only('VERT_L2','DASH.OPS');

  -- ── VERT_L3: + delete on assigned + MIS + exec dashboard ──────────────────
  grant_perm('VERT_L3','OPS',          1,1,0,0,0);
  grant_perm('VERT_L3','OPS.NEW',      1,1,0,0,0);
  grant_perm('VERT_L3','OPS.MINE',     1,0,0,0,0);
  grant_perm('VERT_L3','OPS.ASSIGNED', 1,0,1,1,0);
  grant_perm('VERT_L3','OPS.TEAM',     1,0,1,0,0);
  grant_perm('VERT_L3','OPS.DELEGATE', 1,1,1,0,0);
  view_only('VERT_L3','INQ');          view_only('VERT_L3','INQ.REQ');
  view_only('VERT_L3','INQ.USER');     view_only('VERT_L3','INQ.AUDIT');
  view_only('VERT_L3','REPORTS');      view_only('VERT_L3','REPORTS.SLA');
  view_only('VERT_L3','REPORTS.AGING');
  view_only('VERT_L3','MIS');          view_only('VERT_L3','MIS.VOL');
  view_only('VERT_L3','DASH');         view_only('VERT_L3','DASH.OPS');
  view_only('VERT_L3','DASH.EXEC');

  -- ── VERT_L4: + authorize on assigned/team + broadcast ─────────────────────
  grant_perm('VERT_L4','OPS',          1,1,0,0,0);
  grant_perm('VERT_L4','OPS.NEW',      1,1,0,0,0);
  grant_perm('VERT_L4','OPS.MINE',     1,0,0,0,0);
  grant_perm('VERT_L4','OPS.ASSIGNED', 1,0,1,1,1);
  grant_perm('VERT_L4','OPS.TEAM',     1,0,1,0,1);
  grant_perm('VERT_L4','OPS.DELEGATE', 1,1,1,0,1);
  grant_perm('VERT_L4','OPS.BROADCAST',1,1,1,0,0);
  view_only('VERT_L4','INQ');          view_only('VERT_L4','INQ.REQ');
  view_only('VERT_L4','INQ.USER');     view_only('VERT_L4','INQ.AUDIT');
  view_only('VERT_L4','REPORTS');      view_only('VERT_L4','REPORTS.DAILY');
  view_only('VERT_L4','REPORTS.SLA');  view_only('VERT_L4','REPORTS.AGING');
  view_only('VERT_L4','MIS');          view_only('VERT_L4','MIS.VOL');
  view_only('VERT_L4','MIS.PROD');
  view_only('VERT_L4','DASH');         view_only('VERT_L4','DASH.OPS');
  view_only('VERT_L4','DASH.EXEC');

  -- ── VERT_L5: oversight — view everything, no destructive ops ──────────────
  FOR m IN (
    SELECT CODE FROM RP_RBAC_MODULE
     WHERE CODE NOT LIKE 'MASTERS%' AND CODE NOT LIKE 'ADMIN%'
  ) LOOP
    view_only('VERT_L5', m.CODE);
  END LOOP;

  -- ── APP_ADMIN / SUPER_ADMIN: full access to every module ─────────────────
  admin_full;

END;
/

-- ---------------------------------------------------------------------------
-- 10. PAGE INFO SEED
-- ---------------------------------------------------------------------------
DECLARE
  PROCEDURE upsert_page(
    p_key IN VARCHAR2, p_name IN VARCHAR2, p_type IN VARCHAR2,
    p_desc IN VARCHAR2, p_vert IN VARCHAR2, p_owner IN VARCHAR2,
    p_ip IN VARCHAR2, p_mail IN VARCHAR2, p_ver IN VARCHAR2
  ) IS
    v_n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_n FROM RP_PAGE_INFO WHERE PAGE_KEY = p_key;
    IF v_n = 0 THEN
      INSERT INTO RP_PAGE_INFO
        (PAGE_KEY,PAGE_NAME,PAGE_TYPE,DESCRIPTION,OWNER_VERTICAL,MODULE_OWNER,IP_NUMBER,MAIL_ID,VERSION,STATUS)
      VALUES (p_key,p_name,p_type,p_desc,p_vert,p_owner,p_ip,p_mail,p_ver,'ACTIVE');
    END IF;
  END;
BEGIN
  upsert_page('app-home','App Home','Dashboard','Landing page.','IT','IT Team','IP-RP-2024-0001','it.support@company.in','v1.0');
  upsert_page('requests-new','New Request','Upload','Submit a new service request.','Operations','Ops Team','IP-RP-2024-0010','ops@company.in','v1.0');
  upsert_page('requests-mine','My Requests','Enquiry','Personal request dashboard.','Operations','Ops Team','IP-RP-2024-0011','ops@company.in','v1.0');
  upsert_page('requests-detail','Request Detail','Enquiry','Full detail view for a single request.','Operations','Ops Team','IP-RP-2024-0012','ops@company.in','v1.0');
  upsert_page('requests-assigned','Assigned to Me','Approve','Handler inbox for pending requests.','Operations','Ops Team','IP-RP-2024-0020','ops@company.in','v1.0');
  upsert_page('requests-team','Team Queue','Approve','Team queue for all pending requests.','Operations','Ops Team','IP-RP-2024-0021','ops@company.in','v1.0');
  upsert_page('requests-delegations','Delegations','Maintenance','Manage delegation rules when a handler is absent.','Operations','Ops Admin','IP-RP-2024-0055','ops.admin@company.in','v1.0');
  upsert_page('oversight-dashboard','Operations Dashboard','Dashboard','Supervisory dashboard with cross-team request metrics.','Operations','Ops Team','IP-RP-2024-0030','ops@company.in','v1.0');
  upsert_page('dashboards-exec','Executive Dashboard','Dashboard','Executive view with vertical-level KPI summaries.','Operations','Ops Admin','IP-RP-2024-0031','ops.admin@company.in','v1.0');
  upsert_page('masters-users','Users Master','Maintenance','Manage employee role overrides.','HR / IT','HR Admin','IP-RP-2024-0040','hr.admin@company.in','v1.0');
  upsert_page('masters-roles','Roles Master','Maintenance','Define and manage portal roles.','IT','IT Admin','IP-RP-2024-0041','it.admin@company.in','v1.0');
  upsert_page('masters-units','Units Master','Maintenance','Business units master.','Operations','Ops Admin','IP-RP-2024-0044','ops.admin@company.in','v1.0');
  upsert_page('admin-broadcast','Broadcast','Maintenance','Send portal-wide announcements.','IT','IT Admin','IP-RP-2024-0056','it.admin@company.in','v1.0');
  upsert_page('admin-audit-search','Audit Search','Report','Search and export audit trail.','Compliance','Compliance Team','IP-RP-2024-0057','compliance@company.in','v1.0');
  upsert_page('rbac-menus','Menu Management','Maintenance','Add and toggle navigation menus.','IT','IT Admin','IP-RP-2024-0060','it.admin@company.in','v1.0');
  upsert_page('rbac-modules','Module Management','Maintenance','Configure portal modules.','IT','IT Admin','IP-RP-2024-0061','it.admin@company.in','v1.0');
  upsert_page('rbac-role-permissions','Role Permissions','Maintenance','Define what each role can do.','IT','IT Admin','IP-RP-2024-0062','it.admin@company.in','v1.0');
  upsert_page('rbac-admin-rights','Admin Rights','Maintenance','Grant or revoke App Admin privileges.','IT','IT Admin','IP-RP-2024-0063','it.admin@company.in','v1.0');
  upsert_page('rbac-vertical-assignment','Vertical Level Assignment','Maintenance','CO Vertical Admin assigns VERT_L1–L5 to employees within their vertical.','IT','IT Admin','IP-RP-2024-0064','it.admin@company.in','v1.0');
  upsert_page('rbac-audit-log','RBAC Audit Log','Report','Audit log of all RBAC changes.','Compliance','Compliance Team','IP-RP-2024-0065','compliance@company.in','v1.0');
  upsert_page('reports-sla','SLA Report','Report','SLA compliance with breach analysis.','Operations','Ops Admin','IP-RP-2024-0070','ops.admin@company.in','v1.0');
  upsert_page('notifications','Notifications','Enquiry','User notification centre.','IT','IT Admin','IP-RP-2024-0080','it.admin@company.in','v1.0');
  upsert_page('profile-user','User Profile','Maintenance','View personal profile.','HR / IT','IT Admin','IP-RP-2024-0081','it.admin@company.in','v1.0');
  upsert_page('inquiry-requests','Request Inquiry','Enquiry','Search request status.','Operations','Ops Team','IP-RP-2024-0083','ops@company.in','v1.0');
  upsert_page('inquiry-users','User Inquiry','Enquiry','View employee details and role assignments.','IT','IT Admin','IP-RP-2024-0084','it.admin@company.in','v1.0');
END;
/

COMMIT;
