--------------------------------------------------------------------------
-- RP_45_page_info_knowledge_hub_seed.sql
--
-- Adds RP_PAGE_INFO rows for the 3 new Knowledge Hub sample pages
-- (Step by Step Process Flow, E-manual Content, FAQs/SOPs), created when
-- "e-Circulars" was regrouped into "Knowledge Hub" alongside Circulars
-- and Policies. Additive-only, idempotent (MERGE ... WHEN NOT MATCHED),
-- same pattern as RP_23/RP_41/RP_44.
--------------------------------------------------------------------------

MERGE INTO RP_PAGE_INFO t
USING (SELECT 'knowledge-hub-process-flow' AS PAGE_KEY FROM dual) s
ON (t.PAGE_KEY = s.PAGE_KEY)
WHEN NOT MATCHED THEN
INSERT (PAGE_KEY, PAGE_NAME, PAGE_TYPE, DESCRIPTION, OWNER_VERTICAL,
        MODULE_OWNER, IP_NUMBER, MAIL_ID, CREATED_DATE, VERSION, STATUS)
VALUES ('knowledge-hub-process-flow', 'Step by Step Process Flow', 'Enquiry',
        'Guided, numbered walkthroughs for common banking operations and internal processes',
        'Knowledge Hub', 'Operations Team', '-', 'knowledgehub.support@unionbankofindia.bank',
        SYSDATE, 'v1.0', 'ACTIVE');

MERGE INTO RP_PAGE_INFO t
USING (SELECT 'knowledge-hub-e-manual' AS PAGE_KEY FROM dual) s
ON (t.PAGE_KEY = s.PAGE_KEY)
WHEN NOT MATCHED THEN
INSERT (PAGE_KEY, PAGE_NAME, PAGE_TYPE, DESCRIPTION, OWNER_VERTICAL,
        MODULE_OWNER, IP_NUMBER, MAIL_ID, CREATED_DATE, VERSION, STATUS)
VALUES ('knowledge-hub-e-manual', 'E-manual Content', 'Enquiry',
        'Digital reference manuals and operating instructions, organised by department',
        'Knowledge Hub', 'Operations Team', '-', 'knowledgehub.support@unionbankofindia.bank',
        SYSDATE, 'v1.0', 'ACTIVE');

MERGE INTO RP_PAGE_INFO t
USING (SELECT 'knowledge-hub-faqs-sops' AS PAGE_KEY FROM dual) s
ON (t.PAGE_KEY = s.PAGE_KEY)
WHEN NOT MATCHED THEN
INSERT (PAGE_KEY, PAGE_NAME, PAGE_TYPE, DESCRIPTION, OWNER_VERTICAL,
        MODULE_OWNER, IP_NUMBER, MAIL_ID, CREATED_DATE, VERSION, STATUS)
VALUES ('knowledge-hub-faqs-sops', 'FAQs/SOPs', 'Enquiry',
        'Frequently asked questions and standard operating procedures for day-to-day operations',
        'Knowledge Hub', 'Operations Team', '-', 'knowledgehub.support@unionbankofindia.bank',
        SYSDATE, 'v1.0', 'ACTIVE');

COMMIT;
