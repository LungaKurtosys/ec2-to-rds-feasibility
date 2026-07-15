# Migration Approaches
# [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540)

> **Status:** To Do — blocked on TECH-3538 and TECH-3539 completing first

---

## Candidate Approaches

| Approach | Description | Estimated Downtime | Complexity | Viable |
|---|---|---|---|---|
| Native backup/restore | Back up from EC2, restore into RDS | Hours — depends on database size | Low | TBC |
| AWS DMS | Continuous replication with minimal cutover window | Minutes — near zero downtime | High | TBC |
| Snapshot and restore | EC2 snapshot converted to RDS-compatible format | Hours | Medium | TBC |

---

## Notes

- No approach is executed as part of this epic — documented for recommendation only
- Viability column will be completed after TECH-3539 compatibility findings are available
- Downtime estimates will be refined once database sizes are confirmed in TECH-3538
