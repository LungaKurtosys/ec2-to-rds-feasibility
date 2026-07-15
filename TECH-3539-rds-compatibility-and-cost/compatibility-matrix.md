# Theme B — RDS Compatibility Matrix
# [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539)

> **Status:** To Do — blocked on Theme A inventory completing first

## Feature Compatibility

Every feature identified in TECH-3538 will be assessed, including but not limited to:

| Feature | Used on EC2 | RDS Support | Workaround Available | Impact if No Workaround |
|---|---|---|---|---|
| SQL Agent Jobs — T-SQL steps | TBC | Supported | N/A | None |
| SQL Agent Jobs — CmdExec, PowerShell, SSIS | TBC | Not Supported | Lambda / Step Functions | Job redesign required |
| Linked Servers | TBC | Not Supported | Application-level joins or ETL | Blocker if in use |
| CLR — Safe assemblies | TBC | Supported | N/A | None |
| CLR — External / Unsafe assemblies | TBC | Not Supported | Rewrite as T-SQL or Lambda | Blocker if in use |
| Cross-database queries | TBC | Not Supported | Consolidate databases or use ETL | Blocker if in use |
| Windows Authentication | TBC | Not Supported | SQL authentication | Service account changes required |
| Database Mail | TBC | Not Supported | SNS / SES | Alerting redesign required |
| FILESTREAM / FILETABLE | TBC | Not Supported | S3 | Blocker if in use |
| Backup to local disk | TBC | Not Supported | S3 only | Process change required |
| Custom collation | TBC | Supported at creation only | Set at provisioning time | Must confirm before provisioning |
| CHECKDB manual run | TBC | Managed by RDS | N/A | No action needed |
| Always On / Multi-AZ | TBC | Supported — RDS Multi-AZ | N/A | None |
