# Theme B — RDS Compatibility Matrix
# [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539)

> **Status:** To Do — blocked on Theme A inventory completing first

## Feature Compatibility

| Feature | Used on EC2? | Supported on RDS? | Notes |
|---|---|---|---|
| SQL Agent Jobs | TBC | Partial — limited job types | No CmdExec, PowerShell, SSIS steps |
| Linked Servers | TBC | No | Not supported on RDS for SQL Server |
| CLR Assemblies | TBC | Partial — safe assemblies only | UNSAFE/EXTERNAL_ACCESS not allowed |
| Cross-database queries | TBC | No | Single database per RDS instance |
| Windows Authentication | TBC | No | SQL auth only on RDS |
| Custom collation | TBC | Partial — set at instance creation only | Cannot change after provisioning |
| FILESTREAM / FILETABLE | TBC | No | Not supported |
| Database Mail | TBC | No | Not supported |
| Backup to local disk | TBC | No | Backup to S3 only |
| CHECKDB manual run | TBC | No | Managed automatically by RDS |
