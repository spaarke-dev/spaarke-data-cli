# Phase 0: Data in Dataverse — Task Index

## Status Legend
- 🔲 Pending
- 🔄 In Progress
- ✅ Complete
- ⏭️ Skipped
- 🚫 Blocked

## Task Registry

| # | Task | Phase | Status | Dependencies | Parallel Group |
|---|------|-------|--------|--------------|----------------|
| 001 | Generate Foundation Entities (Accounts, Contacts) | 1 - Data Generation | 🔲 | none | A |
| 002 | Generate Core Business Entities (Matter, Projects, Budgets, Invoices) | 1 - Data Generation | 🔲 | none | A |
| 003 | Generate Document Records with AI Enrichment | 1 - Data Generation | 🔲 | none | A |
| 004 | Generate Activity Entities (Events, Comms, KPIs, Billing) | 1 - Data Generation | 🔲 | none | A |
| 005 | Source CUAD Contracts + Generate Synthetic Files | 2 - File Sourcing | 🔲 | 001-004 | B |
| 006 | Create PowerShell Loading Scripts | 2 - Scripts | 🔲 | 001-004 | B |
| 007 | Load Layers 1-3 (Core Records + Documents) | 3 - Loading | 🔲 | 005, 006 | Sequential |
| 008 | Upload Files to SPE + Link to Documents | 3 - Loading | 🔲 | 007 | Sequential |
| 009 | Load Layer 5 (Activities) + Validate All Data | 3 - Loading | 🔲 | 008 | Sequential |
| 010 | Project Wrap-up — DATA-PROVENANCE + Lessons Learned | 4 - Wrap-up | 🔲 | 009 | Sequential |

## Parallel Execution Groups

| Group | Tasks | Prerequisite | Notes |
|-------|-------|--------------|-------|
| A | 001, 002, 003, 004 | None | Independent JSON generation — all can run simultaneously |
| B | 005, 006 | Group A complete | Files + scripts can run in parallel |
| Sequential | 007 → 008 → 009 → 010 | Group B complete | Loading follows dependency order |

## Dependencies Graph

```
001 ─┐
002 ─┤
003 ─┼──→ 005 ─┐
004 ─┘    006 ─┼──→ 007 ──→ 008 ──→ 009 ──→ 010
               │
               └── (parallel)
```

## Summary
- **Total tasks**: 10
- **Completed**: 0
- **Remaining**: 10
- **Critical path**: Any Group A task → 005/006 → 007 → 008 → 009 → 010
