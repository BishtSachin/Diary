-- ============================================================================
-- RP_15_vertical_seed.sql
-- Seeds RP_M_VERTICAL with the bank verticals, using the supplied SOL ID as the
-- primary-key ID (NOT auto-generated). Keeps UCCRMC_VERT; every other existing
-- vertical is removed — hard-deleted when unreferenced, otherwise deactivated
-- (IS_ACTIVE=0) so FKs (departments / unit-vertical / requests) are not violated.
-- Idempotent. Run as RP_OWNER.
-- ============================================================================
SET SERVEROUTPUT ON
SET DEFINE OFF   -- names contain '&' (do not treat as substitution vars)

DECLARE
    TYPE num_tab IS TABLE OF NUMBER;
    TYPE str_tab IS TABLE OF VARCHAR2(200);
    ids num_tab := num_tab(
        80190,80500,80150,80140,80410,61370,80440,80370,80110,80680,
        7821,80350,80250,80780,80770,80130,80480,80490,80711,80070,
        80560,80290,80010,30009,80220,20009,80210,80230,80300,80550,
        80470,80170,80760,80260,80700,80240,80200,80180,80510,80050,
        80660,50450,10009,80390);
    nms str_tab := str_tab(
        'Agri Business','Analytics Centre of Excellence','Audit and Inspection Dept','Board Secretariat','CISO',
        'CPPC Delhi','CR and MIS','Compliance','Corporate Communication Dept','Corporate Relationship & Transaction Banking',
        'Credit Card Merchant Acq and POS','Credit Compliance and Monitoring (CCM)','DFB','DIGITAL BUSINESS VERTICAL','Data Protection Office',
        'Department of Information Technology','Deposit Mobilization Department','Digitization','Ecosystem Banking','Finance And Accounts',
        'Gold Loan Vertical','Govt Business and Relationship Dept','Human Resources','International Banking','LCV',
        'MD and ED Secretariat','MSME','Mid Corporate','NPC Lucknow','NRI Back Office - CO Annex Mangalore',
        'National Processing Centre','Operations vertical','Procurement','RMD','Reconciliation',
        'Retail Assets','RuSu Banking & Financial Inclusion','SAMV','Strategy','Support Services Dept',
        'TMFMD Vertical','Treasury','Vigilance','Wealth Management');
    v_del NUMBER := 0; v_deact NUMBER := 0; is_seed BOOLEAN;
BEGIN
    -- 1) Upsert the supplied verticals (ID = SOL ID)
    FOR i IN 1 .. ids.COUNT LOOP
        MERGE INTO RP_M_VERTICAL t
        USING (SELECT ids(i) AS ID FROM DUAL) s ON (t.ID = s.ID)
        WHEN MATCHED THEN UPDATE SET t.CODE = TO_CHAR(ids(i)), t.NAME = nms(i), t.IS_ACTIVE = 1
        WHEN NOT MATCHED THEN
            INSERT (ID, CODE, NAME, IS_ACTIVE) VALUES (ids(i), TO_CHAR(ids(i)), nms(i), 1);
    END LOOP;

    -- 2) Remove everything else except UCCRMC_VERT
    FOR v IN (SELECT ID, CODE FROM RP_M_VERTICAL WHERE CODE <> 'UCCRMC_VERT') LOOP
        is_seed := FALSE;
        FOR j IN 1 .. ids.COUNT LOOP
            IF ids(j) = v.ID THEN is_seed := TRUE; EXIT; END IF;
        END LOOP;
        IF NOT is_seed THEN
            BEGIN
                DELETE FROM RP_M_VERTICAL WHERE ID = v.ID; v_del := v_del + 1;
            EXCEPTION WHEN OTHERS THEN
                UPDATE RP_M_VERTICAL SET IS_ACTIVE = 0 WHERE ID = v.ID; v_deact := v_deact + 1;
                DBMS_OUTPUT.PUT_LINE('Deactivated (referenced): '||v.CODE);
            END;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Verticals seeded: '||ids.COUNT||' | removed: '||v_del||' | deactivated: '||v_deact);
END;
/

SELECT 'active_verticals='||COUNT(*) FROM RP_M_VERTICAL WHERE IS_ACTIVE = 1;
SELECT ID, CODE, NAME FROM RP_M_VERTICAL WHERE IS_ACTIVE = 1 ORDER BY NAME;
