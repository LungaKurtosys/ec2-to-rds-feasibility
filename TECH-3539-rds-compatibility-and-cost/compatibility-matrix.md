# Theme B — RDS Compatibility and Cost Analysis
# [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539)

> **Status:** To Do — blocked on TECH-3538 completing first

---

## Purpose

Using the inventory and dependency findings from TECH-3538, assess whether the SQL Server workloads running on EC2 are compatible with Amazon RDS for SQL Server, and produce a cost comparison between staying on EC2 and moving to RDS. This ticket produces the two critical inputs that Theme C needs to make a go/no-go recommendation.

---

## Background

TECH-3538 produced a full picture of what is running on each EC2 instance — versions, editions, databases, jobs, linked servers, CLR, cross-database dependencies, and service accounts. This ticket takes those findings and maps each one against what RDS for SQL Server supports. It also builds the cost model — what RDS would cost versus what EC2 costs today, including licensing, HA, and backup.

---

## This Ticket Delivers

- Feature compatibility matrix: every SQL Server feature in use on EC2 assessed against RDS support — Supported, Not Supported, or Workaround Available
- RDS engine version support confirmed against the SQL Server versions currently running on EC2
- Licensing model comparison: License Included vs BYOL — cost per instance
- Cost model: RDS running cost vs current EC2 spend including Multi-AZ, storage, and backup
- Clear list of compatibility blockers — features in use that RDS does not support, with impact assessment

---

## Feature Compatibility Matrix

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

---

## Cost Comparison

| Item | Current EC2 Cost | RDS Equivalent Cost | Notes |
|---|---|---|---|
| Compute per instance | TBC | TBC | RDS instance class TBC |
| Storage | TBC | TBC | RDS gp3 storage |
| High Availability | TBC | TBC | RDS Multi-AZ |
| Backup storage | TBC | TBC | RDS automated backup to S3 |
| Licensing | TBC | TBC | License Included vs BYOL |
| Total per instance | TBC | TBC | |
| Total across all instances | TBC | TBC | |

---

## Licensing Comparison

| Option | Description | Cost Impact |
|---|---|---|
| License Included | AWS bundles SQL Server licence into RDS hourly rate | Higher hourly rate — no upfront licence cost |
| BYOL | Bring existing SQL Server licence to RDS | Lower hourly rate — requires active SA coverage |

---

## Definition of Done

- [ ] Feature compatibility matrix completed for every feature identified in TECH-3538 — each marked as Supported, Not Supported, or Workaround Available
- [ ] RDS engine version support confirmed against current EC2 SQL Server versions
- [ ] Compatibility blockers listed with impact assessment per instance
- [ ] Licensing model comparison documented: License Included vs BYOL per instance
- [ ] Cost model completed: RDS running cost vs current EC2 spend per instance
- [ ] Total cost of ownership comparison documented across all instances
- [ ] compatibility-matrix.md published to Confluence
- [ ] cost-comparison.md published to Confluence
- [ ] licensing-analysis.md published to Confluence
- [ ] Findings handed over to TECH-3540 for recommendation

---

## Dependencies

- Requires TECH-3538 complete before starting
- TECH-3540 blocked until this is done

---

## Links

| Ticket | Description |
|---|---|
| [TECH-3431](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3431) | Parent epic |
| [TECH-3537](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3537) | Planning ticket |
| [TECH-3538](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3538) | Theme A — must complete before this |
| [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540) | Theme C — blocked on this |
