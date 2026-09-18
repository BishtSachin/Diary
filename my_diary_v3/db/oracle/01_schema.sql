-- ============================================================
-- My Diary V3 — Oracle Schema
-- Users, RBAC, Notifications, Delegations
-- Target: rp-oracle / XEPDB1 / RP_OWNER (coexists with RP_* tables)
-- ============================================================

-- Allow blank lines inside SQL statements (SQL*Plus terminates on blank by default)
SET SQLBLANKLINES ON

-- Global sequence for surrogate keys
CREATE SEQUENCE MD_SEQ_GLOBAL
    START WITH 1000
    INCREMENT BY 1
    NOCACHE NOCYCLE;

-- ── Users ─────────────────────────────────────────────────────────────────

CREATE TABLE MD_USER (
    ID          NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    EMPL_ID     VARCHAR2(50)    NOT NULL,
    NAME        VARCHAR2(200)   NOT NULL,
    EMAIL       VARCHAR2(200),
    MOBILE      VARCHAR2(20),
    IS_ACTIVE   NUMBER(1)       DEFAULT 1 NOT NULL,
    CREATED_AT  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    UPDATED_AT  TIMESTAMP,

    CONSTRAINT UQ_md_user_empl_id UNIQUE (EMPL_ID)
);

-- ── Roles ─────────────────────────────────────────────────────────────────

CREATE TABLE MD_ROLE (
    ID      NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    CODE    NUMBER(5)       NOT NULL,   -- matches RoleCode enum integer value
    NAME    VARCHAR2(100)   NOT NULL,

    CONSTRAINT UQ_md_role_code UNIQUE (CODE)
);

-- ── User → Role assignments ───────────────────────────────────────────────

CREATE TABLE MD_USER_ROLE (
    ID          NUMBER(19)  DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    USER_ID     NUMBER(19)  NOT NULL REFERENCES MD_USER(ID) ON DELETE CASCADE,
    ROLE_ID     NUMBER(19)  NOT NULL REFERENCES MD_ROLE(ID) ON DELETE CASCADE,
    IS_ACTIVE   NUMBER(1)   DEFAULT 1 NOT NULL,
    VALID_FROM  DATE        DEFAULT SYSDATE NOT NULL,
    VALID_TO    DATE
);

-- ── Delegations ──────────────────────────────────────────────────────────

CREATE TABLE MD_DELEGATION (
    ID              NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    FROM_EMPL_ID    VARCHAR2(50)    NOT NULL,
    TO_EMPL_ID      VARCHAR2(50)    NOT NULL,
    ROLE_CODE       VARCHAR2(50)    NOT NULL,
    VERTICAL_CODE   VARCHAR2(50),
    VALID_FROM      DATE            NOT NULL,
    VALID_TO        DATE            NOT NULL,
    REASON          VARCHAR2(500),
    MODIFIED_BY_EMP VARCHAR2(50),
    MODIFIED_AT     TIMESTAMP,
    CREATED_AT      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL
);

-- ── RBAC Modules ─────────────────────────────────────────────────────────

CREATE TABLE MD_RBAC_MODULE (
    ID              NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    CODE            VARCHAR2(100)   NOT NULL,
    DISPLAY_NAME    VARCHAR2(200)   NOT NULL,
    PARENT_ID       NUMBER(19)      REFERENCES MD_RBAC_MODULE(ID),
    KIND            NUMBER(2)       NOT NULL,   -- ModuleKind enum
    SORT_ORDER      NUMBER(5)       DEFAULT 0 NOT NULL,
    IS_ACTIVE       NUMBER(1)       DEFAULT 1 NOT NULL,

    CONSTRAINT UQ_md_rbac_module_code UNIQUE (CODE)
);

-- ── RBAC Menus ───────────────────────────────────────────────────────────

CREATE TABLE MD_RBAC_MENU (
    ID          NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    MODULE_ID   NUMBER(19)      NOT NULL REFERENCES MD_RBAC_MODULE(ID) ON DELETE CASCADE,
    LABEL       VARCHAR2(200)   NOT NULL,
    HREF        VARCHAR2(500),
    ICON        VARCHAR2(100),
    SORT_ORDER  NUMBER(5)       DEFAULT 0 NOT NULL,
    IS_ACTIVE   NUMBER(1)       DEFAULT 1 NOT NULL
);

-- ── Role → Module permissions ─────────────────────────────────────────────

CREATE TABLE MD_ROLE_MODULE_PERM (
    ID              NUMBER(19)  DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    ROLE_ID         NUMBER(19)  NOT NULL REFERENCES MD_ROLE(ID) ON DELETE CASCADE,
    MODULE_ID       NUMBER(19)  NOT NULL REFERENCES MD_RBAC_MODULE(ID) ON DELETE CASCADE,
    CAN_VIEW        NUMBER(1)   DEFAULT 0 NOT NULL,
    CAN_ADD         NUMBER(1)   DEFAULT 0 NOT NULL,
    CAN_MODIFY      NUMBER(1)   DEFAULT 0 NOT NULL,
    CAN_DELETE      NUMBER(1)   DEFAULT 0 NOT NULL,
    CAN_AUTHORIZE   NUMBER(1)   DEFAULT 0 NOT NULL,

    CONSTRAINT UQ_role_module UNIQUE (ROLE_ID, MODULE_ID)
);

-- ── User → Module permission overrides ───────────────────────────────────

CREATE TABLE MD_USER_MODULE_PERM (
    ID              NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    EMPL_CODE       VARCHAR2(50)    NOT NULL,
    MODULE_ID       NUMBER(19)      NOT NULL REFERENCES MD_RBAC_MODULE(ID) ON DELETE CASCADE,
    CAN_VIEW        NUMBER(1)       DEFAULT 0 NOT NULL,
    CAN_ADD         NUMBER(1)       DEFAULT 0 NOT NULL,
    CAN_MODIFY      NUMBER(1)       DEFAULT 0 NOT NULL,
    CAN_DELETE      NUMBER(1)       DEFAULT 0 NOT NULL,
    CAN_AUTHORIZE   NUMBER(1)       DEFAULT 0 NOT NULL,
    IS_DENY         NUMBER(1)       DEFAULT 0 NOT NULL,  -- 1 = explicit revoke

    CONSTRAINT UQ_user_module UNIQUE (EMPL_CODE, MODULE_ID)
);

-- ── Notification outbox (email/SMS) ──────────────────────────────────────

CREATE TABLE MD_NOTIF_OUTBOX (
    ID              NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    EVENT_CODE      VARCHAR2(100)   NOT NULL,
    CHANNEL         NUMBER(2)       NOT NULL,   -- NotifChannel enum
    TO_ADDRESS      VARCHAR2(200)   NOT NULL,
    TO_EMPL_CODE    VARCHAR2(50)    NOT NULL,
    PAYLOAD_JSON    CLOB,
    STATUS          NUMBER(2)       DEFAULT 0 NOT NULL,  -- NotifOutboxStatus
    ATTEMPTS        NUMBER(3)       DEFAULT 0 NOT NULL,
    LAST_ERROR      VARCHAR2(500),
    CREATED_AT      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    SENT_AT         TIMESTAMP
);

CREATE INDEX IX_md_notif_outbox_status ON MD_NOTIF_OUTBOX (STATUS, ATTEMPTS);

-- ── Notification templates ────────────────────────────────────────────────

CREATE TABLE MD_NOTIF_TEMPLATE (
    ID          NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    EVENT_CODE  VARCHAR2(100)   NOT NULL,
    CHANNEL     NUMBER(2)       NOT NULL,
    SUBJECT     VARCHAR2(500),
    BODY        CLOB            NOT NULL,
    IS_ACTIVE   NUMBER(1)       DEFAULT 1 NOT NULL,

    CONSTRAINT UQ_notif_template UNIQUE (EVENT_CODE, CHANNEL)
);

-- ── In-app notifications (bell) ───────────────────────────────────────────

CREATE TABLE MD_INAPP_NOTIF (
    ID          NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    EMPL_CODE   VARCHAR2(50)    NOT NULL,
    TITLE       VARCHAR2(200)   NOT NULL,
    BODY        VARCHAR2(2000),
    HREF        VARCHAR2(500),
    IS_READ     NUMBER(1)       DEFAULT 0 NOT NULL,
    CREATED_AT  TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE INDEX IX_md_inapp_notif_emp ON MD_INAPP_NOTIF (EMPL_CODE, IS_READ, CREATED_AT);

-- ── Oracle Text full-text index for search (used by MainLayout search) ────

CREATE TABLE MYDIARY_LANDING_SITEMAP (
    ID          NUMBER(19)      DEFAULT MD_SEQ_GLOBAL.NEXTVAL PRIMARY KEY,
    NAME        VARCHAR2(200)   NOT NULL,
    URL         VARCHAR2(500)   NOT NULL,
    CATEGORY    VARCHAR2(100),
    SUB_CATEGORY VARCHAR2(100),
    DESCRIPTION VARCHAR2(2000),
    KEYWORDS    VARCHAR2(2000),
    IS_ACTIVE   NUMBER(1)       DEFAULT 1 NOT NULL
);

-- Note: CREATE INDEX ix_sitemap_keywords ON MYDIARY_LANDING_SITEMAP(KEYWORDS)
-- INDEXTYPE IS CTXSYS.CONTEXT;
-- Run separately after granting CTXSYS privileges.

COMMIT;
