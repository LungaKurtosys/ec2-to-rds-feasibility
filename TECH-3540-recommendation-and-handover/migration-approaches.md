# Migration Approaches
# [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540)

> **Status:** In Progress — updated 2026-07-24 with confirmed PRD findings
> **Last Updated:** 2026-07-24

---

## Recommended Approach — Native Backup / Restore

For the 18 clean databases, native backup/restore is the recommended approach. It is well understood, low complexity, and does not require any additional tooling.

**How it works:** Take a full backup of each database on EC2, upload to S3, restore into RDS. RDS supports native SQL Server backup/restore directly from S3 using the `rds_restore_database` stored procedure.

**Estimated downtime per database:** Depends on size. Largest databases on PRD:

| Database | Size | Estimated Backup/Restore Time |
|---|---|---|
| KSDK_157_DocProd | 296 GB | 2–4 hours |
| TROWEPRICE | 122 GB | 1–2 hours |
| JUPITER | 106 GB | 1–2 hours |
| INVESTECFACTSHEETS | 65 GB | 45–90 mins |
| ASI | 57 GB | 45–90 mins |
| SSISDB | 53 GB | 45–90 mins |
| Remaining 14 databases | ~104 GB combined | 1–2 hours total |
| **Total** | **~803 GB** | **~10–15 hours total** |

Databases can be migrated in parallel across multiple maintenance windows — not all at once.

---

## Alternative Approach — AWS DMS

AWS Database Migration Service (DMS) replicates data continuously from EC2 to RDS, allowing a near-zero downtime cutover. The application keeps running on EC2 while DMS syncs changes to RDS in the background. At cutover, the application connection string is switched to RDS.

**Viable:** Yes — but higher complexity and cost. Recommended only if downtime tolerance is very low (less than 30 minutes).

**Complexity:** High — requires DMS replication instance, endpoint configuration, and ongoing monitoring during replication.

---

## Approach Not Viable — EC2 Snapshot to RDS

EC2 snapshots cannot be directly converted to RDS instances. This approach is not viable.

---

## Candidate Approaches Summary

| Approach | Estimated Downtime | Complexity | Viable | Recommended |
|---|---|---|---|---|
| Native backup/restore to S3 | Hours per database — schedule per maintenance window | Low | ✅ Yes | ✅ Yes — recommended for Phase 2 |
| AWS DMS continuous replication | Minutes — near zero downtime cutover | High | ✅ Yes | Only if downtime tolerance < 30 mins |
| EC2 snapshot to RDS | N/A | N/A | ❌ No | No |

---

## Notes

- No migration is executed as part of this epic — approaches documented for recommendation only
- SECURITYBENEFIT and RWC are excluded from Phase 2 until CLR blocker is resolved
- SSRS must be relocated before any migration begins — Phase 1 prerequisite
- Database Mail must be replaced before cutover — Phase 1 prerequisite
