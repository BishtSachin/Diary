-- ============================================================================
-- RP_23_page_info_seed.sql — page-information (ⓘ) metadata for menus & sub-menus
--
-- Seeds RP_PAGE_INFO with the keys that were missing: the My-Diary module /
-- sub-module pages (md-*) plus four Request-Portal pages that were referenced
-- by a PageHeader/PageInfoIcon but had no row yet.
--
-- Idempotent: MERGE ... WHEN NOT MATCHED only inserts missing keys, so existing
-- rows (and any edits made via Admin > Page Config) are preserved on re-run.
-- Prod uses OraclePageInfoService (RP_PAGE_INFO). Dev uses DemoPageInfoService,
-- whose in-memory seed carries the same rows.
-- ============================================================================
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
  PROCEDURE up(k VARCHAR2, n VARCHAR2, ty VARCHAR2, ds VARCHAR2,
               ov VARCHAR2, mo VARCHAR2, ip VARCHAR2, mi VARCHAR2,
               vr VARCHAR2 DEFAULT 'v1.0', st VARCHAR2 DEFAULT 'ACTIVE') IS
  BEGIN
    MERGE INTO RP_PAGE_INFO t
    USING (SELECT k AS PAGE_KEY FROM dual) s
    ON (t.PAGE_KEY = s.PAGE_KEY)
    WHEN NOT MATCHED THEN
      INSERT (PAGE_KEY, PAGE_NAME, PAGE_TYPE, DESCRIPTION, OWNER_VERTICAL,
              MODULE_OWNER, IP_NUMBER, MAIL_ID, CREATED_DATE, VERSION, STATUS)
      VALUES (k, n, ty, ds, ov, mo, ip, mi, SYSDATE, vr, st);
  END;
BEGIN
  -- ── Request Portal keys referenced by pages but previously unseeded ──────
  up('escalation-matrix', 'Escalation Matrix', 'Enquiry',
     'Level-wise (L1-L5) escalation contacts for a selected activity/unit, driven by cascading classification filters. Visible to all staff.',
     'Operations', 'Ops Team', 'IP-RP-2025-0010', 'ops@company.in');
  up('escalation-matrix-admin', 'Escalation Matrix - Manage', 'Maintenance',
     'Admin screen to define and maintain the L1-L5 escalation members for each activity (PF, name, scale, role, email, mobile, IP, generic mailbox).',
     'Operations', 'Ops Admin', 'IP-RP-2025-0011', 'ops.admin@company.in');
  up('classification-map', 'Classification Mapping', 'Maintenance',
     'Interlink master mapping request types to unit types and units to verticals; drives the cascading classification across the portal.',
     'Operations', 'Ops Admin', 'IP-RP-2025-0012', 'ops.admin@company.in');
  up('admin-api-help-uccrmc', 'API Help - UCCRMC Alerts', 'Enquiry',
     'Developer reference for the UCCRMC alert-ingestion API - endpoint, X-Api-Key auth, payload schema and samples.',
     'IT', 'IT Admin', 'IP-RP-2025-0013', 'it.admin@company.in');

  -- ── My-Diary modules / sub-modules (menus & sub-menus) ───────────────────
  up('md-home', 'Home', 'Dashboard',
     'Employee home - corporate events feed, staff details, branch profile and quick actions (New Request, My Requests, Escalation Matrix).',
     'IT / Digital Banking', 'MyDiary Team', 'IP-MD-2025-0001', 'mydiary@unionbankofindia.bank.in');
  up('md-home-exec', 'Home (Executive)', 'Dashboard',
     'Executive home - bank-wide Business KPIs, Advances and Deposits performance/growth/portfolio charts, and operational snapshot cards.',
     'Strategy / Analytics', 'MyDiary Team', 'IP-MD-2025-0002', 'mydiary@unionbankofindia.bank.in', 'v2.0');
  up('md-home-legacy', 'Home (Legacy)', 'Dashboard',
     'Previous-generation landing dashboard retained for reference during the transition to the redesigned Home pages.',
     'IT / Digital Banking', 'MyDiary Team', 'IP-MD-2025-0003', 'mydiary@unionbankofindia.bank.in');
  up('md-departments', 'Departments', 'Enquiry',
     'Directory of bank departments with quick links to each department resources, downloads, circulars and policies.',
     'IT / Digital Banking', 'MyDiary Team', 'IP-MD-2025-0004', 'mydiary@unionbankofindia.bank.in');
  up('md-ecirculars', 'e-Circulars', 'Enquiry',
     'Searchable repository of bank e-Circulars sourced from the DMS, browsable by department and year.',
     'Compliance', 'Compliance Team', 'IP-MD-2025-0005', 'compliance@unionbankofindia.bank.in');
  up('md-policies', 'Policies', 'Enquiry',
     'Central library of bank policies and guidelines, categorised by department and reviewed periodically.',
     'Compliance', 'Compliance Team', 'IP-MD-2025-0006', 'compliance@unionbankofindia.bank.in');
  up('md-downloads', 'Downloads', 'Enquiry',
     'Downloadable forms, templates, manuals and reference material used across branches and offices.',
     'IT / Digital Banking', 'MyDiary Team', 'IP-MD-2025-0007', 'mydiary@unionbankofindia.bank.in');
  up('md-kpi', 'Key Performance Indicator', 'Dashboard',
     'Branch/office KPI dashboard within Focus 360 - target-vs-achievement radial and performance summaries.',
     'Strategy / Analytics', 'Branch Analytics', 'IP-MD-2025-0008', 'analytics@unionbankofindia.bank.in');
  up('md-focus360', 'Focus 360', 'Dashboard',
     '360-degree branch performance snapshot with parameter-driven gap analysis across Financial, Operational and Compliance verticals; exports to Excel and PDF.',
     'Strategy / Analytics', 'Branch Analytics', 'IP-MD-2025-0009', 'analytics@unionbankofindia.bank.in', 'v2.0');
  up('md-business360', 'Business 360', 'Dashboard',
     'Business hub - zone/region/branch drill-down across Advances, Deposits, Staff Details, ATM/CRM, Amenities, Branch Profile and Assurance Function.',
     'Strategy / Analytics', 'Branch Analytics', 'IP-MD-2025-0010', 'analytics@unionbankofindia.bank.in', 'v2.0');
  up('md-business360-legacy', 'Business 360 (Legacy)', 'Dashboard',
     'Previous Business 360 layout retained during the transition to the redesigned hub.',
     'Strategy / Analytics', 'Branch Analytics', 'IP-MD-2025-0011', 'analytics@unionbankofindia.bank.in');
  up('md-assurance-snapshot', 'Assurance Snapshot', 'Report',
     'Branch-wise Financial, Operational and Compliance assurance parameters with Excel/PDF/CSV export and print.',
     'Assurance / Audit', 'Assurance Team', 'IP-MD-2025-0012', 'assurance@unionbankofindia.bank.in');
  up('md-assurance-corner', 'Assurance Corner', 'Dashboard',
     'Assurance dashboards and thematic snapshots supporting the assurance and audit functions.',
     'Assurance / Audit', 'Assurance Team', 'IP-MD-2025-0013', 'assurance@unionbankofindia.bank.in');
  up('md-mis', 'MIS', 'Report',
     'Management Information System reports and analytics consolidating operational and business metrics.',
     'Strategy / Analytics', 'MIS Team', 'IP-MD-2025-0014', 'mis@unionbankofindia.bank.in');
  up('md-qlik', 'Qlik Dashboard', 'Dashboard',
     'Embedded Qlik Sense Enterprise dashboards via qlik-embed with QPS ticket authentication; supports Save-As-PDF.',
     'Strategy / Analytics', 'MIS Team', 'IP-MD-2025-0015', 'mis@unionbankofindia.bank.in');
  up('md-applications', 'Applications', 'Enquiry',
     'Launchpad of internal banking applications and portals available to staff, grouped by function.',
     'IT / Digital Banking', 'MyDiary Team', 'IP-MD-2025-0016', 'mydiary@unionbankofindia.bank.in');
  up('md-atm-indent', 'ATM Indent', 'Upload',
     'Raise and track ATM cash/consumables indents for branches, routed to the procurement/operations team.',
     'Operations', 'Procurement Team', 'IP-MD-2025-0017', 'procurement@unionbankofindia.bank.in');
  up('md-union-hub', 'Union Hub', 'Enquiry',
     'Corporate events and updates feed - verticals post announcements, photos, upcoming events and tags for all staff.',
     'Corporate Communications', 'CorpComm Team', 'IP-MD-2025-0018', 'corpcomm@unionbankofindia.bank.in');
  up('report-developer', 'Report Developer', 'Maintenance',
     'Super Admin tool to define report sources (Server File Path, SFTP, Oracle DB, MS SQL Server DB), capture connection details and queries, and publish them to the Reports page under a Vertical/Department.',
     'IT / Analytics', 'IT Admin', 'IP-MD-2025-0019', 'it.admin@unionbankofindia.bank.in');
  up('report-module-reports', 'Reports', 'Report',
     'Filter published reports by Vertical, Department and Report Name, load up to 200 rows with paging (25/50/100 per page), and export to Excel, PDF or CSV.',
     'IT / Analytics', 'IT Admin', 'IP-MD-2025-0020', 'it.admin@unionbankofindia.bank.in');

  COMMIT;
END;
/

PROMPT === RP_23 page-info seed applied. Rows in RP_PAGE_INFO: ===
SELECT COUNT(*) AS page_info_rows FROM RP_PAGE_INFO;
