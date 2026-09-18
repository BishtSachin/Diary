-- ============================================================
-- My Diary V3 — SQL Server Schema
-- Session management (from Project B)
-- ============================================================

IF OBJECT_ID('dbo.session_dtls', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.session_dtls (
        ID          BIGINT          IDENTITY(1,1) PRIMARY KEY,
        USERNAME    NVARCHAR(100)   NOT NULL,
        IP_ADDRESS  NVARCHAR(50)    NOT NULL,
        LOGIN_TIME  DATETIME2       NOT NULL DEFAULT GETDATE(),

        CONSTRAINT UQ_session_username UNIQUE (USERNAME)
    );

    CREATE INDEX IX_session_dtls_login_time ON dbo.session_dtls (LOGIN_TIME);

    PRINT 'Table session_dtls created.';
END
ELSE
    PRINT 'Table session_dtls already exists.';
GO
