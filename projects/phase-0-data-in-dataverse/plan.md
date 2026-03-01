# Phase 0: Data in Dataverse — Implementation Plan

## Architecture Context

### Target Environment
- **Dataverse**: `https://spaarkedev1.crm.dynamics.com`
- **BFF API**: `https://spe-api-dev-67e2xz.azurewebsites.net`
- **Authentication**: `az account get-access-token` (Azure CLI)
- **API**: Dataverse Web API v9.2

### Discovered Resources

**Reusable Patterns (from spaarke product repo)**:
- `Invoke-DataverseApi.ps1` — Bearer token auth + Web API helper
- `Create-ActionSeedRecords.ps1` — Idempotent record creation pattern with alternate keys
- `Deploy-All-AI-SeedData.ps1` — Master orchestration with dependency ordering
- `DataverseWebApiService.cs` — Entity field mappings and Web API patterns
- `Models.cs` — Complete entity schema (`sprk_document`, `sprk_event`, etc.)
- `UploadEndpoints.cs` — BFF API file upload (PUT small file, POST upload session)

**Key Entity Schemas**:
- `sprk_document`: documentname, filename, filesize, mimetype, graphitemid, graphdriveid, filesummary, filetldr, keywords, extractorganization, extractpeople, extractfees, extractdates, extractdocumenttype, emailsubject/from/to/cc/date/body, Matter/Project/Invoice lookups
- `sprk_event`: eventname, eventtype, basedate, duedate, priority, source, regarding* (8 polymorphic lookups)
- Standard entities: account, contact (OOB fields)
- Custom: sprk_matter, sprk_project, sprk_invoice, sprk_budget, sprk_communication, sprk_workassignment, sprk_kpiassessment

---

## Phase Breakdown

### Phase 1: Data Design & Generation (Tasks 001-004)

**Objective**: Generate complete JSON data files for all entities in Scenario 1.

| Task | Deliverable | Parallelizable |
|------|-------------|----------------|
| 001 | Generate foundation entities JSON (accounts, contacts) | Yes (Group A) |
| 002 | Generate core business entities JSON (matter, projects, budgets, invoices, work assignments) | Yes (Group A) |
| 003 | Generate document records JSON with AI enrichment fields | Yes (Group A) |
| 004 | Generate activity entities JSON (events, communications, KPIs, billing events, spend snapshots) | Yes (Group A) |

All four tasks can run in parallel — they produce independent JSON files. Cross-entity references use deterministic IDs (e.g., `mvp-acct-meridian`, `mvp-matter-001`).

### Phase 2: Document File Sourcing (Tasks 005-006)

**Objective**: Create/source actual document files for SPE upload.

| Task | Deliverable | Parallelizable |
|------|-------------|----------------|
| 005 | Source CUAD contracts + generate synthetic documents (memos, pleadings, emails, invoices) | Yes (Group B) |
| 006 | Create PowerShell loading scripts (Invoke-DataverseApi helper, per-layer loaders, orchestrator) | Yes (Group B) |

Tasks 005 and 006 can run in parallel — scripts and files are independent artifacts.

### Phase 3: Loading & Validation (Tasks 007-009)

**Objective**: Load all data into dev environment and validate.

| Task | Deliverable | Sequential |
|------|-------------|------------|
| 007 | Load Layers 1-3 into Dataverse (accounts → contacts → matter → projects → budgets → invoices → documents) | Sequential |
| 008 | Upload files to SPE via BFF API, patch document records with storage references | After 007 |
| 009 | Load Layer 5 (events, communications, KPIs, billing, spend snapshots) + validate all data | After 008 |

These tasks are sequential — each depends on the previous layer being loaded.

### Phase 4: Wrap-up (Task 010)

| Task | Deliverable |
|------|-------------|
| 010 | DATA-PROVENANCE.md, project wrap-up, lessons learned |

---

## Parallel Execution Groups

| Group | Tasks | Prerequisite | Notes |
|-------|-------|--------------|-------|
| A | 001, 002, 003, 004 | None | Independent JSON generation — all can run simultaneously |
| B | 005, 006 | Group A complete | Files + scripts can run in parallel |
| Sequential | 007 → 008 → 009 | Group B complete | Loading must follow dependency order |
| Final | 010 | 009 complete | Wrap-up |

## Dependencies Graph

```
001 ─┐
002 ─┤
003 ─┼──→ 005 ─┐
004 ─┘    006 ─┼──→ 007 ──→ 008 ──→ 009 ──→ 010
               │
               └── (parallel)
```

## Output Structure

```
output/
└── scenario-1-meridian/
    ├── accounts.json
    ├── contacts.json
    ├── matters.json
    ├── projects.json
    ├── budgets.json
    ├── invoices.json
    ├── documents.json
    ├── events.json
    ├── communications.json
    ├── kpi-assessments.json
    ├── work-assignments.json
    ├── billing-events.json
    ├── spend-snapshots.json
    └── files/
        ├── contracts/          # CUAD PDFs
        ├── pleadings/          # Synthetic PDFs
        ├── memos/              # Synthetic DOCX
        ├── emails/             # Synthetic EML
        └── invoices/           # Synthetic PDFs

scripts/phase0/
├── Invoke-DataverseApi.ps1
├── Load-CoreRecords.ps1
├── Load-DocumentRecords.ps1
├── Upload-SpeFiles.ps1
├── Load-ActivityRecords.ps1
├── Load-AllScenario1.ps1
└── Remove-Scenario1Data.ps1
```
