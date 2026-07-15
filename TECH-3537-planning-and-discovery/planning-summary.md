# SQL Server EC2 to RDS Feasibility — Planning & Discovery
# [TECH-3537](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3537) — Investigation and Discovery Planning

> **Status:** In Progress
> **Purpose:** Define the investigation scope, discovery approach, and definition of done for each child ticket before any investigation work begins.

---

## What This Ticket Delivers

- Repo and folder structure set up
- Discovery query plan for EC2 inventory
- Definition of Done for TECH-3538, 3539, and 3540
- Open questions and blockers identified before investigation starts

---

## Scope Reminder

**In scope:**
- Inventory of self-managed SQL Server EC2 instances
- Reassessment of historical blocking dependencies
- RDS feature and version compatibility analysis
- Licensing and cost comparison
- High-level migration approach options
- Go/no-go recommendation

**Out of scope:**
- Any migration execution
- Pilot cutover or production instance moves
- Application code changes
- Engine change (SQL Server to PostgreSQL — same engine only)

---

## Definition of Done — Per Child Ticket

### TECH-3538 — Theme A: Inventory and Dependency Reassessment

- [ ] All self-managed SQL Server EC2 instances catalogued: hostname, region, version, edition, instance type, storage size, workload profile
- [ ] Dependent applications and integrations mapped per instance
- [ ] Service accounts and connection strings documented per instance
- [ ] Historical blockers listed and each assessed as **still applies** or **removed** with evidence
- [ ] inventory.md, dependency-map.md, and historical-blockers.md published

### TECH-3539 — Theme B: RDS Compatibility and Cost Analysis

- [ ] Feature compatibility matrix completed: agent jobs, linked servers, CLR, cross-database queries, service accounts, unsupported RDS features — each marked as Supported / Not Supported / Workaround Available
- [ ] RDS engine version support confirmed against current EC2 SQL Server versions
- [ ] Licensing model comparison documented: License Included vs BYOL — cost per instance
- [ ] Cost model completed: RDS running cost vs current EC2 spend including HA and backup
- [ ] compatibility-matrix.md, cost-comparison.md, and licensing-analysis.md published

### TECH-3540 — Theme C: Recommendation and Handover

- [ ] Candidate migration approaches documented with downtime and cutover implications (native backup/restore, AWS DMS — documented only, not executed)
- [ ] Risk register completed with mitigation notes
- [ ] Go/no-go recommendation written with evidence from Theme A and Theme B
- [ ] Phased migration outline written for follow-on epic (if recommendation is go)
- [ ] Manager sign-off obtained
- [ ] go-no-go-recommendation.md published

---

## Investigation Approach — Theme A

For each EC2 instance, run the following directly on the SQL Server:

### 1. Instance basics
```sql
SELECT
    SERVERPROPERTY('ServerName')        AS server_name,
    SERVERPROPERTY('ProductVersion')    AS version,
    SERVERPROPERTY('ProductLevel')      AS patch_level,
    SERVERPROPERTY('Edition')           AS edition,
    SERVERPROPERTY('EngineEdition')     AS engine_edition,
    SERVERPROPERTY('Collation')         AS collation,
    SERVERPROPERTY('IsClustered')       AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled')     AS is_hadr_enabled;
```

### 2. Database inventory
```sql
SELECT
    name,
    state_desc,
    recovery_model_desc,
    compatibility_level,
    collation_name,
    SUM(size * 8 / 1024) AS size_mb
FROM sys.databases d
JOIN sys.master_files f ON d.database_id = f.database_id
WHERE name NOT IN ('master','tempdb','model','msdb')
GROUP BY name, state_desc, recovery_model_desc, compatibility_level, collation_name
ORDER BY size_mb DESC;
```

### 3. SQL Agent jobs
```sql
SELECT
    name,
    enabled,
    description
FROM msdb.dbo.sysjobs
ORDER BY enabled DESC, name;
```

### 4. Linked servers
```sql
SELECT
    name,
    provider,
    data_source,
    is_linked
FROM sys.servers
WHERE is_linked = 1
ORDER BY name;
```

### 5. CLR usage
```sql
SELECT
    SERVERPROPERTY('IsSingleUser') AS is_single_user;

SELECT
    name,
    is_clr_enabled
FROM sys.configurations
WHERE name = 'clr enabled';

SELECT
    a.name AS assembly_name,
    a.clr_name,
    DB_NAME(a.database_id) AS db_name
FROM sys.assemblies a
WHERE a.is_user_defined = 1;
```

### 6. Cross-database queries
```sql
SELECT DISTINCT
    OBJECT_NAME(object_id) AS proc_name,
    DB_NAME() AS current_db,
    referenced_database_name AS target_db
FROM sys.sql_expression_dependencies
WHERE referenced_database_name IS NOT NULL
AND referenced_database_name NOT IN ('master','tempdb','model','msdb')
ORDER BY target_db;
```

### 7. Storage layout
```sql
SELECT
    DB_NAME(database_id) AS db_name,
    name AS logical_name,
    physical_name,
    type_desc,
    size * 8 / 1024 AS size_mb,
    growth,
    is_percent_growth
FROM sys.master_files
ORDER BY size DESC;
```

---

## Open Questions — Before Investigation Starts

| # | Question | Why It Matters |
|---|---|---|
| Q1 | How many SQL Server EC2 instances are in scope — full list with hostnames? | Cannot start inventory without knowing what to inventory |
| Q2 | Which recent platform changes removed the historical blockers? | Theme A cannot assess blockers without knowing what changed |
| Q3 | Who are the application/service owners for each instance? | Dependency mapping requires their input |
| Q4 | Do we have access to all EC2 instances to run discovery queries directly? | Blocks all of Theme A |
| Q5 | What is the current EC2 cost per instance — do we have Cost Explorer access? | Required for Theme B cost comparison |
| Q6 | Are any instances using SQL Server features known to be unsupported on RDS (CLR, linked servers, agent jobs)? | Early signal for compatibility blockers |
| Q7 | What SQL Server versions and editions are currently running across all instances? | Determines RDS engine version options |
| Q8 | Is BYOL licensing already in place or are instances running License Included on EC2? | Required for licensing comparison in Theme B |

---

## Links

| Resource | Location |
|---|---|
| Epic | [TECH-3431](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3431) |
| Theme A | [TECH-3538](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3538) |
| Theme B | [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539) |
| Theme C | [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540) |
