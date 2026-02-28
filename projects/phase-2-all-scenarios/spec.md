# Phase 2: All Scenarios + Real Content — Spec

> **Project**: `phase-2-all-scenarios`
> **Parent Design**: [`spaarke/projects/spaarke-demo-data-setup-r1/design.md`](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md) — Section 12, Phase 2
> **Repository**: `spaarke-data-cli`
> **Timeline**: 2-3 weeks
> **Phase Dependencies**: Phase 1 (CLI generate/load/reset commands working for Scenario 1)

---

## 1. Executive Summary

Scale from one demo scenario to all five, integrate real open legal datasets (CUAD contracts, Caselaw Access court opinions), populate AI Search indexes, and add a full validation suite. After this phase, running `spaarke-data generate --scenario all && spaarke-data load --target dev` produces a complete, demo-ready environment with 400-550 documents across 5 interconnected legal stories.

---

## 2. Scope

### In Scope

- Define and implement Scenarios 2-5 as YAML scenario files
- Implement cross-scenario shared entities (`_shared-entities.yaml`)
- Build CUAD source adapter — parse CUAD contracts, rename parties per scenario config
- Build Caselaw source adapter — Caselaw Access Project API client for court opinions
- Pre-bake AI enrichment for all documents across all scenarios
- Implement AI Search index seeder (`load --layer search-index`)
- Implement CMT loader as alternative bulk loading method (optional but valuable for full reloads)
- Build `validate` command with full validation suite (counts + relationships + field completeness)
- Create DATA-PROVENANCE.md with complete licensing documentation
- Create per-scenario demo walkthrough guides
- Volume control: `--volume light` (~100 docs) vs. `--volume full` (~500 docs)

### Out of Scope

- Customer onboarding features (Phase 3)
- CSV/Excel source adapters (Phase 3)
- OpenClaw browser automation adapter (Phase 3)
- Claude Computer Use validation (Phase 3)
- npm global package publishing (Phase 3)
- CI/CD pipeline (Phase 3)
- `schema diff` command (Phase 3)

---

## 3. Requirements

### 3.1 Scenario Definitions

Implement all 5 scenarios from design.md Section 5:

| # | Scenario | Type | Entities | Documents | Key Demo Features |
|---|----------|------|----------|-----------|-------------------|
| 1 | Meridian v. Pinnacle | Litigation | ~85 | 50-80 | *Already implemented in Phase 1* |
| 2 | Atlas/Horizon Acquisition | M&A | ~100 | 120-150 | Bulk document analysis, due diligence Q&A, NDA review |
| 3 | Q1 2026 Compliance Audit | Compliance | ~60 | 60-80 | Knowledge bases, semantic search, risk detection, RAG |
| 4 | Morrison Estate Administration | Estate | ~55 | 40-50 | Task management, email-to-document, communication tracking |
| 5 | Outside Counsel Management | Financial | ~70 | 20-30 invoices | Invoice processing, budget utilization, spend analytics |

**Cross-scenario connections** (from design.md Section 5.7):
- Scenarios 1 & 5: Meridian litigation invoices flow into financial operations
- Scenarios 2 & 5: Atlas acquisition advisory fees tracked in financial operations
- Scenarios 1 & 3: Meridian matter triggers compliance review
- Scenarios 4 & 5: Morrison estate legal fees in financial operations
- All scenarios: Shared contact "Sarah Chen, General Counsel" appears across matters

### 3.2 Shared Entities

`scenarios/_shared-entities.yaml` defines contacts and firms that span multiple scenarios:

```yaml
shared_contacts:
  - id: shared-contact-chen
    name: "Sarah Chen"
    title: "General Counsel"
    scenarios: [meridian-v-pinnacle, atlas-horizon-acquisition, compliance-audit, morrison-estate, outside-counsel-management]

  - id: shared-contact-williams
    name: "David Williams"
    title: "Chief Financial Officer"
    scenarios: [atlas-horizon-acquisition, outside-counsel-management]

shared_firms:
  - id: shared-firm-baker
    name: "Baker & Associates LLP"
    type: "Law Firm"
    scenarios: [meridian-v-pinnacle, outside-counsel-management]
  # ...
```

The `generate` command must resolve shared entity references and avoid creating duplicates across scenarios.

### 3.3 CUAD Source Adapter

Parse and integrate contracts from the CUAD dataset:

**Input**: CUAD dataset files (downloaded to `sources/cuad/`)
**Processing**:
1. Parse CUAD's annotation CSV to identify contract types, parties, key clauses
2. Select contracts matching scenario needs (commercial, NDA, employment, etc.)
3. Rename party references in metadata (not in original PDF content) to match scenario entities
4. Generate AI enrichment fields from actual contract content
5. Map to `sprk_document` records with source attribution

**Output**: `sprk_document` JSON records + original PDF files ready for SPE upload

**Selection criteria per scenario**:
| Scenario | CUAD Contract Types | Count |
|----------|--------------------|----|
| Meridian v. Pinnacle | License agreements, IP agreements | 5-8 |
| Atlas/Horizon Acquisition | MSAs, service agreements, vendor contracts | 15-25 |
| Compliance Audit | Employment agreements, privacy policies | 8-12 |
| Morrison Estate | Trust agreements, property contracts | 3-5 |
| Outside Counsel Management | Engagement letters, fee agreements | 5-8 |

### 3.4 Caselaw Source Adapter

Retrieve court opinions from the Caselaw Access Project API:

**API**: `https://api.case.law/v1/cases/`
**Authentication**: API key (free tier: 500 cases/day)
**Processing**:
1. Query for cases matching scenario topics (patent infringement, corporate M&A, estate law)
2. Download case text and metadata
3. Convert to document format (PDF via pandoc)
4. Generate AI enrichment fields from case content
5. Map to `sprk_document` records

**Target per scenario**:
| Scenario | Case Types | Count |
|----------|-----------|-------|
| Meridian v. Pinnacle | Patent infringement opinions | 8-12 |
| Compliance Audit | Regulatory enforcement actions | 5-8 |
| Morrison Estate | Estate/probate cases | 3-5 |

### 3.5 AI Search Index Seeder

```bash
spaarke-data load --target dev --layer search-index
```

**Behavior**:
1. Read generated document data from `output/`
2. For each document, create search index entries:
   - Chunk document content into passages (500-1000 tokens each)
   - Generate embedding vectors via Azure OpenAI embedding model
   - Build index documents matching the schema in the Spaarke AI Search configuration
3. Upload to Azure AI Search via REST API (`POST /indexes/{name}/docs/index`)
4. Batch in groups of 1000

**Search index schema**: Match existing index structure from `infrastructure/ai-search/` or `infrastructure/ai-foundry/`.

**Cost consideration**: Embedding generation for 400-500 documents will consume Azure OpenAI tokens. Pre-compute and cache embeddings in `output/search-index/` so re-loading doesn't re-embed.

### 3.6 CMT Loader (Optional)

Alternative to Web API for full-environment reloads:

```bash
spaarke-data load --target dev --method cmt
```

**Behavior**:
1. Convert generated JSON data to CMT format (`schema.xml` + `data.xml`)
2. Package as `data.zip`
3. Import via PAC CLI: `pac data import --data output/data.zip --environment {url}`
4. Fall back to direct CMT executable invocation if `pac data` is unavailable

**When to use**: Full reloads of all 5 scenarios (500+ records) where Web API batch operations are too slow.

### 3.7 Validate Command

```bash
spaarke-data validate --target dev
spaarke-data validate --target dev --scenario meridian-v-pinnacle
spaarke-data validate --target dev --verbose
```

**Validation checks**:

| Check | Description | Severity |
|-------|-------------|----------|
| Record counts | Actual count per entity matches expected from scenario definitions | Error |
| Lookup integrity | All lookup fields resolve to existing records | Error |
| AI enrichment completeness | `sprk_document` records have non-null summary, keywords, entities | Warning |
| File linkage | Documents with `hasfile=true` have valid `graphitemid` + `graphdriveid` | Error |
| Cross-scenario references | Shared contacts exist and are linked correctly | Error |
| Option set values | All option set fields contain valid values from schema | Warning |
| Date coherence | Event dates fall within matter timeline | Warning |
| Financial consistency | Invoice totals align with budget amounts (within tolerance) | Warning |

**Output format**:
```
Validating dev environment...

  Scenario: meridian-v-pinnacle
    ✓ Record counts: 85/85 entities matched
    ✓ Lookup integrity: 342/342 lookups resolved
    ✓ AI enrichment: 78/78 documents enriched
    ✗ File linkage: 2/30 files missing graphitemid
    ✓ Date coherence: all events within timeline

  Scenario: atlas-horizon-acquisition
    ...

Summary: 4 scenarios passed, 1 warning, 1 error
```

### 3.8 Volume Control

```bash
spaarke-data generate --scenario all --volume light    # ~100 docs total
spaarke-data generate --scenario all --volume full     # ~500+ docs total
```

| Volume | Documents | Events | Communications | Use Case |
|--------|-----------|--------|----------------|----------|
| `light` | ~100 total (~20/scenario) | ~80 | ~50 | Quick demo setup, CI testing |
| `full` | ~500+ total (per scenario table) | ~200+ | ~150+ | Full demo, production-like |

Volume presets defined in `config/defaults.yaml`.

---

## 4. Technical Approach

### 4.1 New/Modified Source Files

```
src/
├── adapters/
│   ├── claude-adapter.ts          # UPDATE: support multi-scenario generation
│   ├── cuad-adapter.ts            # NEW: CUAD dataset parser + party renaming
│   └── caselaw-adapter.ts         # NEW: Caselaw Access API client
│
├── loaders/
│   ├── webapi-loader.ts           # UPDATE: batch optimization, cross-scenario dedup
│   ├── spe-loader.ts              # UPDATE: multi-scenario file upload
│   ├── cmt-loader.ts              # NEW: CMT format conversion + PAC CLI import
│   └── search-loader.ts           # NEW: Azure AI Search REST API client
│
├── transforms/
│   ├── entity-transform.ts        # NEW: generic entity field mapping + validation
│   ├── document-transform.ts      # NEW: document record assembly + AI enrichment
│   ├── activity-transform.ts      # NEW: event/communication temporal generation
│   └── search-index-transform.ts  # NEW: document chunking + embedding generation
│
├── validators/
│   ├── count-validator.ts         # UPDATE: multi-scenario support
│   ├── relationship-validator.ts  # UPDATE: cross-scenario shared entity checks
│   └── field-validator.ts         # NEW: AI enrichment + option set validation
│
├── cli/
│   ├── validate.ts                # NEW: validate command handler
│   └── harvest.ts                 # NEW: dataset download command (CUAD, Caselaw)
│
scenarios/
├── meridian-v-pinnacle.yaml       # EXISTS from Phase 1
├── atlas-horizon-acquisition.yaml # NEW
├── compliance-audit.yaml          # NEW
├── morrison-estate.yaml           # NEW
├── outside-counsel-management.yaml# NEW
└── _shared-entities.yaml          # NEW
```

### 4.2 CUAD Integration

```
sources/cuad/                     # gitignored — downloaded by harvest command
├── full_contract_pdf/            # 510 contract PDFs
├── master_clauses.csv            # Clause annotations
└── CUADv1.json                   # Contract metadata
```

The `harvest` command downloads CUAD:
```bash
spaarke-data harvest cuad --output ./sources/cuad/
```

The CUAD adapter reads `CUADv1.json` for metadata, selects contracts by type, and maps them to scenario entities.

### 4.3 Embedding Generation

Use Azure OpenAI `text-embedding-3-large` for search index vectors:

```typescript
async function generateEmbeddings(chunks: string[]): Promise<number[][]> {
  // Call Azure OpenAI embedding endpoint
  // Batch in groups of 16 (API limit)
  // Cache results to output/search-index/embeddings/
}
```

**Cost estimate**: ~$0.02 per 1M tokens. 500 documents at ~2000 tokens each = ~$0.02 total. Negligible.

---

## 5. Success Criteria

| Criterion | Measurement |
|-----------|-------------|
| **All 5 scenarios generate** | `spaarke-data generate --scenario all` completes without errors |
| **All 5 scenarios load** | `spaarke-data load --target dev` loads 1500+ records across all entities |
| **Cross-scenario links work** | Shared contacts appear correctly in multiple matters |
| **CUAD contracts integrated** | 30-50 real contracts from CUAD appear as SPE documents with AI enrichment |
| **Caselaw opinions integrated** | 15-25 court opinions appear as searchable documents |
| **AI Search populated** | Search queries return relevant results from loaded documents |
| **Validation passes** | `spaarke-data validate --target dev` reports all-green |
| **Volume control works** | `--volume light` produces ~100 docs, `--volume full` produces ~500+ |
| **Full reset works** | `spaarke-data reset --target dev --confirm` cleanly wipes and reloads all 5 scenarios |
| **Demo-ready** | All 5 scenarios tell coherent stories navigable through Dataverse forms |

---

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| CUAD download is large (~2GB) | Slow first setup; disk space | Cache in `sources/cuad/` (gitignored); document min requirements |
| Caselaw Access API rate limits | Can't download enough cases in one session | Cache downloaded cases; use bulk download endpoint if available |
| Cross-scenario entity deduplication | Shared contacts created multiple times | Resolve shared entities first, before scenario-specific entities |
| AI Search schema mismatch | Index documents don't match existing search configuration | Export current index schema first; validate before upload |
| Embedding model costs at scale | Unexpected Azure OpenAI charges | Pre-compute and cache; estimate costs before generation |
| CMT schema.xml generation is complex | Import failures due to malformed XML | Start with Web API (proven); CMT as optional optimization |
| 5 scenarios generate inconsistent data | Date conflicts, amount mismatches across scenarios | Cross-scenario validation in `validate` command; shared timeline constraints |

---

## 7. Deliverables

1. **5 scenario YAML files** + shared entities YAML
2. **CUAD source adapter** (`src/adapters/cuad-adapter.ts`)
3. **Caselaw source adapter** (`src/adapters/caselaw-adapter.ts`)
4. **AI Search loader** (`src/loaders/search-loader.ts`)
5. **CMT loader** (`src/loaders/cmt-loader.ts`) — optional
6. **Validate command** (`src/cli/validate.ts` + validators)
7. **Transform layer** (`src/transforms/`)
8. **DATA-PROVENANCE.md** — complete licensing for all data sources
9. **Demo walkthrough guides** — per-scenario presenter scripts in `docs/`
10. **Loaded dev environment** — all 5 scenarios, 400-550 documents, all entity types

---

## 8. Constraints

- **No customer data adapters**: CSV/Excel import deferred to Phase 3
- **No browser automation**: OpenClaw adapter deferred to Phase 3
- **Azure CLI auth only**: No service principal — developer's `az login` session
- **CUAD CC BY 4.0 compliance**: Must attribute Atticus Project; document in DATA-PROVENANCE.md
- **Caselaw Access free tier**: 500 cases/day limit — plan downloads accordingly
- **Dev environment only**: Loading targets `https://spaarkedev1.crm.dynamics.com` exclusively

---

## 9. Inputs from Phase 1

| Phase 1 Output | How Phase 2 Uses It |
|----------------|---------------------|
| `generate` command | Extended with `--scenario all`, `--volume` flag, multi-adapter support |
| `load` command | Extended with `--layer search-index`, `--method cmt` |
| `webapi-loader.ts` | Enhanced for cross-scenario batch loading and deduplication |
| `spe-loader.ts` | Enhanced for multi-scenario file upload |
| `schemas/*.schema.json` | Used by all new adapters for field validation |
| `scenarios/meridian-v-pinnacle.yaml` | Template for Scenarios 2-5 YAML definitions |
| Claude adapter pattern | Reused for activity generation across all scenarios |
