-- ============================================================
-- EC2 to RDS Feasibility — Discovery Queries
-- TECH-3537 — Investigation and Discovery Planning
-- ============================================================
-- Run each section against every SQL Server EC2 instance in scope.
-- Record outputs in TECH-3538 inventory.md and dependency-map.md.
-- Do not modify any data — all queries are read-only.
-- ============================================================


-- ============================================================
-- SECTION 1 — Instance Basics
-- ============================================================
-- Purpose: Confirm SQL Server version, edition, collation, and
-- clustering/HA configuration. Determines RDS engine version
-- options and flags any HA setup that needs to be replicated.

SELECT
    SERVERPROPERTY('ServerName')            AS server_name,
    SERVERPROPERTY('ProductVersion')        AS version,
    SERVERPROPERTY('ProductLevel')          AS patch_level,
    SERVERPROPERTY('ProductUpdateLevel')    AS cu_level,
    SERVERPROPERTY('Edition')               AS edition,
    SERVERPROPERTY('EngineEdition')         AS engine_edition,
    -- EngineEdition: 2 = Standard, 3 = Enterprise, 4 = Express, 8 = Managed Instance
    SERVERPROPERTY('Collation')             AS collation,
    SERVERPROPERTY('IsClustered')           AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled')         AS is_hadr_enabled,
    SERVERPROPERTY('IsFullTextInstalled')   AS fulltext_installed,
    SERVERPROPERTY('IsIntegratedSecurityOnly') AS windows_auth_only;


-- ============================================================
-- SECTION 2 — Database Inventory
-- ============================================================
-- Purpose: Full list of user databases with size, recovery model,
-- compatibility level, and collation. Flags any non-standard
-- collations that must be set at RDS provisioning time.

SELECT
    d.name                          AS database_name,
    d.state_desc                    AS state,
    d.recovery_model_desc           AS recovery_model,
    d.compatibility_level,
    d.collation_name,
    d.is_read_only,
    d.is_auto_close_on,
    d.is_auto_shrink_on,
    SUM(f.size) * 8 / 1024          AS total_size_mb
FROM sys.databases d
JOIN sys.master_files f ON d.database_id = f.database_id
WHERE d.name NOT IN ('master', 'tempdb', 'model', 'msdb')
GROUP BY
    d.name, d.state_desc, d.recovery_model_desc,
    d.compatibility_level, d.collation_name,
    d.is_read_only, d.is_auto_close_on, d.is_auto_shrink_on
ORDER BY total_size_mb DESC;


-- ============================================================
-- SECTION 3 — Storage Layout
-- ============================================================
-- Purpose: File locations, sizes, and growth settings per database.
-- RDS does not support local disk paths — all data files are
-- managed by RDS. Flags any non-standard drive layouts or
-- filegroups that need to be accounted for.

SELECT
    DB_NAME(database_id)    AS database_name,
    name                    AS logical_name,
    physical_name,
    type_desc               AS file_type,
    size * 8 / 1024         AS size_mb,
    CASE is_percent_growth
        WHEN 1 THEN CAST(growth AS VARCHAR) + '%'
        ELSE CAST(growth * 8 / 1024 AS VARCHAR) + ' MB'
    END                     AS auto_growth,
    max_size
FROM sys.master_files
ORDER BY database_id, type_desc;


-- ============================================================
-- SECTION 4 — Backup History
-- ============================================================
-- Purpose: Last backup date and type per database. Confirms
-- whether FULL, DIFF, and LOG backups are in place. RDS manages
-- automated backups to S3 — any custom backup jobs or local
-- disk destinations must be identified and replaced.

SELECT
    bs.database_name,
    bs.type                                     AS backup_type,
    -- D = Database (FULL), I = Differential, L = Log
    MAX(bs.backup_finish_date)                  AS last_backup,
    CAST(MAX(bs.backup_size) / 1048576 AS INT)  AS last_backup_size_mb,
    bmf.physical_device_name                    AS backup_destination
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.backup_finish_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY bs.database_name, bs.type, bmf.physical_device_name
ORDER BY bs.database_name, bs.type;


-- ============================================================
-- SECTION 5 — SQL Agent Jobs
-- ============================================================
-- Purpose: Full list of SQL Agent jobs with step types.
-- RDS supports T-SQL Agent job steps only. CmdExec, PowerShell,
-- SSIS, and ActiveX steps are not supported — each one is a
-- compatibility blocker that needs a workaround.

-- 5.1 Job list with enabled status
SELECT
    j.name              AS job_name,
    j.enabled,
    j.description,
    j.date_created,
    j.date_modified
FROM msdb.dbo.sysjobs j
ORDER BY j.enabled DESC, j.name;

-- 5.2 Job steps with step types — flags non-T-SQL steps
SELECT
    j.name              AS job_name,
    js.step_id,
    js.step_name,
    js.subsystem,
    -- TSQL = supported on RDS
    -- CmdExec, PowerShell, SSIS, ActiveScripting = NOT supported on RDS
    js.command,
    js.database_name
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
ORDER BY j.name, js.step_id;

-- 5.3 Last run outcome per job
SELECT
    j.name              AS job_name,
    j.enabled,
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
    END                 AS last_outcome
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobhistory h
    ON j.job_id = h.job_id
    AND h.instance_id = (
        SELECT MAX(instance_id)
        FROM msdb.dbo.sysjobhistory
        WHERE job_id = j.job_id AND step_id = 0
    )
ORDER BY j.enabled DESC, j.name;


-- ============================================================
-- SECTION 6 — Linked Servers
-- ============================================================
-- Purpose: Linked servers are not supported on RDS.
-- Any linked server in active use is a compatibility blocker.
-- Each one needs to be assessed: is it still active, what uses
-- it, and what is the workaround (ETL, application-level join,
-- or consolidation).

SELECT
    s.name              AS linked_server_name,
    s.provider,
    s.data_source,
    s.product,
    s.catalog,
    s.is_linked,
    s.is_remote_login_enabled,
    s.is_rpc_out_enabled
FROM sys.servers s
WHERE s.is_linked = 1
ORDER BY s.name;


-- ============================================================
-- SECTION 7 — CLR Assemblies
-- ============================================================
-- Purpose: CLR Safe assemblies are supported on RDS.
-- External and Unsafe assemblies are not supported.
-- Any Unsafe or External assembly is a compatibility blocker.

-- 7.1 CLR enabled flag
SELECT
    name,
    value_in_use        AS clr_enabled
FROM sys.configurations
WHERE name = 'clr enabled';

-- 7.2 User-defined assemblies per database
-- Run this in each user database
SELECT
    a.name              AS assembly_name,
    a.clr_name,
    a.permission_set_desc,
    -- SAFE = supported on RDS
    -- EXTERNAL_ACCESS / UNSAFE = NOT supported on RDS
    a.create_date,
    a.modify_date
FROM sys.assemblies a
WHERE a.is_user_defined = 1
ORDER BY a.permission_set_desc, a.name;


-- ============================================================
-- SECTION 8 — Cross-Database Dependencies
-- ============================================================
-- Purpose: Cross-database queries are not supported on RDS
-- (each RDS instance is isolated). Any stored procedure or view
-- that references another database by name is a compatibility
-- blocker — databases must either be consolidated onto one
-- instance or the dependency must be removed.

SELECT DISTINCT
    DB_NAME()                           AS current_database,
    OBJECT_SCHEMA_NAME(sed.object_id)   AS schema_name,
    OBJECT_NAME(sed.object_id)          AS object_name,
    o.type_desc                         AS object_type,
    sed.referenced_database_name        AS referenced_database,
    sed.referenced_schema_name,
    sed.referenced_entity_name
FROM sys.sql_expression_dependencies sed
JOIN sys.objects o ON sed.object_id = o.object_id
WHERE sed.referenced_database_name IS NOT NULL
  AND sed.referenced_database_name NOT IN ('master', 'tempdb', 'model', 'msdb')
  AND sed.referenced_database_name <> DB_NAME()
ORDER BY sed.referenced_database_name, object_name;


-- ============================================================
-- SECTION 9 — Windows Logins and Service Accounts
-- ============================================================
-- Purpose: Windows Authentication is not supported on RDS.
-- All Windows logins and service accounts must be converted to
-- SQL authentication or IAM authentication before migration.
-- Each Windows login is a compatibility blocker.

-- 9.1 All logins — flags Windows vs SQL auth
SELECT
    name                AS login_name,
    type_desc           AS login_type,
    -- WINDOWS_LOGIN / WINDOWS_GROUP = NOT supported on RDS
    -- SQL_LOGIN = supported on RDS
    is_disabled,
    create_date,
    modify_date,
    default_database_name
FROM sys.server_principals
WHERE type IN ('U', 'G', 'S')  -- U = Windows user, G = Windows group, S = SQL login
  AND name NOT LIKE '##%'      -- exclude internal accounts
ORDER BY type_desc, name;

-- 9.2 Database-level users per database
-- Run this in each user database
SELECT
    dp.name             AS user_name,
    dp.type_desc        AS user_type,
    dp.default_schema_name,
    sp.name             AS mapped_login
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.type IN ('U', 'G', 'S')
  AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
ORDER BY dp.type_desc, dp.name;


-- ============================================================
-- SECTION 10 — Database Mail
-- ============================================================
-- Purpose: Database Mail is not supported on RDS.
-- Any alerting or notification that uses Database Mail must be
-- replaced with SNS, SES, or Lambda before migration.

SELECT
    p.name              AS profile_name,
    a.name              AS account_name,
    a.email_address,
    a.mailserver_name,
    a.port
FROM msdb.dbo.sysmail_profile p
JOIN msdb.dbo.sysmail_profileaccount pa ON p.profile_id = pa.profile_id
JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id
ORDER BY p.name;


-- ============================================================
-- SECTION 11 — FILESTREAM / FILETABLE
-- ============================================================
-- Purpose: FILESTREAM and FILETABLE are not supported on RDS.
-- Any database using these features cannot be migrated without
-- redesigning the storage layer (typically replaced with S3).

SELECT
    name                AS database_name,
    is_filetables_enabled,
    DATABASEPROPERTYEX(name, 'IsFilestream') AS filestream_enabled
FROM sys.databases
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
ORDER BY name;


-- ============================================================
-- SECTION 12 — Active Connections and Workload Profile
-- ============================================================
-- Purpose: Understand peak connection counts and active workload
-- to right-size the RDS instance class. Also flags any
-- applications connecting from outside the VPC that would need
-- network path changes after migration.

-- 12.1 Current active sessions
SELECT
    COUNT(*)            AS active_sessions,
    SUM(CASE WHEN status = 'running' THEN 1 ELSE 0 END) AS running,
    SUM(CASE WHEN status = 'sleeping' THEN 1 ELSE 0 END) AS sleeping
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;

-- 12.2 Connections per database and login
SELECT
    DB_NAME(database_id)    AS database_name,
    login_name,
    COUNT(*)                AS connection_count,
    MAX(last_request_start_time) AS last_active
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
GROUP BY database_id, login_name
ORDER BY connection_count DESC;

-- 12.3 Max server memory configuration
SELECT
    name,
    value_in_use
FROM sys.configurations
WHERE name IN ('max server memory (MB)', 'min server memory (MB)', 'max degree of parallelism');
