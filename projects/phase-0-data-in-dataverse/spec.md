# Phase 0: Data in Dataverse — Spec

> **Project**: `phase-0-data-in-dataverse`
> **Parent Design**: [`spaarke/projects/spaarke-demo-data-setup-r1/design.md`](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md) — Section 12, Phase 0
> **Repository**: `spaarke-data-cli`
> **Timeline**: 3-5 days
> **Phase Dependencies**: None (this is the foundation phase)

---

## 1. Executive Summary

Get the first complete demo scenario ("Meridian Corp v. Pinnacle Industries" — active patent litigation) loaded into the Spaarke dev environment (`https://spaarkedev1.crm.dynamics.com`). This phase uses no CLI infrastructure — just Claude Code for data generation and PowerShell scripts (reusing existing product repo patterns) for loading via Dataverse Web API and BFF API.

The purpose is twofold: (1) populate the dev environment with realistic demo data immediately, and (2) validate the scenario design, entity relationships, and loading process before investing in CLI tooling (Phase 1).

---

## 2. Scope

### In Scope

- Design and generate structured JSON data for all 5 data layers of Scenario 1 (Meridian v. Pinnacle)
- Create idempotent PowerShell loading scripts using Dataverse Web API
- Upload 20-30 actual document files to SPE via BFF API
- Pre-bake AI enrichment fields (summary, keywords, entities, classification) on document records
- Create activity records (events, communications, billing events, KPI assessments) linked to core entities
- Validate loaded data in Dataverse UI
- Document data provenance for any open datasets used (CUAD contracts)

### Out of Scope

- CLI tool infrastructure (Phase 1)
- Scenarios 2-5 (Phase 2)
- Customer onboarding features (Phase 3)
- AI Search index population (Phase 2)
- Automated validation tooling (Phase 1-2)
- npm packaging or CI/CD (Phase 3)

---

## 3. Requirements

### 3.1 Scenario 1 Data Design

Generate structured JSON files for the "Meridian Corp v. Pinnacle Industries" scenario with these entity volumes:

| Entity | Count | Key Details |
|--------|-------|-------------|
| `account` | 4 | Meridian Corp (client), Pinnacle Industries (opposing), 2 law firms |
| `contact` | 12 | Attorneys (4), paralegals (2), expert witnesses (2), judges (1), client contacts (3) |
| `sprk_matter` | 1 | Active litigation, opened ~6 months ago, patent infringement |
| `sprk_project` | 3 | Discovery, Expert Analysis, Trial Prep |
| `sprk_budget` | 1 | $500K litigation budget |
| `sprk_invoice` | 8-12 | Monthly outside counsel invoices from both law firms |
| `sprk_document` | 50-80 | Contracts, discovery docs, pleadings, expert reports, correspondence, memos |
| `sprk_event` | 40-60 | Filing deadlines, deposition dates, discovery cutoffs, review tasks |
| `sprk_communication` | 30-40 | Attorney-client emails, opposing counsel correspondence |
| `sprk_kpiassessment` | 6 | Guidelines compliance, budget adherence, outcome probability |
| `sprk_workassignment` | 5-8 | Paralegal tasks, attorney review assignments |
| Billing events | 50-80 | Invoice line items with timekeeper rates and hours |
| Spend snapshots | 6 | Monthly budget utilization snapshots |

**Total**: ~220-350 Dataverse records + 20-30 actual files

### 3.2 Data Generation Requirements

1. **Coherent narrative**: All data must tell a consistent story — dates align, amounts sum correctly, references are valid
2. **Temporal depth**: Events span 6 months with realistic progression (past events completed, future events pending)
3. **AI enrichment pre-baked**: Every `sprk_document` record must have `sprk_filesummary`, `sprk_filetldr`, `sprk_keywords`, `sprk_documenttype`, and `sprk_entities` populated
4. **Alternate keys**: Use deterministic identifiers (e.g., `mvp-matter-001`, `mvp-acct-meridian`) instead of hardcoded GUIDs for cross-entity references
5. **Realistic names and amounts**: Law firm names, attorney names, invoice amounts, and budget figures should be plausible
6. **Email format**: Communications use `@example.com` domain per RFC 2606

### 3.3 Document Files

Generate or source 20-30 actual files for SPE upload:

| Type | Count | Source | Format |
|------|-------|--------|--------|
| Commercial contracts | 5-8 | CUAD dataset (renamed parties) | PDF |
| NDAs | 2-3 | Synthetic from templates | PDF/DOCX |
| Pleadings/motions | 3-4 | Synthetic (AI-generated) | PDF |
| Expert reports | 2-3 | Synthetic (AI-generated) | DOCX |
| Email correspondence | 5-8 | Synthetic (AI-generated) | EML |
| Internal memos | 2-3 | Synthetic (AI-generated) | DOCX |
| Invoices | 3-4 | Synthetic from templates | PDF |

### 3.4 Loading Requirements

1. **Idempotent**: All loading scripts must be re-runnable without creating duplicates (upsert via alternate keys)
2. **Dependency order**: Load in layer order — reference data first, then core records, then documents, then files, then activities
3. **Authentication**: Use `az account get-access-token --resource https://spaarkedev1.crm.dynamics.com` for bearer tokens (existing pattern from product repo)
4. **Error handling**: Scripts must report failures clearly and continue with remaining records where possible
5. **SPE file upload**: Use BFF API endpoints (`PUT /api/drives/{driveId}/upload`), then patch `sprk_document` records with `graphitemid` and `graphdriveid`

### 3.5 Validation Requirements

After loading, verify:

1. All expected record counts match (query each entity)
2. Lookup relationships resolve (matters link to accounts, documents link to matters, events link to regarding records)
3. Document records have non-null AI enrichment fields
4. SPE files are accessible via the BFF API
5. Data renders correctly on Dataverse forms (manual spot-check)

---

## 4. Technical Approach

### 4.1 Data Generation

Use Claude Code interactively in the `spaarke-data-cli` repo to generate JSON files:

```
output/
├── scenario-1-meridian/
│   ├── accounts.json
│   ├── contacts.json
│   ├── matters.json
│   ├── projects.json
│   ├── budgets.json
│   ├── invoices.json
│   ├── documents.json          # sprk_document records with AI enrichment
│   ├── events.json
│   ├── communications.json
│   ├── kpi-assessments.json
│   ├── work-assignments.json
│   ├── billing-events.json
│   └── spend-snapshots.json
```

Each JSON file contains an array of records with field names matching Dataverse Web API format (logical names).

### 4.2 Loading Scripts

PowerShell scripts in `scripts/phase0/`:

| Script | Purpose | Pattern Source |
|--------|---------|---------------|
| `Invoke-DataverseApi.ps1` | Reusable Web API helper (borrowed from product repo pattern) | `spaarke/projects/ai-spaarke-platform-enhancements-r1/scripts/Invoke-DataverseApi.ps1` |
| `Load-CoreRecords.ps1` | Loads Layer 1-2 records in dependency order | Follows existing seed script patterns |
| `Load-DocumentRecords.ps1` | Loads Layer 3 `sprk_document` records | Same pattern |
| `Upload-SpeFiles.ps1` | Uploads files to SPE via BFF API, patches document records | New but uses BFF API patterns |
| `Load-ActivityRecords.ps1` | Loads Layer 5 events, communications, billing | Same pattern |
| `Load-AllScenario1.ps1` | Orchestrator — runs all scripts in order | New |
| `Remove-Scenario1Data.ps1` | Deletes all Scenario 1 data (reverse order) for re-loading | New |

### 4.3 Document Sourcing

1. **CUAD contracts**: Download 5-8 contracts from the CUAD dataset. Rename party references to match scenario entities (Meridian Corp, Pinnacle Industries). These are real annotated contracts — excellent for document analysis demos.
2. **Synthetic documents**: Use Claude Code to generate markdown content for memos, reports, pleadings, and emails. Convert to final format using pandoc (markdown → DOCX) or direct text generation (EML).
3. **Invoice templates**: Create XLSX or PDF invoice templates with realistic line items.

Files stored in `output/scenario-1-meridian/files/`.

### 4.4 AI Enrichment Pre-Baking

For each document, generate these fields alongside the content:

| Field | Example |
|-------|---------|
| `sprk_filesummary` | "Master Services Agreement between Meridian Corp and Pinnacle Industries dated March 15, 2025. Covers technology licensing, support services, and IP ownership. Key provisions include..." |
| `sprk_filetldr` | "MSA for technology licensing between Meridian and Pinnacle, $2.4M annual value" |
| `sprk_keywords` | "master services agreement, technology licensing, intellectual property, indemnification, limitation of liability" |
| `sprk_documenttype` | 100000001 (Contract) |
| `sprk_entities` | `{"organizations":["Meridian Corp","Pinnacle Industries"],"people":["James Morrison","Sarah Chen"],"dates":["2025-03-15","2026-03-14"],"amounts":["$2,400,000"]}` |

---

## 5. Success Criteria

| Criterion | Measurement |
|-----------|-------------|
| **Data loaded** | All ~220-350 records present in Dataverse dev environment |
| **Files accessible** | 20-30 files viewable through BFF API / SPE |
| **Coherent story** | Opening Matter form shows related projects, documents, events, invoices — all making narrative sense |
| **AI fields populated** | Document records show summaries, keywords, entities in forms/grids |
| **Idempotent** | Running `Load-AllScenario1.ps1` twice produces no duplicates |
| **Resetable** | Running `Remove-Scenario1Data.ps1` then `Load-AllScenario1.ps1` restores clean state |
| **Documented** | DATA-PROVENANCE.md tracks all CUAD files used with license info |

---

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Entity schema assumptions wrong | JSON field names don't match actual Dataverse schema | Export current schema from dev environment first; validate field names before generating data |
| SPE container provisioning requires setup | Can't upload files if containers don't exist | Use BFF API's existing container management (it creates containers for matters) |
| CUAD party name replacement breaks formatting | Renamed contracts look unnatural | Only replace in metadata, not in original PDF content; use CUAD PDFs as-is for file content |
| Alternate key support varies by entity | Some entities may not have alternate keys configured | Fall back to deterministic GUID generation (hash-based) for those entities |
| Bearer token expires mid-load | Script fails partway through | Add token refresh logic or keep script execution fast (batch operations) |

---

## 7. Deliverables

1. `output/scenario-1-meridian/` — JSON data files for all entities
2. `output/scenario-1-meridian/files/` — 20-30 document files (PDF, DOCX, EML)
3. `scripts/phase0/` — PowerShell loading scripts (6 scripts)
4. `docs/DATA-PROVENANCE.md` — Data source licensing documentation
5. Loaded data in `https://spaarkedev1.crm.dynamics.com` — verified and demo-ready

---

## 8. Constraints

- **No CLI infrastructure**: This phase uses PowerShell scripts only — no TypeScript pipeline, no Commander.js commands
- **Single scenario only**: Meridian v. Pinnacle only — other scenarios deferred to Phase 2
- **Dev environment only**: All loading targets `https://spaarkedev1.crm.dynamics.com`
- **No AI Search indexing**: Search index population deferred to Phase 2
- **Pre-baked AI only**: No live AI pipeline execution — all AI fields generated alongside content
- **Existing auth patterns**: Use `az account get-access-token` — no new auth infrastructure
