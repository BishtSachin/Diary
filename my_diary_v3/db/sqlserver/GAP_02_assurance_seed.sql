-- ============================================================================
-- GAP_02_assurance_seed.sql   (SQL Server — GapPerformanceDB)
-- Seeds the FOCUS 360 parameter framework with ASSURANCE data so the Assurance
-- Snapshot renders through the same IGapService/tables as Focus 360.
--   * Assurance content -> BUSINESS_360_PARAMETER_MASTER, F360_CATEGORY_COLOR,
--                          BUSINESS_360_DATA_MyDiary
--   * Minimal scaffolding (1 branch) -> MD_BRANCH_MASTER, staffdetails,
--                          BUSINESS_360_DATA, empty View_TPPD_* views
-- Idempotent. Branch: BRANCH_ID 732 (DAVANGERE-MANDIPET).
-- ============================================================================
SET NOCOUNT ON;

-- ── Tables (create if missing) ──────────────────────────────────────────────
IF OBJECT_ID('dbo.F360_CATEGORY_COLOR') IS NULL
CREATE TABLE dbo.F360_CATEGORY_COLOR (
    CATEGORY NVARCHAR(80), SUB_CATEGORY NVARCHAR(80) NULL,
    COLOR_HEX NVARCHAR(10), SECTION_LABEL NVARCHAR(120), SORT_ORDER INT, IS_ACTIVE CHAR(1) NULL);
IF COL_LENGTH('dbo.F360_CATEGORY_COLOR','IS_ACTIVE') IS NULL
    ALTER TABLE dbo.F360_CATEGORY_COLOR ADD IS_ACTIVE CHAR(1) NULL;

IF OBJECT_ID('dbo.BUSINESS_360_PARAMETER_MASTER') IS NULL
CREATE TABLE dbo.BUSINESS_360_PARAMETER_MASTER (
    PARAMETER_ID INT PRIMARY KEY, PARAMETER_NAME NVARCHAR(150), MD_DISPLAY_NAME NVARCHAR(150) NULL,
    CATEGORY NVARCHAR(80), SUB_CATEGORY NVARCHAR(80) NULL, TYPE NVARCHAR(20) NULL,
    UI_TYPE NVARCHAR(20) NULL, DATE_TYPE NVARCHAR(20) NULL, F360_SORT_ORDER INT NULL, F360_IS_ACTIVE CHAR(1) NULL);

IF OBJECT_ID('dbo.BUSINESS_360_DATA_MyDiary') IS NULL
CREATE TABLE dbo.BUSINESS_360_DATA_MyDiary (
    BRANCH_ID INT, PARAMETER_ID INT, BASE_LAST_FY DECIMAL(18,2), BASE_CURRENT_FY DECIMAL(18,2),
    ACTUALS_AS_ON DECIMAL(18,2), TARGET DECIMAL(18,2), TARGET_QUARTER DECIMAL(18,2), AS_ON_DATE DATE);

IF OBJECT_ID('dbo.BUSINESS_360_DATA') IS NULL
CREATE TABLE dbo.BUSINESS_360_DATA (
    BRANCH_ID INT, REGION_ID INT NULL, ZONE_ID INT NULL, PARAMETER_ID INT NULL,
    ACTUALS_AS_ON DECIMAL(18,2) NULL, BASE_CURRENT_FY DECIMAL(18,2) NULL, AS_ON_DATE DATE NULL);

IF OBJECT_ID('dbo.MD_BRANCH_MASTER') IS NULL
CREATE TABLE dbo.MD_BRANCH_MASTER (
    sol_id NVARCHAR(20), sol_desc NVARCHAR(120), zone_name NVARCHAR(80), region_name NVARCHAR(80),
    branch_head_name NVARCHAR(120), branch_head_designation NVARCHAR(120), branch_head_posted_since_dt DATE,
    sol_opn_dt DATE, license_number NVARCHAR(40), aesol_region_cd NVARCHAR(20));

IF OBJECT_ID('dbo.staffdetails') IS NULL
CREATE TABLE dbo.staffdetails (brsolid NVARCHAR(20), emp_scale_code NVARCHAR(5), emp_name NVARCHAR(120) NULL);

-- ── Empty TPPD views (parameters 39-42 UNIONs; return no rows) ───────────────
IF OBJECT_ID('dbo.View_TPPD_Health_Insurance')   IS NOT NULL DROP VIEW dbo.View_TPPD_Health_Insurance;
IF OBJECT_ID('dbo.View_TPPD_Life_Insurance')     IS NOT NULL DROP VIEW dbo.View_TPPD_Life_Insurance;
IF OBJECT_ID('dbo.View_TPPD_MutualFund')         IS NOT NULL DROP VIEW dbo.View_TPPD_MutualFund;
IF OBJECT_ID('dbo.View_TPPD_NonLife_Insurance')  IS NOT NULL DROP VIEW dbo.View_TPPD_NonLife_Insurance;
GO
CREATE VIEW dbo.View_TPPD_Health_Insurance  AS SELECT CAST(NULL AS NVARCHAR(20)) AS Branch_Solid, CAST(0 AS DECIMAL(18,2)) AS Total_Health_Insurance_Amount  WHERE 1=0;
GO
CREATE VIEW dbo.View_TPPD_Life_Insurance    AS SELECT CAST(NULL AS NVARCHAR(20)) AS Branch_Solid, CAST(0 AS DECIMAL(18,2)) AS Total_Life_Insurance_Amount    WHERE 1=0;
GO
CREATE VIEW dbo.View_TPPD_MutualFund        AS SELECT CAST(NULL AS NVARCHAR(20)) AS Branch_Solid, CAST(0 AS DECIMAL(18,2)) AS Total_MutualFund_Amount        WHERE 1=0;
GO
CREATE VIEW dbo.View_TPPD_NonLife_Insurance AS SELECT CAST(NULL AS NVARCHAR(20)) AS Branch_Solid, CAST(0 AS DECIMAL(18,2)) AS Total_NonLife_Insurance_Amount WHERE 1=0;
GO

-- ── Clean prior assurance seed (idempotent) ─────────────────────────────────
DELETE FROM dbo.BUSINESS_360_DATA_MyDiary       WHERE PARAMETER_ID >= 1000;
DELETE FROM dbo.BUSINESS_360_PARAMETER_MASTER   WHERE PARAMETER_ID >= 1000;
DELETE FROM dbo.F360_CATEGORY_COLOR             WHERE CATEGORY IN ('KYC','ALERTS','DATA_CLEANSING','CREDIT_MON','SUSPENSE','DEFAULTING','CASH_LOCKER','AUDIT_COMP');
DELETE FROM dbo.BUSINESS_360_DATA               WHERE BRANCH_ID = 732;
DELETE FROM dbo.MD_BRANCH_MASTER                WHERE sol_id = '732';
DELETE FROM dbo.staffdetails                    WHERE brsolid = '732';

-- ── Branch scaffolding ──────────────────────────────────────────────────────
INSERT INTO dbo.MD_BRANCH_MASTER VALUES
 ('732','DAVANGERE-MANDIPET','564974-BENGALURU','592544-BALLARI','VERMA AMIT KUMAR',
  'SENIOR MANAGER (BRANCH HEAD)','2025-05-14','2010-01-01','LIC-00732','592544');
INSERT INTO dbo.BUSINESS_360_DATA (BRANCH_ID,REGION_ID,ZONE_ID,PARAMETER_ID,ACTUALS_AS_ON,BASE_CURRENT_FY,AS_ON_DATE)
 VALUES (732,592544,564974,1,12500000,11800000,'2026-05-25');
INSERT INTO dbo.staffdetails (brsolid,emp_scale_code,emp_name) VALUES
 ('732','5','Officer A'),('732','6','Officer B'),('732','7','Officer C'),('732','10','Clerk D'),('732','11','Sub Staff E');

-- ── Category colours (= assurance sections) ─────────────────────────────────
INSERT INTO dbo.F360_CATEGORY_COLOR (CATEGORY,SUB_CATEGORY,COLOR_HEX,SECTION_LABEL,SORT_ORDER,IS_ACTIVE) VALUES
 ('KYC','','#1565C0','KYC & Transaction Monitoring',10,'Y'),
 ('ALERTS','','#C62828','Alerts Pendency & Non-Compliant Areas',20,'Y'),
 ('DATA_CLEANSING','','#6A1B9A','Data Cleansing Pendency',30,'Y'),
 ('CREDIT_MON','','#2E7D32','Credit Monitoring',40,'Y'),
 ('SUSPENSE','','#E65100','Suspense & Sundry Entries',50,'Y'),
 ('DEFAULTING','','#00838F','Defaulting, DEAF, Lien & Complaints',60,'Y'),
 ('CASH_LOCKER','','#4527A0','Cash Holding, Locker & ATM',70,'Y'),
 ('AUDIT_COMP','','#37474F','Audit & Compliance',80,'Y');

-- ── Assurance parameters + data (COUNT type -> shown as-is) ─────────────────
DECLARE @asn DATE = '2026-05-25';
DECLARE @p TABLE (id INT, nm NVARCHAR(150), cat NVARCHAR(80), sub NVARCHAR(80), so INT,
                  prev DECIMAL(18,2), cur DECIMAL(18,2), ason DECIMAL(18,2));
INSERT INTO @p VALUES
 (1001,'ReKYC','KYC','KYC',1,122,122,130),
 (1002,'CKYC','KYC','KYC',2,122,122,110),
 (1003,'Legacy CKYC','KYC','KYC',3,122,122,90),
 (1004,'EDD Pendency','KYC','Transaction Monitoring',4,122,122,120),
 (1005,'Smule','KYC','Transaction Monitoring',5,122,122,80),
 (1006,'Vajra','KYC','Transaction Monitoring',6,122,122,60),
 (1007,'Negative List','KYC','Transaction Monitoring',7,122,122,40),
 (1010,'EWS Alerts','ALERTS','Alerts Pendency',1,122,110,95),
 (1011,'Highly Critical Alerts','ALERTS','Alerts Pendency',2,80,70,60),
 (1012,'OTMS','ALERTS','Alerts Pendency',3,50,45,40),
 (1013,'NRTMS','ALERTS','Alerts Pendency',4,30,25,20),
 (1014,'Interest not Capitalised','ALERTS','Major Non-Compliant Areas',5,15,12,10),
 (1015,'Loan Repaid but not Closed','ALERTS','Major Non-Compliant Areas',6,8,6,5),
 (1016,'A/Cs Pending Disbursement','ALERTS','Major Non-Compliant Areas',7,20,18,14),
 (1017,'Negative Amortisation','ALERTS','Major Non-Compliant Areas',8,3,2,1),
 (1020,'Annual Income','DATA_CLEANSING','',1,45,30,12),
 (1021,'Annual Turnover','DATA_CLEANSING','',2,120,80,25),
 (1022,'OVD','DATA_CLEANSING','',3,60,40,12),
 (1023,'PAN / Form60','DATA_CLEANSING','',4,90,60,20),
 (1024,'Constitution Code','DATA_CLEANSING','',5,30,20,8),
 (1025,'Occupation','DATA_CLEANSING','',6,50,35,15),
 (1026,'Date of Incorporation','DATA_CLEANSING','',7,25,15,6),
 (1027,'Customer Type','DATA_CLEANSING','',8,40,28,10),
 (1030,'Release Pendency < 30 days','CREDIT_MON','Release of Security Documents',1,20,15,10),
 (1031,'Release Pendency > 30 days','CREDIT_MON','Release of Security Documents',2,12,9,5),
 (1032,'CERSAI Satisfaction Pending','CREDIT_MON','Release of Security Documents',3,8,6,4),
 (1033,'Renewal - Retail','CREDIT_MON','Renewal Pendency',4,25,18,12),
 (1034,'Renewal - Agri','CREDIT_MON','Renewal Pendency',5,30,22,15),
 (1035,'Renewal - MSME','CREDIT_MON','Renewal Pendency',6,15,10,6),
 (1036,'Renewal - Others','CREDIT_MON','Renewal Pendency',7,10,7,4),
 (1037,'Quick Mortality A/cs','CREDIT_MON','Quick Mortality & Stock',8,6,4,3),
 (1038,'Stock Statement > 90 days','CREDIT_MON','Quick Mortality & Stock',9,18,12,7),
 (1040,'Suspense - No. of Entries','SUSPENSE','Suspense Entries',1,269947,555528,563779),
 (1041,'Suspense - Outstanding (Lacs)','SUSPENSE','Suspense Entries',2,4544,4030,4009),
 (1042,'Suspense > 90 days','SUSPENSE','Suspense Entries',3,0,67466,1575),
 (1043,'Sundry - No. of Entries','SUSPENSE','Sundry Entries',4,424226,442421,440331),
 (1044,'Sundry - Outstanding (Lacs)','SUSPENSE','Sundry Entries',5,2641,5871,5604),
 (1050,'Dormant','DEFAULTING','Defaulting Accounts',1,269947,555528,563779),
 (1051,'Inactive','DEFAULTING','Defaulting Accounts',2,4544,4030,4009),
 (1052,'No Nomination','DEFAULTING','Defaulting Accounts',3,4544,4030,4009),
 (1053,'DEAF Accounts','DEFAULTING','DEAF & Lien',4,10,15,20),
 (1054,'Lien Marked Accounts','DEFAULTING','DEAF & Lien',5,12,15,20),
 (1055,'Customer Complaints','DEFAULTING','Complaints',6,1021,1000,2000),
 (1056,'Complaints Beyond TAT','DEFAULTING','Complaints',7,120,90,60),
 (1060,'CRL (INR Lacs)','CASH_LOCKER','Cash Holding',1,1021,1000,2000),
 (1061,'Cash in Hand (INR Lacs)','CASH_LOCKER','Cash Holding',2,123,125,126),
 (1062,'Excess Cash','CASH_LOCKER','Cash Holding',3,100,231,132),
 (1063,'Total Lockers','CASH_LOCKER','Locker Status',4,183,183,183),
 (1064,'Vacant Lockers','CASH_LOCKER','Locker Status',5,50,49,48),
 (1065,'Occupied Lockers','CASH_LOCKER','Locker Status',6,12,12,12),
 (1066,'Death Claim Upto 10 Days','CASH_LOCKER','Death Claim & ATM',7,12,12,12),
 (1067,'Death Claim Above 15 Days','CASH_LOCKER','Death Claim & ATM',8,30,28,24),
 (1068,'Live ATMs','CASH_LOCKER','Death Claim & ATM',9,1,1,1),
 (1070,'COR Reports Released','AUDIT_COMP','COR Pendency',1,122,122,122),
 (1071,'COR Pending','AUDIT_COMP','COR Pendency',2,122,100,90),
 (1072,'FLASH Reports Released','AUDIT_COMP','FLASH Pendency',3,122,122,122),
 (1073,'FLASH Pending','AUDIT_COMP','FLASH Pendency',4,122,110,100),
 (1074,'EDPMS Outstanding upto Rs 10 L','AUDIT_COMP','EDPMS / IDPMS',5,122,115,110),
 (1075,'IDPMS Outstanding above Rs 10 L','AUDIT_COMP','EDPMS / IDPMS',6,122,118,112);

INSERT INTO dbo.BUSINESS_360_PARAMETER_MASTER
 (PARAMETER_ID,PARAMETER_NAME,MD_DISPLAY_NAME,CATEGORY,SUB_CATEGORY,TYPE,UI_TYPE,DATE_TYPE,F360_SORT_ORDER,F360_IS_ACTIVE)
 SELECT id,nm,nm,cat,sub,'COUNT','CARD','AS_ON_DATE',so,'Y' FROM @p;

INSERT INTO dbo.BUSINESS_360_DATA_MyDiary
 (BRANCH_ID,PARAMETER_ID,BASE_LAST_FY,BASE_CURRENT_FY,ACTUALS_AS_ON,TARGET,TARGET_QUARTER,AS_ON_DATE)
 SELECT 732,id,prev,cur,ason,0,0,@asn FROM @p;

-- ── Verify ──────────────────────────────────────────────────────────────────
SELECT 'params=' + CAST(COUNT(*) AS VARCHAR) FROM dbo.BUSINESS_360_PARAMETER_MASTER WHERE PARAMETER_ID >= 1000;
SELECT 'data='   + CAST(COUNT(*) AS VARCHAR) FROM dbo.BUSINESS_360_DATA_MyDiary WHERE BRANCH_ID = 732;
SELECT 'colors=' + CAST(COUNT(*) AS VARCHAR) FROM dbo.F360_CATEGORY_COLOR;
GO
