-- ============================================================================
-- Request Portal — Super Admin Seeding v3.0
-- Schema   : RP_OWNER
-- Run after: 01_schema.sql + 02_seed.sql
-- Cap      : Application enforces max 2 Super Admins (RbacConstants.MaxSuperAdmins)
--
-- RP_RBAC_SUPER_ADMIN now uses EMP_CODE VARCHAR2(20) directly —
-- no dependency on RP_USER table.
-- ============================================================================

SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------------
-- Section A — Primary Super Admin  (EMP_CODE = 860921)
-- ---------------------------------------------------------------------------
DECLARE
BEGIN
  MERGE INTO RP_RBAC_SUPER_ADMIN t
  USING (SELECT '860921' AS EMP_CODE FROM DUAL) s ON (t.EMP_CODE = s.EMP_CODE)
  WHEN NOT MATCHED THEN
    INSERT (ID, EMP_CODE, ASSIGNED_AT_UTC, ASSIGNED_BY)
    VALUES (RP_SEQ_GLOBAL.NEXTVAL, '860921', SYSTIMESTAMP, 'BOOT_SEED');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SuperAdmin seeded: EMP_CODE=860921');
EXCEPTION
  WHEN OTHERS THEN ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM); RAISE;
END;
/

-- ---------------------------------------------------------------------------
-- Section B — Second Super Admin (uncomment and fill in EMP_CODE before running)
-- ---------------------------------------------------------------------------
--
-- DECLARE
-- BEGIN
--   MERGE INTO RP_RBAC_SUPER_ADMIN t
--   USING (SELECT 'REPLACE_EMP_CODE' AS EMP_CODE FROM DUAL) s ON (t.EMP_CODE = s.EMP_CODE)
--   WHEN NOT MATCHED THEN
--     INSERT (ID, EMP_CODE, ASSIGNED_AT_UTC, ASSIGNED_BY)
--     VALUES (RP_SEQ_GLOBAL.NEXTVAL, 'REPLACE_EMP_CODE', SYSTIMESTAMP, 'BOOT_SEED');
--   COMMIT;
--   DBMS_OUTPUT.PUT_LINE('SuperAdmin seeded: second super admin');
-- EXCEPTION
--   WHEN OTHERS THEN ROLLBACK;
--     DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM); RAISE;
-- END;
-- /
