-- ============================================================================
-- RP_12_sample_users_routing_requests.sql
--   1) Give 713907 / 921592 email + mobile so they receive notifications.
--   2) Seed a few sample users (active, with email/mobile).
--   3) Make 713907 the L1 handler: routing rules per manual request type +
--      a vertical-level (VERT_L1) assignment.
--   4) Seed sample requests assigned to 713907 at L1 (so Handler Inbox shows them).
-- Idempotent. Run as RP_OWNER (after RP_11).
-- ============================================================================
SET SERVEROUTPUT ON

-- ── 1 + 2. Users (upsert by EMP_CODE) ───────────────────────────────────────
DECLARE
    TYPE u_rec IS RECORD (emp VARCHAR2(20), nm VARCHAR2(100), em VARCHAR2(120), mo VARCHAR2(20));
    TYPE u_tab IS TABLE OF u_rec;
    us u_tab := u_tab(
        u_rec('713907','Handler L1 (713907)','handler.713907@bank.local','9000000001'),
        u_rec('921592','Super Admin (921592)','admin.921592@bank.local','9000000002'),
        u_rec('SAMPLE_A','Asha Menon','asha.menon@bank.local','9000000101'),
        u_rec('SAMPLE_B','Bhaskar Rao','bhaskar.rao@bank.local','9000000102'),
        u_rec('SAMPLE_C','Chitra Nair','chitra.nair@bank.local','9000000103'),
        u_rec('SAMPLE_D','Devan Pillai','devan.pillai@bank.local','9000000104')
    );
BEGIN
    FOR i IN 1 .. us.COUNT LOOP
        MERGE INTO RP_USER t
        USING (SELECT us(i).emp AS EMP_CODE FROM DUAL) s ON (t.EMP_CODE = s.EMP_CODE)
        WHEN MATCHED THEN UPDATE SET t.EMAIL = us(i).em, t.MOBILE = us(i).mo,
                                     t.NAME = NVL(t.NAME, us(i).nm), t.IS_ACTIVE = 1
        WHEN NOT MATCHED THEN
            INSERT (ID, EMP_CODE, AD_SAM, NAME, EMAIL, MOBILE, IS_ACTIVE)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, us(i).emp, us(i).emp, us(i).nm, us(i).em, us(i).mo, 1);
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Users upserted: '||us.COUNT);
END;
/

-- ── 3a. Routing rules — 713907 as L1 for each manual request type ────────────
DECLARE
    v_rule NUMBER;
    v_cnt  NUMBER;
BEGIN
    FOR rt IN (SELECT ID FROM RP_M_REQUEST_TYPE WHERE ENTRY_MODE <> 'API') LOOP
        -- Rule (idempotent: skip if a 713907 assignee already exists for this type)
        SELECT COUNT(*) INTO v_cnt FROM RP_M_ROUTING_RULE r
            JOIN RP_M_ROUTING_ASSIGNEE a ON a.RULE_ID = r.ID
            WHERE r.REQUEST_TYPE_ID = rt.ID AND a.EMP_CODE = '713907';
        IF v_cnt = 0 THEN
            v_rule := RP_SEQ_GLOBAL.NEXTVAL;
            INSERT INTO RP_M_ROUTING_RULE (ID, REQUEST_TYPE_ID, UNIT_TYPE_ID, VERTICAL_ID,
                                           DEPARTMENT_ID, ACTIVITY_ID, PRIORITY, IS_ACTIVE, CREATED_BY, CREATED_AT)
            VALUES (v_rule, rt.ID, NULL, NULL, NULL, NULL, 100, 1, 'PROD_SEED', SYSTIMESTAMP);
            INSERT INTO RP_M_ROUTING_ASSIGNEE (ID, RULE_ID, EMP_CODE, IS_PRIMARY)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, v_rule, '713907', 1);
        END IF;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Routing rules ensured for 713907 (L1).');
END;
/

-- ── 3b. Vertical-level assignment: 713907 as VERT_L1 for each vertical ───────
DECLARE
BEGIN
    FOR v IN (SELECT ID FROM RP_M_VERTICAL WHERE CODE <> 'UCCRMC_VERT') LOOP
        MERGE INTO RP_RBAC_VERTICAL_LEVEL t
        USING (SELECT v.ID AS VID, '713907' AS EMP, 'VERT_L1' AS LVL FROM DUAL) s
          ON (t.VERTICAL_ID = s.VID AND t.EMP_CODE = s.EMP AND t.LEVEL_CODE = s.LVL)
        WHEN NOT MATCHED THEN
            INSERT (ID, VERTICAL_ID, EMP_CODE, LEVEL_CODE, IS_ACTIVE, ASSIGNED_BY_EMP, ASSIGNED_AT_UTC)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, s.VID, s.EMP, s.LVL, 1, 'PROD_SEED', SYSTIMESTAMP);
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('713907 assigned VERT_L1 on all verticals.');
END;
/

-- ── 4. Sample requests assigned to 713907 at L1 ─────────────────────────────
DECLARE
    v_rt   NUMBER;
    v_unit NUMBER;
    v_vert NUMBER;
    v_dept NUMBER;
    v_act  NUMBER;
    v_id   NUMBER;
    v_no   VARCHAR2(20);
    v_cnt  NUMBER;
    TYPE s_rec IS RECORD (subj VARCHAR2(200), req VARCHAR2(20));
    TYPE s_tab IS TABLE OF s_rec;
    ss s_tab := s_tab(
        s_rec('Sample: Account statement request','SAMPLE_A'),
        s_rec('Sample: Cheque book issue','SAMPLE_B'),
        s_rec('Sample: Address update','SAMPLE_C')
    );
BEGIN
    SELECT ID INTO v_rt FROM RP_M_REQUEST_TYPE WHERE CODE = 'REQUEST';
    SELECT MIN(ID) INTO v_unit FROM RP_M_UNIT WHERE CODE NOT LIKE 'UCCRMC%';
    SELECT MIN(ID) INTO v_vert FROM RP_M_VERTICAL WHERE CODE <> 'UCCRMC_VERT';
    SELECT MIN(ID) INTO v_dept FROM RP_M_DEPARTMENT WHERE VERTICAL_ID = v_vert;
    SELECT MIN(ID) INTO v_act  FROM RP_M_ACTIVITY   WHERE DEPARTMENT_ID = v_dept;

    IF v_act IS NULL OR v_unit IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Skip sample requests: no valid classification found.');
        RETURN;
    END IF;

    FOR i IN 1 .. ss.COUNT LOOP
        -- idempotent by subject
        SELECT COUNT(*) INTO v_cnt FROM RP_REQUEST WHERE SUBJECT = ss(i).subj;
        IF v_cnt = 0 THEN
            v_id := RP_SEQ_GLOBAL.NEXTVAL;
            v_no := 'SR' || TO_CHAR(SYSDATE,'YYYYMMDD') || LPAD(MOD(v_id,10000),4,'0');
            INSERT INTO RP_REQUEST (ID, REQ_NO, REQUEST_TYPE_ID, UNIT_ID, VERTICAL_ID, DEPARTMENT_ID,
                                    ACTIVITY_ID, RAISED_BY_EMP, SUBJECT, DESCRIPTION, CURRENT_LEVEL, STATUS,
                                    SLA_DUE_UTC)
            VALUES (v_id, v_no, v_rt, v_unit, v_vert, v_dept, v_act, ss(i).req, ss(i).subj,
                    'Seeded sample request for handler testing.', 1, 2,
                    SYS_EXTRACT_UTC(SYSTIMESTAMP) + 2);
            INSERT INTO RP_REQUEST_ASSIGNEE (ID, REQUEST_ID, LEVEL_NO, EMP_CODE, IS_ACTIVE)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, v_id, 1, '713907', 1);
            INSERT INTO RP_REQUEST_ACTION (ID, REQUEST_ID, LEVEL_NO, ACTOR_EMP_CODE, ACTION, REMARKS)
            VALUES (RP_SEQ_GLOBAL.NEXTVAL, v_id, 1, ss(i).req, 'Created', 'Sample seed');
        END IF;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sample requests seeded (assignee 713907). rt='||v_rt||' unit='||v_unit||' act='||v_act);
END;
/

-- ── Verify ───────────────────────────────────────────────────────────────────
SELECT 'active_users='||COUNT(*) FROM RP_USER WHERE IS_ACTIVE=1;
SELECT 'routing_713907='||COUNT(*) FROM RP_M_ROUTING_ASSIGNEE WHERE EMP_CODE='713907';
SELECT 'inbox_713907='||COUNT(*) FROM RP_REQUEST_ASSIGNEE WHERE EMP_CODE='713907' AND IS_ACTIVE=1;
