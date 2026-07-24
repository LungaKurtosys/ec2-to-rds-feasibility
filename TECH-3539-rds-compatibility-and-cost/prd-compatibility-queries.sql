-- ============================================================
-- TECH-3539 — PRD Compatibility Queries via EW1R-REP-01
-- ============================================================
-- Run all queries from EW1R-REP-01 (ew1r-rep-01.ad.shnonprd.kurtosys-internal.net)
-- Uses existing linked servers to ew2p-mssql-01 and ew2p-mssql-02
-- No direct PRD access required — all queries are read-only
-- ============================================================


-- ============================================================
-- SECTION 1 — Instance Basics (confirm collation, HA, auth mode)
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        SERVERPROPERTY(''ServerName'')              AS server_name,
        SERVERPROPERTY(''ProductVersion'')          AS version,
        SERVERPROPERTY(''Edition'')                 AS edition,
        SERVERPROPERTY(''Collation'')               AS collation,
        SERVERPROPERTY(''IsHadrEnabled'')           AS is_hadr_enabled,
        SERVERPROPERTY(''IsIntegratedSecurityOnly'') AS windows_auth_only
');

SELECT * FROM OPENQUERY([ew2p-mssql-02], '
    SELECT
        SERVERPROPERTY(''ServerName'')              AS server_name,
        SERVERPROPERTY(''ProductVersion'')          AS version,
        SERVERPROPERTY(''Edition'')                 AS edition,
        SERVERPROPERTY(''Collation'')               AS collation,
        SERVERPROPERTY(''IsHadrEnabled'')           AS is_hadr_enabled,
        SERVERPROPERTY(''IsIntegratedSecurityOnly'') AS windows_auth_only
');


-- ============================================================
-- SECTION 2 — Database Inventory
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        d.name                          AS database_name,
        d.state_desc,
        d.recovery_model_desc,
        d.compatibility_level,
        d.collation_name,
        SUM(f.size) * 8 / 1024         AS total_size_mb
    FROM sys.databases d
    JOIN sys.master_files f ON d.database_id = f.database_id
    WHERE d.name NOT IN (''master'', ''tempdb'', ''model'', ''msdb'')
    GROUP BY d.name, d.state_desc, d.recovery_model_desc, d.compatibility_level, d.collation_name
    ORDER BY total_size_mb DESC
');


-- ============================================================
-- SECTION 3 — SQL Agent Job Steps (blocker 4 + 5)
-- Flags any CmdExec, PowerShell, or SSIS steps — not supported on RDS
-- ============================================================

-- All non-T-SQL steps on ew2p-mssql-01
SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        j.name          AS job_name,
        j.enabled,
        js.step_id,
        js.step_name,
        js.subsystem
    FROM msdb.dbo.sysjobs j
    JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
    WHERE js.subsystem NOT IN (''TSQL'')
    ORDER BY j.name, js.step_id
');

-- All non-T-SQL steps on ew2p-mssql-02
SELECT * FROM OPENQUERY([ew2p-mssql-02], '
    SELECT
        j.name          AS job_name,
        j.enabled,
        js.step_id,
        js.step_name,
        js.subsystem
    FROM msdb.dbo.sysjobs j
    JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
    WHERE js.subsystem NOT IN (''TSQL'')
    ORDER BY j.name, js.step_id
');

-- Full job step list (all subsystems) for complete picture
SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        j.name          AS job_name,
        j.enabled,
        js.subsystem,
        COUNT(*)        AS step_count
    FROM msdb.dbo.sysjobs j
    JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
    GROUP BY j.name, j.enabled, js.subsystem
    ORDER BY js.subsystem, j.name
');


-- ============================================================
-- SECTION 4 — Linked Servers on PRD (blocker 2)
-- Flags any outbound linked servers from PRD — not supported on RDS
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        name            AS linked_server_name,
        provider,
        data_source,
        product,
        is_linked
    FROM sys.servers
    WHERE is_linked = 1
    ORDER BY name
');

SELECT * FROM OPENQUERY([ew2p-mssql-02], '
    SELECT
        name            AS linked_server_name,
        provider,
        data_source,
        product,
        is_linked
    FROM sys.servers
    WHERE is_linked = 1
    ORDER BY name
');


-- ============================================================
-- SECTION 5 — Windows Logins and Service Accounts (blocker 3)
-- Windows Authentication not supported on RDS
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        name            AS login_name,
        type_desc       AS login_type,
        is_disabled,
        default_database_name
    FROM sys.server_principals
    WHERE type IN (''U'', ''G'', ''S'')
      AND name NOT LIKE ''##%''
    ORDER BY type_desc, name
');

SELECT * FROM OPENQUERY([ew2p-mssql-02], '
    SELECT
        name            AS login_name,
        type_desc       AS login_type,
        is_disabled,
        default_database_name
    FROM sys.server_principals
    WHERE type IN (''U'', ''G'', ''S'')
      AND name NOT LIKE ''##%''
    ORDER BY type_desc, name
');


-- ============================================================
-- SECTION 6 — CLR Assemblies (blocker 6)
-- SAFE = supported on RDS. EXTERNAL_ACCESS / UNSAFE = blocker
-- ============================================================

-- CLR enabled flag
SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT name, value_in_use AS clr_enabled
    FROM sys.configurations
    WHERE name = ''clr enabled''
');

-- User-defined assemblies — run per database
-- Replace <database_name> with each database from Section 2 results
SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        DB_NAME()               AS database_name,
        a.name                  AS assembly_name,
        a.permission_set_desc,
        a.create_date
    FROM sys.assemblies a
    WHERE a.is_user_defined = 1
');
-- Note: sys.assemblies is database-scoped — repeat for each user database
-- or use sp_MSforeachdb if available


-- ============================================================
-- SECTION 7 — Cross-Database Dependencies (blocker 1)
-- Cross-database queries not supported on RDS
-- Run against each user database on ew2p-mssql-01
-- ============================================================

-- This query checks the current database context
-- You need to run it per database — use the database list from Section 2
-- Example for one database:
SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    USE [<database_name>];
    SELECT DISTINCT
        DB_NAME()                           AS current_database,
        OBJECT_NAME(sed.object_id)          AS object_name,
        o.type_desc                         AS object_type,
        sed.referenced_database_name        AS referenced_database,
        sed.referenced_entity_name
    FROM sys.sql_expression_dependencies sed
    JOIN sys.objects o ON sed.object_id = o.object_id
    WHERE sed.referenced_database_name IS NOT NULL
      AND sed.referenced_database_name NOT IN (''master'', ''tempdb'', ''model'', ''msdb'')
      AND sed.referenced_database_name <> DB_NAME()
    ORDER BY sed.referenced_database_name, object_name
');

-- Shortcut — check all databases at once using sp_MSforeachdb
-- Run this directly on ew2p-mssql-01 if you have access, or via OPENQUERY
SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    EXEC sp_MSforeachdb ''
        USE [?];
        SELECT
            DB_NAME() AS current_database,
            OBJECT_NAME(sed.object_id) AS object_name,
            o.type_desc,
            sed.referenced_database_name,
            sed.referenced_entity_name
        FROM sys.sql_expression_dependencies sed
        JOIN sys.objects o ON sed.object_id = o.object_id
        WHERE sed.referenced_database_name IS NOT NULL
          AND sed.referenced_database_name NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''')
          AND sed.referenced_database_name <> DB_NAME()
    ''
');


-- ============================================================
-- SECTION 8 — Database Mail (confirm if in use)
-- Database Mail not supported on RDS
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        p.name          AS profile_name,
        a.name          AS account_name,
        a.email_address,
        a.mailserver_name
    FROM msdb.dbo.sysmail_profile p
    JOIN msdb.dbo.sysmail_profileaccount pa ON p.profile_id = pa.profile_id
    JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id
');


-- ============================================================
-- SECTION 9 — FILESTREAM / FILETABLE (confirm if in use)
-- Not supported on RDS
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        name            AS database_name,
        DATABASEPROPERTYEX(name, ''IsFilestream'') AS filestream_enabled
    FROM sys.databases
    WHERE name NOT IN (''master'', ''tempdb'', ''model'', ''msdb'')
    ORDER BY name
');


-- ============================================================
-- SECTION 10 — Backup History (confirm destinations)
-- Local disk backups not supported on RDS — S3 only
-- ============================================================

SELECT * FROM OPENQUERY([ew2p-mssql-01], '
    SELECT
        bs.database_name,
        bs.type                                     AS backup_type,
        MAX(bs.backup_finish_date)                  AS last_backup,
        bmf.physical_device_name                    AS backup_destination
    FROM msdb.dbo.backupset bs
    JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.backup_finish_date >= DATEADD(DAY, -30, GETDATE())
    GROUP BY bs.database_name, bs.type, bmf.physical_device_name
    ORDER BY bs.database_name, bs.type
');
