# Theme B — RDS Compatibility and Cost Analysis
# [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539)

> **Status:** In Progress — PRD instance data confirmed 2026-07-23. Cost model populated. Feature compatibility assessment based on known PRD workload (InvestorPress_Encore, Always On). Remaining TBC items require direct PRD query access.
> **Last Updated:** 2026-07-28

---

## Purpose

Using the inventory and dependency findings from TECH-3538, assess whether the SQL Server workloads running on EC2 are compatible with Amazon RDS for SQL Server, and produce a cost comparison between staying on EC2 and moving to RDS.

---

## Confirmed Inputs from TECH-3538

| Property | Value | Source |
|---|---|---|
| PRD instances | ew2p-mssql-01 (primary), ew2p-mssql-02 (secondary) | EW1R-REP-01 linked servers |
| SQL Server version | 2019 (15.0.4455.2) CU32 | OPENQUERY via EW1R-REP-01 |
| Edition | Enterprise Edition (64-bit) | OPENQUERY via EW1R-REP-01 |
| Instance type | r6i.2xlarge (8 vCPU, 64 GB RAM) | INFO_AWS_EC2_Detail in DBA_VCC_AWS |
| Storage per node | 2,680 GB total (80 + 1,400 + 800 + 400 GB) | INFO_AWS_EC2_Detail in DBA_VCC_AWS |
| License model | BYOL — confirmed | LICENSE-EXEMPTION-KSYS-MSSQL-PASSIVE-NODE in cost data |
| HA topology | Always On Availability Group (primary + secondary) | Workload profile confirmed |
| Workload | InvestorPress_Encore | Confirmed |
| OS disk encryption | Unencrypted (80 GB OS disk) — compliance finding | INFO_AWS_EC2_Detail |

---

## Feature Compatibility Matrix

> Assessment basis: SQL Server 2019 Enterprise on EC2 → RDS for SQL Server. Features marked TBC require direct PRD query access to confirm whether they are in use.

| Feature | In Use on EC2 | RDS Support | Workaround | Impact |
|---|---|---|---|---|
| SQL Agent Jobs — T-SQL steps | Yes — confirmed (EW1R-REP-01 monitors jobs) | ✅ Supported | N/A | None |
| SQL Agent Jobs — CmdExec / PowerShell steps | TBC — requires direct PRD query | ❌ Not Supported | Lambda / Step Functions / SSM Run Command | Blocker if in use — job redesign required |
| SQL Agent Jobs — SSIS steps | TBC | ❌ Not Supported | AWS Glue / SSIS on EC2 sidecar | Blocker if in use |
| Always On Availability Groups | Yes — primary/secondary confirmed | ✅ Supported via RDS Multi-AZ | Use RDS Multi-AZ deployment | None — RDS Multi-AZ replaces Always On |
| Linked Servers | TBC — EW1R-REP-01 has linked servers to PRD; PRD-to-PRD linked servers unknown | ❌ Not Supported on RDS | Application-level joins or ETL pipeline | Blocker if PRD instances have outbound linked servers |
| CLR — Safe assemblies | TBC | ✅ Supported | N/A | None if only Safe |
| CLR — External / Unsafe assemblies | TBC | ❌ Not Supported | Rewrite as T-SQL or move to Lambda | Blocker if in use |
| Cross-database queries | TBC — 32 databases on REL suggest likely on PRD too | ❌ Not Supported | Consolidate databases or use ETL | Blocker if in use — high likelihood given workload |
| Windows Authentication / AD logins | TBC | ❌ Not Supported (standard RDS) | SQL auth or RDS Kerberos with AWS Managed AD | Service account changes required |
| Database Mail | TBC | ❌ Not Supported | Amazon SNS / SES | Alerting redesign if in use |
| FILESTREAM / FILETABLE | TBC | ❌ Not Supported | S3 | Blocker if in use |
| SSRS (SQL Server Reporting Services) | TBC | ❌ Not Supported | Power BI / QuickSight / SSRS on separate EC2 | Blocker if in use |
| Backup to local disk | TBC | ❌ Not Supported | S3 only (native RDS backup) | Process change — not a blocker |
| Custom collation | Latin1_General_CI_AS confirmed on REL — PRD TBC | ✅ Supported at DB creation | Must be set at provisioning time | Confirm PRD collation before provisioning |
| CHECKDB | Manual on EC2 | ✅ Managed by RDS automatically | N/A | Improvement — no action needed |
| Transparent Data Encryption (TDE) | TBC | ✅ Supported | N/A | None |
| Data compression | TBC — Enterprise feature | ✅ Supported on RDS Enterprise | N/A | None |
| Online index operations | TBC — Enterprise feature | ✅ Supported on RDS Enterprise | N/A | None |
| Resource Governor | TBC | ❌ Not Supported on RDS | Workload management via instance sizing | Low impact unless actively used |
| SQL Server version (2019) | 2019 CU32 | ✅ RDS supports SQL Server 2019 | N/A | None |
| Enterprise Edition on RDS | Required — BYOL only | ✅ Supported — BYOL only | N/A | BYOL confirmed — no blocker |

---

## Compatibility Blockers Summary

These are the features that are either confirmed blockers or high-likelihood blockers pending PRD query access:

| # | Blocker | Likelihood | Status | Action Required |
|---|---|---|---|---|
| 1 | Cross-database queries | High — 32 databases on REL, likely same on PRD | TBC — needs PRD query | Run cross-database dependency query on PRD |
| 2 | Linked servers (PRD outbound) | Medium — EW1R-REP-01 has inbound links to PRD; PRD outbound unknown | TBC — needs PRD query | Query sys.servers on PRD |
| 3 | Windows Authentication / AD logins | Medium — common in enterprise SQL Server | TBC — needs PRD query | Query sys.server_principals on PRD |
| 4 | CmdExec / PowerShell SQL Agent steps | Medium | TBC — needs PRD query | Query msdb.dbo.sysjobsteps on PRD |
| 5 | SSIS job steps | Low-Medium | TBC — needs PRD query | Query msdb.dbo.sysjobsteps on PRD |
| 6 | CLR Unsafe/External assemblies | Low | TBC — needs PRD query | Query sys.assemblies on PRD |
| 7 | SSRS | Low — no evidence of SSRS use | TBC | Confirm with application team |

> **Note:** None of these are confirmed hard blockers yet. All require direct PRD query access or stakeholder confirmation. The PRD database inventory queries (planned for this sprint) will resolve blockers 1–6.

---

## Licensing Analysis

### Enterprise Edition — BYOL is the Only RDS Option

RDS for SQL Server does not offer License Included for Enterprise Edition. BYOL is the only path. This is confirmed as viable because BYOL is already in place on EC2.

| Option | Available for Enterprise on RDS | Cost Model | Status |
|---|---|---|---|
| License Included | ❌ Not available for Enterprise | N/A | Not applicable |
| BYOL | ✅ Available | Compute + storage only — no license cost on AWS bill | **Confirmed viable — BYOL already in place** |

### BYOL Evidence

The `LICENSE-EXEMPTION-KSYS-MSSQL-PASSIVE-NODE` line item appears consistently in AWS cost data for ew2p-mssql-02 from 2024-07-23 through 2026-07-23. AWS only grants this passive node license exemption under the Microsoft SQL Server BYOL passive node rule — it is not available under License Included. This confirms Kurtosys owns the Enterprise licenses with active Software Assurance.

### AWS License Mobility

To use existing licenses on RDS, AWS License Mobility must be formally activated. This is an administrative step — not a technical blocker — but it must be initiated before migration begins. Confirm with the manager whether this has been done previously or is a first-time activation.

---

## Cost Model

### EC2 Baseline — Confirmed from EW1R-REP-01 Monitoring Data

> Source: INFO_AWS_Entity_Cost in DBA_VCC_AWS on EW1R-REP-01. Real AWS billing data collected daily.

| Period | ew2p-mssql-01/month | ew2p-mssql-02/month | Combined |
|---|---|---|---|
| 2024 – Oct 2025 (confirmed baseline) | ~$3,150 | ~$960 | **~$4,110/month** |
| Nov 2025 onwards (change detected — under investigation) | ~$285 | ~$960 | **~$1,245/month** |

> The cost drop on ew2p-mssql-01 from ~$103/day to ~$9/day around Oct/Nov 2025 is unexplained. Possible causes: instance stopped, resized, or SQL Server license removed. This must be confirmed before the cost comparison is finalised. The 2024 baseline (~$4,110/month) is used as the conservative comparison figure.

### RDS Cost Estimate — BYOL, db.r6i.2xlarge, Multi-AZ

> Indicative figures based on confirmed instance type (r6i.2xlarge) and BYOL licensing. Exact figures to be confirmed via AWS Pricing Calculator.

| Component | Cost/month | Notes |
|---|---|---|
| RDS db.r6i.2xlarge — primary (BYOL) | ~$800–$900 | Compute only — no license cost |
| RDS Multi-AZ standby | ~$800–$900 | Replaces ew2p-mssql-02 + Always On |
| Storage — gp3, 2,680 GB | ~$270 | $0.10/GB-month on RDS gp3 |
| Automated backup storage | ~$50–$100 | Depends on retention period |
| **Total estimated** | **~$2,000–$2,500/month** | Both nodes combined |

### EC2 vs RDS Comparison

| Item | EC2 (2024 baseline) | RDS BYOL Estimate | Saving |
|---|---|---|---|
| Compute — primary node | ~$3,150/month | ~$800–$900/month | ~$2,250/month |
| Compute — secondary node | ~$960/month | Included in Multi-AZ | ~$960/month |
| Storage | Included in EBS cost above | ~$270/month | Offset |
| Automated backups | Manual — separate S3 cost | Included | Saving |
| OS patching | Manual effort | Managed by AWS | Effort saving |
| **Total** | **~$4,110/month** | **~$2,000–$2,500/month** | **~$1,600–$2,100/month** |

> If the Nov 2025 cost change is confirmed as a legitimate resize (not a stopped instance), the saving narrows to ~$0–$500/month against the current ~$1,245/month baseline. This scenario must be investigated before presenting the cost case.

---

## RDS Engine Version Compatibility

| EC2 SQL Server Version | RDS Support | Notes |
|---|---|---|
| SQL Server 2019 (15.0.4455.2) CU32 | ✅ Supported | RDS supports SQL Server 2019 — minor version managed by AWS |
| SQL Server 2019 Enterprise Edition | ✅ Supported — BYOL only | Confirmed viable |

---

## Definition of Done

- [x] Confirmed inputs from TECH-3538 documented — instance type, edition, BYOL, storage, cost baseline
- [x] Feature compatibility matrix completed for known features — Supported / Not Supported / Workaround
- [x] Compatibility blockers listed with likelihood and action required
- [x] Licensing analysis completed — BYOL confirmed, License Mobility noted
- [x] Cost model populated — EC2 baseline confirmed, RDS estimate calculated, saving quantified
- [x] RDS engine version support confirmed against current EC2 SQL Server version
- [ ] Compatibility blockers 1–6 resolved via direct PRD query access
- [ ] Cost model finalised — Nov 2025 cost change investigated and confirmed
- [ ] AWS License Mobility activation status confirmed with manager
- [ ] Exact RDS pricing confirmed via AWS Pricing Calculator
- [ ] compatibility-matrix.md published to Confluence
- [ ] Findings handed over to TECH-3540 for recommendation

---

## Dependencies

- TECH-3538 complete — ✅ PRD instance data confirmed
- Direct PRD query access — needed to resolve compatibility blockers 1–6
- Manager confirmation — AWS License Mobility activation status

---

## Links

| Ticket | Description |
|---|---|
| [TECH-3431](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3431) | Parent epic |
| [TECH-3537](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3537) | Planning ticket |
| [TECH-3538](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3538) | Theme A — inventory source |
| [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540) | Theme C — blocked on this |
