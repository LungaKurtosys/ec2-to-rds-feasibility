# EC2 to RDS Feasibility — SQL Server Migration Evaluation [2026]

> **Epic:** Evaluate migrating SQL Server from self-managed EC2 to Amazon RDS — feasibility assessment only.
> **Status:** In Progress — Planning & Discovery

This epic delivers a go/no-go recommendation only. No migration execution, no pilot cutover, no production instance moves.

---

## Repository Structure

```
ec2-to-rds-feasibility/
│
│   README.md                                        ← This file
│
├── TECH-3537-planning-and-discovery/                ← Planning & Discovery
│   │   planning-summary.md                          ← Master planning doc
│   │   discovery-queries.sql                        ← SQL queries for EC2 inventory
│   │   open-questions.md                            ← Blockers and open items
│
├── TECH-3538-inventory-and-dependency/              ← Theme A
│   │   inventory.md                                 ← EC2 instance inventory
│   │   dependency-map.md                            ← Dependent applications per instance
│   │   historical-blockers.md                       ← Blocker reassessment
│
├── TECH-3539-rds-compatibility-and-cost/            ← Theme B
│   │   compatibility-matrix.md                      ← Feature compatibility analysis
│   │   cost-comparison.md                           ← RDS vs EC2 cost model
│   │   licensing-analysis.md                        ← License Included vs BYOL
│
└── TECH-3540-recommendation-and-handover/           ← Theme C
        migration-approaches.md                      ← Candidate approaches + downtime
        risk-register.md                             ← Risks and mitigations
        go-no-go-recommendation.md                   ← Final recommendation
```

---

## Child Tickets

| Ticket | Title | Status |
|---|---|---|
| [TECH-3537](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3537) | Investigation and Discovery Planning | In Progress |
| [TECH-3538](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3538) | Theme A — Inventory and Dependency Reassessment | To Do |
| [TECH-3539](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3539) | Theme B — RDS Compatibility and Cost Analysis | To Do |
| [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540) | Theme C — Recommendation and Handover | To Do |
