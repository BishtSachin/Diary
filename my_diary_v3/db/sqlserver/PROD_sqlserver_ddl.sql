-- ============================================================
-- GapPerformanceDB (SQL Server) - table DDL for production
-- Generated from live gap-sqlserver. Recommend BACPAC (sqlpackage) for full data + indexes.
-- ============================================================

CREATE TABLE [dbo].[AppSettings] (
        [SettingKey] nvarchar(100) NOT NULL,
    [SettingValue] nvarchar(1000) NULL,
    [Description] nvarchar(500) NULL,
    [UpdatedAt] datetime2 NULL,
);
CREATE TABLE [dbo].[Branches] (
        [BranchId] int IDENTITY(1,1) NOT NULL,
    [BranchCode] nvarchar(20) NOT NULL,
    [BranchName] nvarchar(200) NOT NULL,
    [ZoneId] int NOT NULL,
    [RegionName] nvarchar(100) NULL,
    [ZMBMName] nvarchar(100) NULL,
    [ZMBMCode] nvarchar(20) NULL,
    [Scale] nvarchar(100) NULL,
    [BranchOpenDate] date NULL,
    [WorkingSince] date NULL,
    [GuardianExec] nvarchar(100) NULL,
    [BranchOpenTime] time NULL,
    [BranchCloseTime] time NULL,
    [IsActive] bit NOT NULL,
    [CreatedAt] datetime2 NULL,
    [StaffMixSummary] nvarchar(200) NULL,
    [AbbreviatedStaffTotal] int NULL,
);
CREATE TABLE [dbo].[BranchPerformanceData] (
        [PerfDataId] bigint IDENTITY(1,1) NOT NULL,
    [BranchId] int