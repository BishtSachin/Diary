--------------------------------------------------------------------------
-- RP_47_dashboards2_hub_flags_review.sql
--
-- Manual, card-by-card review of every row on
-- MYDIARYDB.APP_USERS_ROLE_ACCESS_MENU_MASTER, correcting the
-- SHOW_IN_ASSURANCE_HUB / SHOW_IN_BUSINESS_HUB flags (added in RP_46)
-- beyond the blanket category-level backfill that migration applied.
-- RP_46's backfill set the flag the SAME for every row in a category;
-- this script overrides individual rows where the card's actual purpose
-- doesn't match that blanket default, and assigns hub flags to the 15
-- rows that had a blank MENU_CATEGORY (previously N/N in both hubs,
-- effectively orphaned) — reusing existing category names so no new,
-- unexpected tabs are introduced.
--
-- Run as the MYDIARYDB user. Safe to re-run (each UPDATE is absolute,
-- not incremental).
--------------------------------------------------------------------------

-- ── Analytics: ATR (Action Taken Report) items are audit/compliance
--    content, not business-growth reports — Assurance only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Mandatory ATR Report - Daily Dashboard' AND MENU_CATEGORY = 'Analytics';

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Mandatory Report ATR MIS' AND MENU_CATEGORY = 'Analytics';

-- ── Dashboards: same ATR reasoning for the general one.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Mandatory ATR Report' AND MENU_CATEGORY = 'Dashboards';

-- ── Utilities: technical/IT operations monitoring, not business-facing.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'CBS Failed Batch Job' AND MENU_CATEGORY = 'Utilities';

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Login Report' AND MENU_CATEGORY = 'Utilities';

-- ── Utilities: DEA funds remitted to RBI is regulatory/compliance,
--    matching the identically-purposed "DEA Fund remitted to RBI" under
--    Operations (already Assurance-only) — align for consistency.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'DEA Funds Remitted To RBI' AND MENU_CATEGORY = 'Utilities';

-- ── Utilities: TPP distribution tracking is a sales/business metric,
--    not an assurance/audit concern — Business only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET SHOW_IN_ASSURANCE_HUB = 'N', SHOW_IN_BUSINESS_HUB = 'Y'
 WHERE MENU_NAME = 'Third Party Product Distribution Dashboard' AND MENU_CATEGORY = 'Utilities';

--------------------------------------------------------------------------
-- Blank-category rows: previously N/N in both hubs (invisible everywhere).
-- Assign both a hub flag and a MENU_CATEGORY, reusing an EXISTING
-- category name so they render under an existing tab rather than
-- silently sitting in "All" only or creating a brand-new tab.
--------------------------------------------------------------------------

-- RBI regulatory observation dashboards → Compliance, Assurance only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Compliance', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Dashboard CA RBI Observations' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Compliance', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Dashboard CA RBI Observations Cust ID Wise' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Compliance', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Dashboard SB RBI Observations' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Compliance', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Dashboard SB RBI Observations Cust ID Wise(Active)' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Compliance', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Dashboard SB RBI Observations Cust ID Wise(Inactive)' AND MENU_CATEGORY IS NULL;

-- Corporate/business financial results → Dashboards, Business only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Dashboards', SHOW_IN_ASSURANCE_HUB = 'N', SHOW_IN_BUSINESS_HUB = 'Y'
 WHERE MENU_NAME = 'Financial Results' AND MENU_CATEGORY IS NULL;

-- Clearing (inward/outward) is a reconciliation activity → Recon, Assurance only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Recon', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Inward Clearing' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Recon', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Outward Clearing' AND MENU_CATEGORY IS NULL;

-- JOSH 2.0 is a strategy/staff-engagement program → Dashboards, Business only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Dashboards', SHOW_IN_ASSURANCE_HUB = 'N', SHOW_IN_BUSINESS_HUB = 'Y'
 WHERE MENU_NAME = 'JOSH 2.0 Dashboard' AND MENU_CATEGORY IS NULL;

-- NEDU TV device status is technical/branch operations → Operations, Assurance only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Operations', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'NEDU TV Status' AND MENU_CATEGORY IS NULL;

-- Service Branch sundry/suspense data are reconciliation reports, same
-- family as the existing "Sundry Data - OAB" / "Suspense Data - OAB" etc.
-- already under Recon → Recon, Assurance only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Recon', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Service Branch - Sundry Data - OAB' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Recon', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Service Branch - Sundry Data - OAP' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Recon', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Service Branch - Suspense Data - OAB' AND MENU_CATEGORY IS NULL;

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Recon', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'Service Branch - Suspense Data - OAP' AND MENU_CATEGORY IS NULL;

-- ZOHO CRM pending complaints → Complaints, Assurance only.
UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
   SET MENU_CATEGORY = 'Complaints', SHOW_IN_ASSURANCE_HUB = 'Y', SHOW_IN_BUSINESS_HUB = 'N'
 WHERE MENU_NAME = 'ZOHO CRM Pending Complaints' AND MENU_CATEGORY IS NULL;

COMMIT;
