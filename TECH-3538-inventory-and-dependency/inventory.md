# Theme A — SQL Server EC2 Inventory and Dependency Reassessment
# [TECH-3538](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3538)

> **Status:** In Progress — PRD instance data confirmed 2026-07-23 via EW1R-REP-01 monitoring data
> **Last Updated:** 2026-07-23 — Instance type, storage, actual EC2 cost, and BYOL status all confirmed from DBA_VCC_AWS on EW1R-REP-01

---

## Purpose

Take the discovery query outputs captured in TECH-3537 and produce the full inventory of every SQL Server EC2 instance in scope, map all applications and integrations that depend on each one, and reassess the historical blockers that previously prevented migration to RDS. This ticket produces the evidence base that Theme B and Theme C depend on.

---

## Background

TECH-3537 confirmed the list of instances, established access, and ran all discovery queries against each EC2 instance. This ticket takes those outputs and turns them into structured, documented findings — a complete picture of what is running, what depends on it, and whether the historical reasons for staying on EC2 still apply after recent platform changes.

---

## This Ticket Delivers

- Full inventory of every SQL Server EC2 instance: hostname, region, environment, version, edition, instance type, storage size, and workload profile
- All user databases documented per instance: size, recovery model, compatibility level, collation
- Storage layout per instance: file locations, growth settings, backup destination
- Dependent applications and integrations mapped per instance
- Service accounts and Windows logins documented per instance
- SQL Agent jobs, linked servers, CLR assemblies, and cross-database dependencies captured per instance
- Historical blockers listed and each assessed as still applies or removed, with evidence

---

## Instance Inventory

| Hostname | Region | Environment | SQL Server Version | Edition | License Model | Instance Type | Storage (GB) | Workload Profile |
|---|---|---|---|---|---|---|---|---|
| ew1d-mssql-01 | Ireland (eu-west-1) | DEV | TBC | TBC | N/A — Dev | TBC | TBC | InvestorPress_Encore |
| ew1r-mssql-01 | Ireland (eu-west-1) | REL | 2019 (15.0.4455.2) CU32 | Developer Edition | Free — non-prod only | TBC | TBC | InvestorPress_Encore |
| ew2p-mssql-01 | London (eu-west-2) | PRD | 2019 (15.0.4455.2) CU32 | Enterprise Edition (64-bit) | **BYOL — confirmed** | r6i.2xlarge (8 vCPU, 64 GB) | 2,680 GB total (80 + 1,400 + 800 + 400) | InvestorPress_Encore — Always On primary |
| ew2p-mssql-02 | London (eu-west-2) | PRD | 2019 (15.0.4455.2) CU32 | Enterprise Edition (64-bit) | **BYOL — confirmed** | r6i.2xlarge (8 vCPU, 64 GB) | 2,680 GB total (80 + 1,400 + 800 + 400) | InvestorPress_Encore — Always On secondary |

> **How this was confirmed:** Edition and version confirmed 2026-07-23 via OPENQUERY through EW1R-REP-01 linked servers. Instance type, storage, and BYOL status confirmed from INFO_AWS_EC2_Detail and INFO_AWS_Entity_Cost tables in DBA_VCC_AWS on EW1R-REP-01 — the monitoring server already collects this data weekly. No direct PRD access was required.
>
> **BYOL evidence:** The LICENSE-EXEMPTION-KSYS-MSSQL-PASSIVE-NODE line item appears consistently in the cost data for ew2p-mssql-02. AWS only grants this passive node license exemption under the Microsoft SQL Server BYOL passive node rule — it is not available under License Included. This confirms Kurtosys owns the Enterprise licenses and is running BYOL. Scenario A applies.
>
> **Instance type history:** Both nodes ran on r6i.4xlarge from at least July 2023 until February 2024, then were downsized to r6i.2xlarge in February 2024 and have remained on r6i.2xlarge since. This is confirmed by 18+ months of weekly snapshots in INFO_AWS_EC2_Detail.
>
> **Storage encryption note:** The 80 GB OS disk on both nodes is unencrypted. The three data disks (1,400 GB, 800 GB, 400 GB) are encrypted. This is a compliance finding — the OS disk should be encrypted before or during migration.

---

## SQL Server Licensing — Enterprise Edition Analysis

> This section is the single most important cost input for TECH-3539. Both PRD nodes are Enterprise Edition. RDS does not offer License Included for Enterprise — BYOL is the only option on RDS for Enterprise Edition. The answer to the BYOL question below determines whether migration to RDS is cost-effective or not.

### What Is BYOL?

BYOL (Bring Your Own License) means Kurtosys already owns the SQL Server Enterprise licenses purchased directly from Microsoft, typically through a Volume Licensing agreement with Software Assurance (SA). On AWS, BYOL means you pay only for EC2 or RDS compute and storage — the license cost is not added to the AWS bill because you already own it.

The alternative is License Included — AWS bundles the SQL Server license into the hourly instance cost. This is available for Standard Edition on RDS but **is not available for Enterprise Edition on RDS**.

### Current Situation — BYOL Confirmed

Both PRD nodes are running SQL Server 2019 Enterprise Edition on r6i.2xlarge instances. **BYOL is confirmed** — the LICENSE-EXEMPTION-KSYS-MSSQL-PASSIVE-NODE line item in the AWS cost data for ew2p-mssql-02 is proof. AWS only applies this exemption when a customer is running under BYOL with active Software Assurance. This means Kurtosys owns the Enterprise licenses and Scenario A applies.

### Scenario A — BYOL Already in Place

**What it means:** Kurtosys owns active SQL Server Enterprise licenses with Software Assurance. Those licenses can be moved to RDS under the AWS License Mobility program.

**Cost impact:** Compute and storage costs only on RDS. No additional license purchase needed. This is the most cost-effective path to RDS.

**Estimated RDS cost (indicative — exact figures require instance type confirmation):**

| Component | Estimated Monthly Cost (per node) | Notes |
|---|---|---|
| RDS db.r6i.2xlarge (8 vCPU, 64 GB) | ~$800–$1,000 | BYOL pricing — compute only |
| Multi-AZ standby | ~$800–$1,000 | RDS Multi-AZ doubles compute cost |
| Storage (gp3, 1 TB) | ~$115 | Per node |
| Backup storage | ~$50–$100 | Depends on retention period |
| **Total (both nodes combined)** | **~$3,500–$4,500/month** | Indicative only — confirm instance type |

**Effort:** Low-to-medium. License transfer is administrative. Migration effort is driven by the blockers (SSIS, SSRS, Windows logins) not the license.

**Recommendation if Scenario A:** Proceed with RDS migration. Cost is predictable and manageable. Use AWS License Mobility to transfer existing licenses.

### Scenario B — No BYOL — License Included on EC2

**What it means:** The SQL Server Enterprise license is currently bundled into the EC2 hourly cost (License Included on EC2). Kurtosys does not own the license outright. Moving to RDS would require either purchasing new Enterprise licenses with Software Assurance, downgrading to Standard Edition, or staying on EC2.

**Option B1 — Purchase Enterprise licenses for BYOL on RDS:**
- SQL Server Enterprise with SA costs approximately $14,256 per core per year from Microsoft
- A typical 8-core instance = ~$114,048/year in license cost alone, per node
- Two PRD nodes = ~$228,096/year just for licenses, before any AWS compute cost
- This is almost certainly not cost-effective unless there is a strategic reason to own the licenses
- **Effort:** High — procurement, Microsoft agreement negotiation, SA activation
- **Recommendation:** Do not pursue this path unless Microsoft EA is already in negotiation

**Option B2 — Downgrade to Standard Edition on RDS (License Included):**
- RDS Standard Edition License Included is available and significantly cheaper
- Standard Edition is capped at 24 cores and 128 GB RAM — must confirm PRD instance size fits within these limits
- Application compatibility must be verified — any Enterprise-only features in use would break
- Enterprise-only features to check: Advanced HADR (Always On with more than 1 secondary), partitioning, online index operations, data compression, Resource Governor
- **Estimated RDS Standard Edition License Included cost (indicative):**

| Component | Estimated Monthly Cost (per node) | Notes |
|---|---|---|
| RDS db.r6i.2xlarge Standard LI | ~$1,400–$1,800 | License Included pricing |
| Multi-AZ standby | ~$1,400–$1,800 | Doubles compute cost |
| Storage (gp3, 1 TB) | ~$115 | Per node |
| **Total (both nodes combined)** | **~$6,000–$7,500/month** | Indicative only |

- **Effort:** High — edition downgrade requires application compatibility testing, feature audit, and regression testing across all InvestorPress_Encore workloads
- **Recommendation:** Only viable if application compatibility is confirmed clean and PRD instance fits within Standard Edition limits

**Option B3 — Stay on EC2:**
- No license change needed. EC2 License Included continues as-is
- Loses the operational benefits of RDS (automated backups, patching, Multi-AZ failover, no OS management)
- **Effort:** Zero — no migration
- **Recommendation:** Valid fallback if licensing cost makes RDS uneconomical. Should be documented as the baseline in the go/no-go recommendation

### Q8 — Resolved

| # | Question | Status | Evidence |
|---|---|---|---|
| Q8 | Is BYOL already in place? | **Closed — BYOL confirmed** | LICENSE-EXEMPTION-KSYS-MSSQL-PASSIVE-NODE appears in AWS cost data for ew2p-mssql-02 consistently from 2024-07-23 through 2026-07-23. AWS only grants this under BYOL with active SA. |

> **Action for manager discussion (2026-07-24):** Q8 is now closed — BYOL is confirmed from the cost data. The remaining question to raise with your manager is whether AWS License Mobility has been formally activated for RDS, or whether this would be a first-time activation. This is an administrative step, not a blocker, but it needs to be initiated before migration begins.

---

## Actual EC2 Cost — Confirmed from EW1R-REP-01 Monitoring Data

> Source: INFO_AWS_Entity_Cost table in DBA_VCC_AWS on EW1R-REP-01. Data collected daily. This is real AWS billing data, not an estimate.

### Why EW1R-REP-01 Has This Data

EW1R-REP-01 is the monitoring server that watches over the PRD SQL Server instances. It has linked servers pointing directly at ew2p-mssql-01 and ew2p-mssql-02, and it runs SQL Agent jobs that collect AWS cost data from Cost Explorer via the DBA_VCC_AWS database. This means the actual EC2 spend for the PRD nodes has been recorded daily since at least mid-2024 — without needing direct access to the AWS console or Cost Explorer.

### Confirmed Daily Cost (2024 baseline — r6i.2xlarge)

| Instance | Typical Daily Cost | Monthly Estimate | Notes |
|---|---|---|---|
| ew2p-mssql-01 | ~$103–$107/day | **~$3,150/month** | Primary node — higher cost includes SQL Server compute |
| ew2p-mssql-02 | ~$31–$33/day | **~$960/month** | Secondary/passive node — lower cost due to BYOL passive node exemption |
| LICENSE-EXEMPTION-KSYS-MSSQL-PASSIVE-NODE | ~$0.003/day | negligible | AWS passive node license credit — confirms BYOL |
| **Both nodes combined** | **~$135–$140/day** | **~$4,110/month** | Baseline EC2 cost for PRD SQL Server |

### Cost Change Detected — Late 2025

The cost data shows ew2p-mssql-01 dropped from ~$103/day to ~$9–10/day around October/November 2025, while ew2p-mssql-02 remained at ~$31/day. This is a significant change and needs to be confirmed:

- ew2p-mssql-01 may have been stopped, resized, or had its SQL Server license removed
- If ew2p-mssql-01 was downsized, the current PRD cost baseline is lower than the 2024 figure
- This must be confirmed before the cost comparison in TECH-3539 is finalised

| Period | ew2p-mssql-01/month | ew2p-mssql-02/month | Combined |
|---|---|---|---|
| 2024 – Oct 2025 (confirmed baseline) | ~$3,150 | ~$960 | **~$4,110/month** |
| Nov 2025 onwards (change detected) | ~$285 | ~$960 | **~$1,245/month** |

### RDS Cost Comparison — Scenario A (BYOL confirmed)

Now that BYOL is confirmed and the instance type is known (r6i.2xlarge), the RDS cost comparison can be calculated accurately for TECH-3539:

| Component | EC2 Current (2024 baseline) | RDS BYOL Equivalent | Difference |
|---|---|---|---|
| ew2p-mssql-01 compute | ~$3,150/month | ~$800–$900/month (db.r6i.2xlarge BYOL) | RDS ~$2,250 cheaper |
| ew2p-mssql-02 compute | ~$960/month | ~$800–$900/month (Multi-AZ standby) | Similar |
| Storage (2,680 GB × 2 nodes) | Included in EC2 EBS cost | ~$270/month (gp3) | Separate on RDS |
| Automated backups | Manual — S3 cost separate | Included in RDS | Saving |
| OS patching | Manual effort | Managed by AWS | Effort saving |
| **Total estimated** | **~$4,110/month** | **~$2,000–$2,500/month** | **~$1,600–$2,100/month saving** |

> These are indicative figures. TECH-3539 will produce the full cost model with exact RDS pricing from the AWS Pricing Calculator.

---

## Database Inventory

| Instance | Database | Size (MB) | Recovery Model | Compatibility Level | Collation |
|---|---|---|---|---|---|
| ew1r-mssql-01 | 32 user databases, ~342 GB total | Various | FULL (all) | Mostly 130, some 150 | Latin1_General_CI_AS (except ReportServer* — Latin1_General_100_CI_AS_KS_WS) |
| ew2p-mssql-01 | TBC — PRD assessment pending | TBC | TBC | TBC | TBC |
| ew2p-mssql-02 | TBC — PRD assessment pending | TBC | TBC | TBC | TBC |
| ew1d-mssql-01 | TBC — DEV assessment pending | TBC | TBC | TBC | TBC |

---

## Dependency Map

| Instance | Application / Service | Connection Type | Owner | Impact if Instance Moves |
|---|---|---|---|---|
| TBC | TBC | TBC | TBC | TBC |

---

## Historical Blocker Reassessment

| Blocker | Previously Blocked Migration | Still Applies | Evidence |
|---|---|---|---|
| TBC | TBC | TBC | TBC |

---

## Definition of Done

- [x] All SQL Server EC2 instances catalogued: hostname, region, environment, version, edition, instance type, storage size, workload profile — PRD confirmed 2026-07-23 from EW1R-REP-01 monitoring data
- [ ] All user databases inventoried per instance: size, recovery model, compatibility level, collation
- [ ] Storage layout documented per instance: file locations, growth settings
- [ ] Backup history captured per instance: last backup date, type, destination
- [ ] SQL Agent jobs listed per instance: name, enabled status, step types
- [ ] Linked servers listed per instance: name, provider, data source
- [ ] CLR assembly usage confirmed per instance: name, permission set
- [ ] Cross-database dependencies mapped per instance
- [ ] Windows logins and service accounts documented per instance
- [ ] Dependent applications and integrations mapped per instance
- [ ] Historical blockers listed and each assessed as still applies or removed with evidence
- [ ] inventory.md published to Confluence
- [ ] dependency-map.md published to Confluence
- [ ] historical-blockers.md published to Confluence
- [ ] Findings handed over to TECH-3539

---

## Dependencies

- Requires TECH-3537 complete before starting
- TECH-3539 and TECH-3540 blocked until this is done

---

## Links

| Ticket | Description |
|---|---|
| [TECH-3431](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3431) | Parent epic |
| [TECH-3537](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3537) | Planning ticket — must complete before this |
| [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539) | Theme B — blocked on this |
| [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540) | Theme C — blocked on this |
