# Theme A — SQL Server EC2 Inventory and Dependency Reassessment
# [TECH-3538](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3538)

> **Status:** To Do — blocked on TECH-3537 completing first

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

| Hostname | Region | Environment | SQL Server Version | Edition | Instance Type | Storage (GB) | Workload Profile |
|---|---|---|---|---|---|---|---|
| TBC | TBC | TBC | TBC | TBC | TBC | TBC | TBC |

---

## Database Inventory

| Instance | Database | Size (MB) | Recovery Model | Compatibility Level | Collation |
|---|---|---|---|---|---|
| TBC | TBC | TBC | TBC | TBC | TBC |

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

- [ ] All SQL Server EC2 instances catalogued: hostname, region, environment, version, edition, instance type, storage size, workload profile
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
