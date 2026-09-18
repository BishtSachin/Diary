-- =====================================================================
-- RP_OWNER_CLEAN_ALL.sql
-- Drops EVERY object owned by the connected schema (RP_OWNER) so the
-- destination DB can be re-seeded from a clean slate via
-- RP_OWNER_FULL_DDL_EXPORT.sql + RP_OWNER_CURRENT_SEED_DATA.sql.
--
-- DESTRUCTIVE: this permanently deletes all tables, data, sequences,
-- views, procedures, functions, packages, triggers, and synonyms in
-- the connected schema. Run only against a schema you intend to wipe.
--
-- Usage:
--   sqlplus RP_OWNER/RPOwner123@127.0.0.1:1521/XEPDB1 @RP_OWNER_CLEAN_ALL.sql
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET ECHO OFF
SET VERIFY OFF

PROMPT Dropping all TRIGGERS...
BEGIN
  FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TRIGGER "' || r.trigger_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip trigger ' || r.trigger_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Dropping all VIEWS...
BEGIN
  FOR r IN (SELECT view_name FROM user_views) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP VIEW "' || r.view_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip view ' || r.view_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Dropping all PACKAGE BODIES and PACKAGES...
BEGIN
  FOR r IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE BODY') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP PACKAGE BODY "' || r.object_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip package body ' || r.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
  FOR r IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP PACKAGE "' || r.object_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip package ' || r.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Dropping all PROCEDURES and FUNCTIONS...
BEGIN
  FOR r IN (SELECT object_name FROM user_procedures WHERE object_type = 'PROCEDURE') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP PROCEDURE "' || r.object_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip procedure ' || r.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
  FOR r IN (SELECT object_name FROM user_procedures WHERE object_type = 'FUNCTION') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP FUNCTION "' || r.object_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip function ' || r.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Dropping all SYNONYMS...
BEGIN
  FOR r IN (SELECT synonym_name FROM user_synonyms) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP SYNONYM "' || r.synonym_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip synonym ' || r.synonym_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Dropping all TABLES (CASCADE CONSTRAINTS, PURGE)...
-- CASCADE CONSTRAINTS removes dependent FKs from other tables automatically,
-- so table drop order doesn't matter. PURGE skips the recycle bin.
BEGIN
  FOR r IN (SELECT table_name FROM user_tables) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE "' || r.table_name || '" CASCADE CONSTRAINTS PURGE';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip table ' || r.table_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Dropping all SEQUENCES...
BEGIN
  FOR r IN (SELECT sequence_name FROM user_sequences) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP SEQUENCE "' || r.sequence_name || '"';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  skip sequence ' || r.sequence_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT Verifying schema is empty...
SELECT object_type, COUNT(*) AS remaining
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

PROMPT Done. Schema should now be empty (0 rows above = fully clean).
EXIT
