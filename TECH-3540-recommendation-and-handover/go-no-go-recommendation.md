# Theme C — Recommendation and Handover
# [TECH-3540](https://kurtosys-prod-eng.atlassian.net/jira/software/c/projects/TECH/boards/795?selectedIssue=TECH-3540)

> **Status:** To Do — blocked on TECH-3538 and TECH-3539 completing first

---

## Purpose

Using the findings from Theme A (TECH-3538) and Theme B (TECH-3539), produce the final go/no-go recommendation on whether migrating SQL Server from EC2 to Amazon RDS is viable. This ticket closes the feasibility assessment. No migration is executed here — this is the decision point only.

---

## Background

TECH-3538 produced the full inventory of EC2 instances, dependency map, and historical blocker reassessment. TECH-3539 produced the feature compatibility matrix, licensing comparison, and cost model. This ticket takes both sets of findings and turns them into a single evidence-based recommendation that the manager can sign off on.

---

## This Ticket Delivers

- Candidate migration approaches documented with downtime and cutover implications — native backup/restore and AWS DMS assessed, not executed
- Risk register with mitigation notes covering every risk identified across Theme A and Theme B
- Go/no-go recommendation written with evidence from both themes
- Phased migration outline for a follow-on epic if the recommendation is go
- Manager sign-off to close the feasibility assessment

---

## Candidate Migration Approaches

For each approach, document what it involves, estimated downtime, complexity, and whether it is viable given the compatibility findings from TECH-3539:

| Approach | Description | Estimated Downtime | Complexity | Viable |
|---|---|---|---|---|
| Native backup/restore | Back up from EC2, restore into RDS | Hours — depends on database size | Low | TBC |
| AWS DMS | Continuous replication with minimal cutover window | Minutes — near zero downtime | High | TBC |
| Snapshot and restore | EC2 snapshot converted to RDS-compatible format | Hours | Medium | TBC |

---

## Risk Register Scope

Every risk identified across Theme A and Theme B documented with likelihood, impact, and mitigation:

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Hidden feature dependency not supported on RDS | TBC | High | Full compatibility matrix from TECH-3539 |
| Licensing cost higher than expected | TBC | Medium | BYOL vs License Included comparison from TECH-3539 |
| Scope creep into execution | Low | High | Explicit out-of-scope list enforced at epic level |
| Application downtime during cutover exceeds tolerance | TBC | High | Downtime assessment per approach from this ticket |
| Historical blocker still applies after platform changes | TBC | High | Evidence-based reassessment from TECH-3538 |

---

## Go/No-Go Recommendation Basis

The recommendation will be based on:

- Compatibility blockers from TECH-3539 — are they resolvable or hard blockers?
- Cost comparison outcome — is RDS cheaper, comparable, or more expensive than EC2?
- Historical blockers from TECH-3538 — removed or still active?
- Risk profile — low, medium, or high overall?

---

## Definition of Done

- [ ] Candidate migration approaches documented with downtime and cutover implications
- [ ] Risk register completed with likelihood, impact, and mitigation per risk
- [ ] Go/no-go recommendation written with evidence from TECH-3538 and TECH-3539
- [ ] Phased migration outline written for follow-on epic if recommendation is go
- [ ] migration-approaches.md published to Confluence
- [ ] risk-register.md published to Confluence
- [ ] go-no-go-recommendation.md published to Confluence
- [ ] Manager sign-off obtained
- [ ] Epic TECH-3431 closure comment written with go-forward recommendation

---

## Dependencies

- Requires TECH-3538 and TECH-3539 both complete before starting
- Cannot make a recommendation without the full inventory and compatibility findings

---

## Links

- Parent epic: TECH-3431
- Planning ticket: TECH-3537
- Theme A — must complete before this: TECH-3538
- Theme B — must complete before this: TECH-3539
