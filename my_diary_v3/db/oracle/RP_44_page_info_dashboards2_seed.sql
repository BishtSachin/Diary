--------------------------------------------------------------------------
-- RP_44_page_info_dashboards2_seed.sql
--
-- Adds the RP_PAGE_INFO row for the PageHeader/PageInfoIcon on the
-- Assurance Hub page (/Dashboards2 — renamed from "Assurance Corner" to
-- "Assurance Hub"). Additive-only, idempotent (MERGE ... WHEN NOT
-- MATCHED), same pattern as RP_23/RP_41.
--
-- If an environment already has a row keyed 'assurance-corner' (from an
-- earlier deploy of this script before the rename), run this UPDATE first:
--   UPDATE RP_PAGE_INFO SET PAGE_KEY='assurance-hub', PAGE_NAME='Assurance Hub'
--   WHERE PAGE_KEY='assurance-corner';
--------------------------------------------------------------------------

MERGE INTO RP_PAGE_INFO t
USING (SELECT 'assurance-hub' AS PAGE_KEY FROM dual) s
ON (t.PAGE_KEY = s.PAGE_KEY)
WHEN NOT MATCHED THEN
INSERT (PAGE_KEY, PAGE_NAME, PAGE_TYPE, DESCRIPTION, OWNER_VERTICAL,
        MODULE_OWNER, IP_NUMBER, MAIL_ID, CREATED_DATE, VERSION, STATUS)
VALUES ('assurance-hub', 'Assurance Hub', 'Dashboard',
        'Consolidated hub for assurance dashboards, reports, compliance and operations tools',
        'Assurance', 'Assurance Team', '-', 'assurance.support@unionbankofindia.bank',
        SYSDATE, 'v1.0', 'ACTIVE');

-- New "Business Hub" page (/BusinessHub), created alongside the
-- Assurance Hub rename, using the same MENU_CATEGORY-driven card model.
MERGE INTO RP_PAGE_INFO t
USING (SELECT 'business-hub' AS PAGE_KEY FROM dual) s
ON (t.PAGE_KEY = s.PAGE_KEY)
WHEN NOT MATCHED THEN
INSERT (PAGE_KEY, PAGE_NAME, PAGE_TYPE, DESCRIPTION, OWNER_VERTICAL,
        MODULE_OWNER, IP_NUMBER, MAIL_ID, CREATED_DATE, VERSION, STATUS)
VALUES ('business-hub', 'Business Hub', 'Dashboard',
        'Consolidated hub for business dashboards, reports and analytics tools',
        'Business', 'Business Team', '-', 'business.support@unionbankofindia.bank',
        SYSDATE, 'v1.0', 'ACTIVE');

COMMIT;
