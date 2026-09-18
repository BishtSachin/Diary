-- ============================================================================
-- 00_RUN_ALL.sql — ordered apply script for the Request Portal (RP_OWNER) schema
--
-- Run as RP_OWNER from this directory:
--     sqlplus RP_OWNER/<pwd>@<host>:1521/<service> @00_RUN_ALL.sql
--
-- Order matters: base schema/seed first, then the incremental change scripts.
-- Every increment is idempotent (guarded), so re-running is safe.
-- ============================================================================
SET SERVEROUTPUT ON
SET SQLBLANKLINES ON
WHENEVER SQLERROR CONTINUE

PROMPT === Base schema + seed ===
@@PROD_FULL_MIGRATION.sql          -- full base: tables, sequences, RBAC, masters, seed
@@RP_04_superadmin.sql             -- bootstrap super admin (superseded by RP_11 in prod)

PROMPT === Incremental changes ===
@@RP_06_escalation_matrix.sql      -- Escalation Matrix: RP_M_EMPLOYEE + RP_ESCALATION_MATRIX + seed
@@RP_07_classification_mapping.sql -- Classification interlink: RP_M_REQTYPE_UNITTYPE + RP_M_UNIT_VERTICAL
@@RP_08_uccrmc.sql                 -- UCCRMC: RP_REQUEST.EXT_ALERT_ID/EXT_SOURCE + 'UCCRMC Alert' type + chain
@@RP_09_notification_userid_fix.sql-- RP_NOTIFICATION: EMP_CODE -> USER_ID (repo alignment)
@@RP_10_entrymode_and_attachment_blob.sql -- RP_M_REQUEST_TYPE.ENTRY_MODE + RP_ATTACHMENT_BLOB
@@RP_11_superadmins.sql            -- Production super admins: 921592, 713907 (removes demo 860921)
@@RP_12_sample_users_routing_requests.sql -- Sample users/emails + routing (713907 as L1) + sample requests
@@RP_13_assurance_menu.sql         -- Assurance Snapshot RBAC (all-employees dashboard)
@@RP_14_unittype_seed.sql          -- RP_M_UNIT_TYPE standard unit types seed
@@RP_15_vertical_seed.sql          -- RP_M_VERTICAL bank verticals seed (ID = SOL ID)
@@RP_16_co_mapping.sql             -- CO vertical->dept->activity reset (keeps only UCCRMC); units cleared
@@RP_17_classification_masters_seed.sql -- Snapshot seed of unit types/verticals/units/depts/activities (current state)
@@RP_18_qlik_menu.sql              -- Qlik Dashboard RBAC (all-employees dashboard)
@@RP_19_unionhub_menu.sql          -- Union Hub (Corporate Events feed) RBAC (all-employees)
@@RP_20_rename_uccrms_to_uccrmc.sql -- Rename UCCRMS -> UCCRMC (request type code/name + activity name)
@@RP_21_nav_seed.sql               -- DB-driven sidebar: RP_RBAC_MODULE/MENU/ROLE_PERM = the nav tree
@@RP_22_unionhub_tables.sql        -- Union Hub structures: EV_TAG/EV_EVENT/EV_POST/EV_POST_IMAGE/EV_ACTIVITY_LOG + RP_RBAC_VERTICAL_ADMIN
@@RP_23_page_info_seed.sql         -- Page-info (ⓘ) metadata for My-Diary menus/sub-menus + missing RP keys (RP_PAGE_INFO)
@@RP_24_report_module.sql          -- Report Module: RP_M_REPORT_DEF (report definitions master)
@@RP_25_report_dr_and_audit.sql    -- Report Module: DC/DR mirror columns + RP_REPORT_AUDIT_LOG + RP_REPORT_ACCESS_LOG
@@RP_30_report_impala_source.sql   -- Report Developer: allow SOURCE_TYPE='IMPALA' (Hive/Impala via Knox)
@@RP_31_report_code.sql            -- Report Developer: RP_M_REPORT_DEF.REPORT_CODE (unique, stable cross-ref id)
@@RP_32_report_filters.sql         -- Report Developer: RP_M_REPORT_FILTER (Zone/Region/Branch/Custom filters)
@@RP_33_report_connection_name.sql -- Report Developer: RP_M_REPORT_DEF.CONNECTION_NAME (admin-picked appsettings key)

PROMPT === Done. Verify: ===
SELECT 'super_admins' item, COUNT(*) n FROM RP_RBAC_SUPER_ADMIN
UNION ALL SELECT 'req_types',   COUNT(*) FROM RP_M_REQUEST_TYPE
UNION ALL SELECT 'esc_matrix',  COUNT(*) FROM RP_ESCALATION_MATRIX
UNION ALL SELECT 'attach_blob_tbl', COUNT(*) FROM USER_TABLES WHERE TABLE_NAME='RP_ATTACHMENT_BLOB';
