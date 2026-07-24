# Risk Register
# [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540)

> **Status:** In Progress — updated 2026-07-24 with confirmed PRD findings
> **Last Updated:** 2026-07-24

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| UNSAFE CLR assemblies in SECURITYBENEFIT and RWC block migration of those 2 databases | Confirmed — already happened | High | Rewrite SHA1StringFunction as T-SQL HASHBYTES (low effort). Rewrite EmailReportNotifications using SES (medium effort). Or leave both databases on EC2 permanently. |
| SSRS not moved off instance before migration begins | Medium — easy to overlook | High | Phase 1 of migration plan explicitly requires SSRS relocation before any database moves |
| Database Mail not replaced before migration | Medium | Medium | Replace with Amazon SES/SNS in Phase 1. Profile and account details confirmed — dba profile, dba@kurtosys.com. |
| ew2p-mssql-01 cost drop (Oct/Nov 2025) not explained — cost saving may be overstated | Medium | Medium | Confirm current instance state before presenting cost case to management |
| AWS License Mobility not formally activated for RDS | Low — BYOL confirmed, activation is administrative only | Medium | Raise with manager — initiate activation before migration begins |
| SSISDB present but usage not confirmed | Low | Medium | Confirm with application team whether SSIS packages are actively running before decommissioning EC2 |
| Application downtime during cutover exceeds tolerance | Low — native backup/restore is well understood | High | Use native backup/restore for Phase 2. For zero-downtime option, assess AWS DMS. Schedule cutover in maintenance window. |
| Collation mismatch at RDS provisioning | Low — collation confirmed | Low | Set Latin1_General_CI_AS at RDS instance creation. Document ReportServer and SSISDB collations separately. |
| Scope creep into execution | Low | High | This epic is feasibility only — no migration executed here. Follow-on epic required for execution. |
