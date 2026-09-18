--------------------------------------------------------------------------
-- RP_46_dashboards2_hub_flags.sql
--
-- Moves "which hub does this card/tab belong to" out of hardcoded C#
-- AllowedCategories sets (previously in Dashboards2.razor/BusinessHub.razor)
-- and into the database, on MYDIARYDB.APP_USERS_ROLE_ACCESS_MENU_MASTER —
-- the same table that already drives every card, tab (MENU_CATEGORY),
-- sub-tab (MENU_SUBCATEGORY) and card→page link (MENU_ROUTE).
--
-- Adds two per-row flags:
--   SHOW_IN_ASSURANCE_HUB  Y/N  — include this row on Assurance Hub (/Dashboards2)
--   SHOW_IN_BUSINESS_HUB   Y/N  — include this row on Business Hub (/BusinessHub)
--
-- Per-row (not per-category) so an individual menu item can be toggled in
-- or out of a hub without affecting the rest of its category — a tab only
-- appears on a hub if at least one of its rows has that hub's flag = 'Y'.
--
-- Run as the MYDIARYDB user (table owner). Additive, idempotent — checks
-- USER_TAB_COLUMNS before adding, safe to re-run.
--------------------------------------------------------------------------

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM user_tab_columns
   WHERE table_name = 'APP_USERS_ROLE_ACCESS_MENU_MASTER' AND column_name = 'SHOW_IN_ASSURANCE_HUB';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE APP_USERS_ROLE_ACCESS_MENU_MASTER ADD (SHOW_IN_ASSURANCE_HUB VARCHAR2(1) DEFAULT ''Y'' NOT NULL)';
    EXECUTE IMMEDIATE
      'ALTER TABLE APP_USERS_ROLE_ACCESS_MENU_MASTER ADD CONSTRAINT CHK_SHOW_IN_ASSURANCE_HUB CHECK (SHOW_IN_ASSURANCE_HUB IN (''Y'',''N''))';
  END IF;

  SELECT COUNT(*) INTO v_count FROM user_tab_columns
   WHERE table_name = 'APP_USERS_ROLE_ACCESS_MENU_MASTER' AND column_name = 'SHOW_IN_BUSINESS_HUB';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE APP_USERS_ROLE_ACCESS_MENU_MASTER ADD (SHOW_IN_BUSINESS_HUB VARCHAR2(1) DEFAULT ''N'' NOT NULL)';
    EXECUTE IMMEDIATE
      'ALTER TABLE APP_USERS_ROLE_ACCESS_MENU_MASTER ADD CONSTRAINT CHK_SHOW_IN_BUSINESS_HUB CHECK (SHOW_IN_BUSINESS_HUB IN (''Y'',''N''))';
  END IF;
END;
/

--------------------------------------------------------------------------
-- Backfill: reproduces the exact category → hub mapping that was
-- previously hardcoded, so behaviour doesn't change on cutover. Safe to
-- re-run (idempotent — always re-derives from MENU_CATEGORY).
--------------------------------------------------------------------------

UPDATE APP_USERS_ROLE_ACCESS_MENU_MASTER
SET    SHOW_IN_ASSURANCE_HUB = CASE
         WHEN MENU_CATEGORY IN ('Alerts','Analytics','Assurance Corner','Branch Info','Complaints',
                                 'Compliance','Dashboards','Digital','Forms','NPCI','Operations',
                                 'Recon','SAMV','Utilities') THEN 'Y'
         ELSE 'N'
       END,
       SHOW_IN_BUSINESS_HUB = CASE
         WHEN MENU_CATEGORY IN ('Analytics','Branch Info','Dashboards','Digital','Forms','Insurance',
                                 'LAS Masters','LCV','Leads','SUD Corner','Utilities') THEN 'Y'
         ELSE 'N'
       END;

COMMIT;
