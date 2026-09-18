-- ============================================================================
-- RP_11_superadmins.sql
-- Production Super Admins for the Request Portal.
--   * Sets EMP_CODE 921592 and 713907 as the two Super Admins.
--   * Removes the demo/bootstrap super admin 860921.
-- The application caps Super Admins at 2 (RbacConstants.MaxSuperAdmins), so this
-- leaves exactly the two production administrators.
-- RP_RBAC_SUPER_ADMIN keys on EMP_CODE (VARCHAR2). Idempotent. Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON

BEGIN
    -- Remove the demo/bootstrap super admin (safe if absent).
    DELETE FROM RP_RBAC_SUPER_ADMIN WHERE EMP_CODE = '860921';

    -- Seed the two production super admins.
    MERGE INTO RP_RBAC_SUPER_ADMIN t
    USING (SELECT '921592' AS EMP_CODE FROM DUAL) s ON (t.EMP_CODE = s.EMP_CODE)
    WHEN NOT MATCHED THEN
        INSERT (ID, EMP_CODE, ASSIGNED_AT_UTC, ASSIGNED_BY)
        VALUES (RP_SEQ_GLOBAL.NEXTVAL, '921592', SYSTIMESTAMP, 'PROD_SEED');

    MERGE INTO RP_RBAC_SUPER_ADMIN t
    USING (SELECT '713907' AS EMP_CODE FROM DUAL) s ON (t.EMP_CODE = s.EMP_CODE)
    WHEN NOT MATCHED THEN
        INSERT (ID, EMP_CODE, ASSIGNED_AT_UTC, ASSIGNED_BY)
        VALUES (RP_SEQ_GLOBAL.NEXTVAL, '713907', SYSTIMESTAMP, 'PROD_SEED');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Super Admins set to 921592 and 713907 (860921 removed).');
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM); RAISE;
END;
/

SELECT EMP_CODE FROM RP_RBAC_SUPER_ADMIN ORDER BY EMP_CODE;
