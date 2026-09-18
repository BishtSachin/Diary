-- ============================================================
-- My Diary V3 — Oracle Seed Data
-- Roles, RBAC modules, notification templates
-- ============================================================

-- ── Roles (maps to RoleCode enum) ────────────────────────────────────────

INSERT INTO MD_ROLE (CODE, NAME) VALUES (1,  'BranchUser');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (2,  'BranchHead');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (3,  'RoUser');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (4,  'RoHead');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (5,  'ZoUser');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (6,  'ZoHead');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (7,  'CoUser');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (8,  'CoHead');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (9,  'CoVertAdmin');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (10, 'AppAdmin');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (11, 'SuperAdmin');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (12, 'VertL1');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (13, 'VertL2');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (14, 'VertL3');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (15, 'VertL4');
INSERT INTO MD_ROLE (CODE, NAME) VALUES (16, 'VertL5');

-- ── RBAC Modules ─────────────────────────────────────────────────────────

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('HOME',             'Home Dashboard',       5, 1);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('KPI',              'Key Performance',      5, 2);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('FOCUS360',         'Focus 360',            5, 3);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('BUSINESS360',      'Business 360',         5, 4);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('ASSURANCE',        'Assurance Corner',     3, 5);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('APPLICATIONS',     'Applications',         5, 6);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('DEPARTMENTS',      'Departments',          5, 7);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('DOWNLOADS',        'Downloads',            5, 8);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('MIS',              'MIS',                  4, 9);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('REQUEST_PORTAL',   'Request Portal',       1, 10);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('NOTIFICATIONS',    'Notifications',        5, 11);

INSERT INTO MD_RBAC_MODULE (CODE, DISPLAY_NAME, KIND, SORT_ORDER)
VALUES ('ADMIN',            'Administration',       1, 99);

-- ── Grant VIEW on all modules to all roles by default ─────────────────────
-- This fulfils the requirement: "All Project B pages accessible to all users initially"

DECLARE
    CURSOR c_roles   IS SELECT ID FROM MD_ROLE;
    CURSOR c_modules IS SELECT ID FROM MD_RBAC_MODULE;
BEGIN
    FOR r IN c_roles LOOP
        FOR m IN c_modules LOOP
            INSERT INTO MD_ROLE_MODULE_PERM
                (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_MODIFY, CAN_DELETE, CAN_AUTHORIZE)
            VALUES
                (r.ID, m.ID, 1, 0, 0, 0, 0);
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ── Sample notification templates ─────────────────────────────────────────

INSERT INTO MD_NOTIF_TEMPLATE (EVENT_CODE, CHANNEL, SUBJECT, BODY, IS_ACTIVE)
VALUES (
    'REQUEST_CREATED', 1,
    'New Request Created — {{ReqNo}}',
    'Dear {{RecipientName}},\n\nA new request {{ReqNo}} has been submitted by {{RaisedByName}}.\n\nType: {{RequestTypeName}}\nStatus: {{Status}}\n\nPlease log in to My Diary to review.\n\nRegards,\nMy Diary System',
    1
);

INSERT INTO MD_NOTIF_TEMPLATE (EVENT_CODE, CHANNEL, SUBJECT, BODY, IS_ACTIVE)
VALUES (
    'REQUEST_RESOLVED', 1,
    'Request Resolved — {{ReqNo}}',
    'Dear {{RecipientName}},\n\nYour request {{ReqNo}} has been resolved.\n\nPlease log in to My Diary to provide feedback.\n\nRegards,\nMy Diary System',
    1
);

-- ── Sitemap for search ────────────────────────────────────────────────────

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('Home Dashboard', '/Landing_Dashboard_V2_1', 'Dashboard', 'home dashboard main landing');

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('KPI Dashboard', '/dashboard_new_1', 'Dashboard', 'kpi key performance indicator metrics');

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('Focus 360', '/focus360', 'Analytics', 'focus 360 gap performance report');

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('Business 360', '/business-new', 'Analytics', 'business 360 business report');

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('New Request', '/requests/new', 'Requests', 'new request create submit ticket');

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('My Requests', '/requests/mine', 'Requests', 'my requests status track');

INSERT INTO MYDIARY_LANDING_SITEMAP (NAME, URL, CATEGORY, KEYWORDS)
VALUES ('MIS Reports', '/MIS', 'Reports', 'mis management information system reports');

COMMIT;
