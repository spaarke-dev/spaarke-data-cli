# Demo Environment Setup — Design Document

> **Author**: Ralph Schroeder
> **Date**: April 6, 2026
> **Status**: Draft
> **Repository**: `spaarke-data-cli` — `C:\code_files\SPAARKE-DATA-CLI`
> **Parent Design**: [`spaarke/projects/spaarke-demo-data-setup-r1/design.md`](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md)

---

## 1. Executive Summary

This project creates a **fully automated, Claude Code-executable pipeline** that populates a Spaarke development or demo environment with realistic, comprehensive legal industry data. The pipeline covers all five data layers: Dataverse records, SharePoint Embedded files, Azure AI Search indexes, AI enrichment fields, and transactional activity data.

The key differentiator from Phase 0 (which manually ran individual scripts) is **end-to-end automation with full entity completeness**. Every matter has financial metrics, performance assessments, active events, related documents, and indexed search content. Every document exists as a real file in SPE and is discoverable via semantic search.

### 1.1 Goals

| Goal | Measure |
|------|---------|
| **Realistic data** | Demo data tells coherent legal stories — names, dates, amounts, and documents are plausible |
| **Complete entities** | Every entity record has all relationship fields populated (no orphaned records, no empty grids) |
| **Full stack coverage** | Dataverse records + SPE files + AI Search index + AI enrichment — all populated |
| **Automated execution** | Claude Code can run the entire pipeline with a single orchestration command |
| **Idempotent & resetable** | Re-runnable without duplicates; can tear down and rebuild cleanly |
| **Leverages existing tools** | Reuses product repo scripts, BFF API endpoints, and seed data patterns |

### 1.2 What "Complete" Means

A matter in the demo environment should look like a matter a real user would see:

- **Matter record** with name, number, description, status, type, open date, related account
- **Projects** (2-3) linked to the matter with status and timeline
- **Budget** with allocated amount and budget buckets by cost type
- **Invoices** (6-12) from outside counsel with line items, amounts, dates
- **Billing events** tied to invoices showing fee/expense breakdowns by timekeeper role
- **Spend snapshots** showing monthly budget utilization trends (MoM velocity)
- **KPI assessments** with grades (A+ through F) across performance areas
- **Events** (20-40) — filing deadlines, depositions, review tasks — with status progression (completed, open, pending)
- **Documents** (30-60) — contracts, pleadings, memos, emails, invoices, expert reports — each with:
  - AI profile fields populated (summary, TL;DR, keywords, document type, extracted entities)
  - Actual file in SharePoint Embedded
  - Chunks indexed in Azure AI Search (knowledge + discovery indexes)
  - Record association lookups (linked to matter, project, or invoice)
- **Communications** (15-25) — email threads between attorneys, clients, opposing counsel
- **Work assignments** linked to matter/project with assignees and status

---

## 2. Architecture

### 2.1 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR                              │
│         scripts/setup/Setup-DemoEnvironment.ps1             │
│                                                             │
│  Params: -EnvironmentUrl -BffApiUrl -Scenario -DryRun      │
└───────┬─────────┬──────────┬──────────┬──────────┬──────────┘
        │         │          │          │          │
   ┌────▼───┐ ┌──▼────┐ ┌───▼───┐ ┌───▼───┐ ┌───▼────┐
   │Layer 1 │ │Layer 2│ │Layer 3│ │Layer 4│ │Layer 5 │
   │Ref/Cfg │ │Core   │ │Docs   │ │Files  │ │Activity│
   │        │ │Biz    │ │Records│ │(SPE)  │ │Records │
   └───┬────┘ └──┬────┘ └───┬───┘ └───┬───┘ └───┬────┘
       │         │          │         │          │
       │         │          │    ┌────▼────┐     │
       │         │          │    │AI Search│     │
       │         │          │    │Indexing  │     │
       │         │          │    └─────────┘     │
       ▼         ▼          ▼         ▼          ▼
   ┌─────────────────────────────────────────────────┐
   │              VALIDATION                          │
   │  Verify counts, relationships, files, search     │
   └─────────────────────────────────────────────────┘
```

### 2.2 Target Environment — Demo

| Component | Value | Notes |
|-----------|-------|-------|
| **Dataverse** | `https://spaarke-demo.crm.dynamics.com` | Environment ID: `6d3ab55e-8d8f-e798-94af-670a695c1d1b` |
| **BFF API** | `https://spaarke-bff-demo.azurewebsites.net` | Client ID: `da03fe1a-4b1d-4297-a4ce-4b83cae498a9` |
| **SPE Container** | `b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp` | Per-business-unit container (flat — no internal folder structure) |
| **AI Search** | `https://spaarke-search-demo.search.windows.net` | Resource group: `rg-spaarke-demo` (West US 2). Admin key in Key Vault: `sprk-demo-kv` → secret `ai-search-key` |
| **Azure OpenAI** | `https://spaarke-openai-demo.openai.azure.com` | Deployment: `text-embedding-3-large` (3072 dims). API version: `2023-05-15` |

### 2.3 Authentication

The BFF API uses MSAL with OBO (On-Behalf-Of) flow. Scripts authenticate as follows:

| Target | Auth Method | Details |
|--------|------------|---------|
| **Dataverse Web API** | `az account get-access-token --resource https://spaarke-demo.crm.dynamics.com` | Azure CLI bearer token (existing pattern) |
| **BFF API** | MSAL token with scope `api://da03fe1a-4b1d-4297-a4ce-4b83cae498a9/access_as_user` | Script acquires token via Azure CLI or MSAL ConfidentialClient |
| **SPE (Graph)** | Via BFF API OBO | BFF extracts bearer token → exchanges for Graph token via `GraphClientFactory.ForUserAsync()` |
| **AI Search** | Admin API key from Key Vault (`az keyvault secret show --vault-name sprk-demo-kv --name ai-search-key`) | Direct REST API for index seeding |
| **Azure OpenAI** | API key (provided separately, not committed to repo) | Direct embedding generation for index seeding |

**BFF API token acquisition from PowerShell:**
```powershell
# Option A: Azure CLI (interactive, simplest)
$bffToken = az account get-access-token `
    --resource "api://da03fe1a-4b1d-4297-a4ce-4b83cae498a9" `
    --query 'accessToken' -o tsv

# Option B: MSAL ConfidentialClient (unattended, requires service principal)
# Uses client credentials flow with app registration that has
# knownClientApplications configured for the BFF API
```

**Auth flow for SPE file uploads:**
```
PowerShell script
  → acquires user/app token for BFF API scope
  → calls BFF API with Authorization: Bearer {token}
  → BFF API OBO exchanges for Graph API token
  → BFF API calls SharePoint Embedded via Graph SDK
  → returns graphItemId, driveId to script
```

> **Reference**: See `spaarke/.claude/patterns/auth/obo-flow.md`, `oauth-scopes.md`, and `service-principal.md` for implementation details.

### 2.4 Runtime Secrets

API keys and secrets are **never committed to the repository**. The orchestrator script retrieves them at runtime:

| Secret | Source | Script Usage |
|--------|--------|-------------|
| **Dataverse token** | `az account get-access-token --resource https://spaarke-demo.crm.dynamics.com` | Auto-acquired per session |
| **BFF API token** | `az account get-access-token --resource api://da03fe1a-4b1d-4297-a4ce-4b83cae498a9` | Auto-acquired per session |
| **AI Search admin key** | `az keyvault secret show --vault-name sprk-demo-kv --name ai-search-key --query value -o tsv` | Retrieved once at script start |
| **Azure OpenAI API key** | Environment variable `AZURE_OPENAI_API_KEY` or script parameter `-OpenAiApiKey` | For embedding generation during index seeding |

```powershell
# Example: full automated run with all secrets resolved automatically
az login  # one-time interactive login
$env:AZURE_OPENAI_API_KEY = "..."  # set once per session (or pass as parameter)

./scripts/setup/Setup-DemoEnvironment.ps1 -Scenario "scenario-1-meridian"
# Script auto-resolves: Dataverse token, BFF token, AI Search key from Key Vault
```

---

## 3. Data Design

### 3.1 Scenarios

We start with **Scenario 1** (Meridian v. Pinnacle — active patent litigation) and design the pipeline to support additional scenarios by adding JSON config files.

**Scenario 1: Meridian Corp v. Pinnacle Industries**
- Patent infringement litigation, filed ~8 months ago
- Active discovery phase, trial date set
- Two law firms involved (plaintiff and defendant counsel)
- $500K litigation budget, ~60% utilized
- Multiple expert witnesses, deposition schedule in progress

### 3.2 Entity Volumes (per scenario)

| Layer | Entity | Count | Key Completeness Requirements |
|-------|--------|-------|-------------------------------|
| **1** | Event types | 8-12 | Field config JSON for form customization |
| **1** | AI seed data (playbooks, actions, skills, tools, knowledge) | ~35 | Full scope chain (playbook → skills → actions → tools → knowledge) |
| **2** | Accounts | 4-6 | Name, address, industry, phone, email, account type |
| **2** | Contacts | 12-18 | Full name, email, job title, phone, parent account link |
| **2** | Matters | 1-2 | All fields: name, number, description, status, type, dates, account lookups |
| **2** | Projects | 3-5 | Linked to matter, with status, dates, description |
| **2** | Budgets | 1-2 | Linked to matter, with amount, period, status |
| **2** | Budget buckets | 4-6 | Fee/Expense/Expert/Other breakdowns per budget |
| **2** | Invoices | 8-12 | Linked to matter, with number, amount, date, vendor, line items |
| **2** | Work assignments | 5-8 | Linked to matter/project, with assignee contact, status, dates |
| **3** | Documents | 50-80 | Full AI profile, record association lookups, source type, status |
| **4** | Files (SPE) | 20-30 | Real PDF/DOCX/EML/XLSX files uploaded to SPE containers |
| **4** | Search index entries | 200-400 | Chunked + embedded in knowledge-index-v2 and discovery-index |
| **5** | Events | 40-60 | Typed, with polymorphic regarding lookups, status progression, dates |
| **5** | Event logs | 80-120 | Audit trail for event state changes |
| **5** | Communications | 30-40 | Email threads with direction, regarding matter |
| **5** | KPI assessments | 6-10 | Grades per performance area per matter |
| **5** | Billing events | 50-80 | Line items per invoice with role, hours, rate |
| **5** | Spend snapshots | 6-12 | Monthly budget utilization with MoM velocity |

**Total per scenario**: ~550-900 Dataverse records + 20-30 files + 200-400 search index chunks

### 3.3 Entity Relationship Completeness Map

Every record must have its relationships populated. This is the dependency graph:

```
account ──────────────────────────────────────────┐
  │                                                │
  ├── contact (parent account)                     │
  │     │                                          │
  │     ├── work assignment (assignee)             │
  │     └── communication (sent by)                │
  │                                                │
  └── matter (client account, opposing account) ───┤
        │                                          │
        ├── project (parent matter) ───────────────┤
        │     └── event (regarding project)        │
        │                                          │
        ├── budget (parent matter)                 │
        │     └── budget bucket (parent budget)    │
        │                                          │
        ├── invoice (parent matter)                │
        │     └── billing event (parent invoice)   │
        │                                          │
        ├── document (matter/project/invoice link) │
        │     ├── SPE file (graphitemid/driveid)   │
        │     └── AI Search chunks (parent entity) │
        │                                          │
        ├── event (regarding matter)               │
        │     └── event log (parent event)         │
        │                                          │
        ├── communication (regarding matter)       │
        ├── kpi assessment (parent matter)         │
        └── spend snapshot (parent matter)         │
```

### 3.4 Document Types & File Formats

Documents must look authentic — a mix of PDF and DOCX formats, with realistic multi-page content. **No filler text or lorem ipsum.** Every document contains substantive, scenario-relevant content that a legal professional would recognize as plausible.

| Document Category | Count | File Format | Content Approach |
|-------------------|-------|-------------|-----------------|
| Commercial contracts (MSA, License, NDA) | 5-8 | **PDF** | CUAD-sourced contracts (real legal language); party names in metadata only |
| Pleadings & motions | 3-5 | **PDF** | Synthetic with proper legal formatting: captions, case numbers, argument structure |
| Expert reports | 2-3 | **DOCX** | Synthetic with technical analysis, methodology sections, expert opinions |
| Internal memos | 4-6 | **DOCX** | Synthetic with firm letterhead style: TO/FROM/RE headers, analysis, recommendations |
| Email correspondence | 8-12 | **EML** | Synthetic with RFC 5322 headers, realistic email threads, proper signatures |
| Outside counsel invoices | 3-4 | **PDF** | Synthetic with LEDES-style formatting: timekeeper entries, rates, task codes |
| Court orders | 3-4 | **PDF** | Synthetic with court caption, order number, judge signature block |
| Discovery documents | 2-3 | **PDF/XLSX** | Production logs, privilege logs with realistic entries |

**File generation pipeline:**
- **PDF**: Generate markdown with proper formatting → convert via `pandoc` or similar tool
- **DOCX**: Generate markdown → convert via `pandoc` with reference template for styling
- **EML**: Generate directly with proper MIME structure, headers, and body content

**Total**: 30-45 files, each with:
- Realistic multi-page content (substantive, not stubs or filler)
- Complete `sprk_document` metadata record in Dataverse
- AI enrichment fields pre-populated
- File uploaded to shared SPE container (flat — unique file names per document)
- Content chunked and indexed in AI Search

### 3.5 AI Search Index Population

Each document produces search index entries in two indexes:

**Knowledge Index (`spaarke-knowledge-index-v2`)**:
- Chunked at 2048 chars with 200-char overlap
- Each chunk gets `contentVector3072` embedding (text-embedding-3-large, 3072 dims)
- Document-level `documentVector3072` embedding
- Parent entity scoping (parentEntityType, parentEntityId)
- Tenant isolation (tenantId)

**Discovery Index**:
- Chunked at 4096 chars with 400-char overlap
- Same vector embedding strategy
- Used for document discovery and record matching

**Record Search Index (`spaarke-records-index`)**:
- Dataverse records (matters, projects, invoices, accounts) indexed directly
- Fields: recordName, recordDescription, organizations, people, referenceNumbers, keywords
- Content vector embedding for semantic record search

### 3.6 Financial Data Completeness

Each matter must demonstrate the full financial picture:

| Financial Artifact | Data Points | Calculation Rules |
|--------------------|------------|-------------------|
| **Budget** | $500K total, allocated across 4 buckets (Fees 65%, Expenses 20%, Expert 10%, Other 5%) | Budget buckets sum to budget total |
| **Invoices** | 8-12 invoices spanning 6 months, $5K-$60K each | Invoice amounts sum to ~$300K (60% budget utilization) |
| **Billing events** | 6-15 line items per invoice | Line amounts sum to invoice total |
| **Spend snapshots** | Monthly snapshots showing utilization progression | Each snapshot: invoicedAmount, budgetAmount, variance, variancePct, velocityPct |
| **MoM velocity** | Increasing spend trend (early months lower, recent months higher) | velocityPct = (current - prior) / prior * 100 |

### 3.7 KPI & Performance Metrics

| Performance Area | Grade | Rationale |
|------------------|-------|-----------|
| Budget Adherence | B | 60% utilized at 67% timeline — slightly ahead |
| Billing Guidelines Compliance | A | Outside counsel following billing guidelines |
| Outcome Probability | B | Favorable claim construction, strong expert reports |
| Timeline Compliance | A+ | All deadlines met, no extensions requested |
| Discovery Completeness | A | Document production on track |
| Vendor Performance | B | Good quality, minor delays on invoice submission |

---

## 4. Automation Architecture

### 4.1 Execution Model

The pipeline is designed so Claude Code can orchestrate the entire process:

```
Claude Code
    │
    ├── 1. Generate data (if not already generated)
    │       └── JSON files in output/scenario-1-meridian/
    │
    ├── 2. Run orchestrator script
    │       └── Setup-DemoEnvironment.ps1
    │            ├── Layer 1: Deploy AI seed data (via Deploy-All-AI-SeedData.ps1)
    │            ├── Layer 2: Load core records (accounts → contacts → matters → projects → budgets → invoices → work assignments)
    │            ├── Layer 3: Load document records (sprk_document with AI profile fields)
    │            ├── Layer 4: Upload files to SPE (via BFF API)
    │            ├── Layer 4b: Index documents in AI Search (via BFF API trigger or direct)
    │            └── Layer 5: Load activity records (events → event logs → communications → KPIs → billing → spend snapshots)
    │
    ├── 3. Index Dataverse records in AI Search
    │       └── Sync-RecordsToIndex.ps1 (matters, projects, invoices, accounts)
    │
    └── 4. Validate
            └── Validate-DemoEnvironment.ps1
                 ├── Record counts per entity
                 ├── Relationship integrity (lookups resolve)
                 ├── AI enrichment fields non-null
                 ├── SPE files accessible
                 └── Search index query returns results
```

### 4.2 Script Inventory

#### New Scripts (in this repo)

| Script | Purpose | Inputs |
|--------|---------|--------|
| `scripts/setup/Setup-DemoEnvironment.ps1` | **Master orchestrator** — runs the full pipeline | EnvironmentUrl, BffApiUrl, Scenario, DryRun |
| `scripts/setup/Load-CoreRecords.ps1` | Loads Layer 2 records in dependency order | JSON data files, EnvironmentUrl |
| `scripts/setup/Load-DocumentRecords.ps1` | Loads Layer 3 document records with AI profiles | documents.json, EnvironmentUrl |
| `scripts/setup/Upload-SpeFiles.ps1` | Uploads files to SPE via BFF API, patches document records | files directory, BffApiUrl |
| `scripts/setup/Index-Documents.ps1` | Triggers RAG indexing for uploaded documents via BFF API | Document IDs, BffApiUrl |
| `scripts/setup/Load-ActivityRecords.ps1` | Loads Layer 5 records in dependency order | JSON data files, EnvironmentUrl |
| `scripts/setup/Validate-DemoEnvironment.ps1` | Validates all data layers | EnvironmentUrl, BffApiUrl |
| `scripts/setup/Remove-DemoData.ps1` | Tears down all demo data (reverse dependency order) | EnvironmentUrl, Scenario |
| `scripts/setup/Invoke-DataverseApi.ps1` | Reusable Dataverse Web API helper | (shared module) |

#### Reused Scripts (from spaarke product repo)

| Script | Location | Usage |
|--------|----------|-------|
| `Deploy-All-AI-SeedData.ps1` | `spaarke/scripts/seed-data/` | Layer 1 AI configuration data |
| `Sync-RecordsToIndex.ps1` | `spaarke/scripts/ai-search/` | Index Dataverse records in AI Search |
| `Load-DemoSampleData.ps1` | `spaarke/scripts/` | Reference pattern for idempotent loading |

### 4.3 SPE File Upload Strategy

SPE containers are **per business unit**, not per matter. The demo environment uses a single pre-provisioned container. Files are uploaded directly to the container root — the container itself is the organizational unit (no internal folder hierarchy).

**Demo SPE Container ID**: `b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp`

Files are uploaded through the BFF API, which handles Graph authentication via OBO internally:

```
For each document with a file:
  1. Upload file to the demo container (already exists — no creation needed)
     PUT {bffApiUrl}/api/containers/{containerId}/files/{fileName}
     Body: file stream
     → Returns { id: graphItemId, parentReference: { driveId } }

     Container ID: b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp
     File path example: meridian-pinnacle-msa.pdf

  2. Patch document record in Dataverse
     PATCH {envUrl}/api/data/v9.2/sprk_documents({documentId})
     Body: {
       sprk_graphitemid: "{graphItemId}",
       sprk_graphdriveid: "{driveId}",
       sprk_hasdocument: true,
       sprk_filepath: "{speUrl}",
       sprk_status: 421500001  // Active
     }
```

> **Note**: File names must be unique within the container. Use descriptive file names that include scenario/document context (e.g., `mvp-doc-001_meridian-pinnacle-msa.pdf`) to avoid collisions and support future multi-scenario loading.

### 4.4 AI Search Indexing Strategy

Two indexing paths:

**Path A: Document content indexing (via BFF API)**
- After file upload, trigger the BFF API's RAG indexing pipeline
- BFF handles: document parsing → chunking → embedding → index upload
- This is the production path — validates the full pipeline works

**Path B: Direct index seeding (chosen approach)**
- Seed the AI Search indexes directly via REST API
- Pre-generate document chunks during data generation phase
- Generate embeddings via Azure OpenAI (`https://spaarke-openai-demo.openai.azure.com/openai/deployments/text-embedding-3-large/embeddings?api-version=2023-05-15`)
- Upload chunk documents directly to `spaarke-knowledge-index-v2` and `discovery-index`
- AI Search endpoint: `https://spaarke-search-demo.search.windows.net`
- Admin key: retrieved from Key Vault (`sprk-demo-kv` → `ai-search-key`)

**Path C: Record indexing (via Sync-RecordsToIndex.ps1)**
- Index Dataverse entity records (matters, projects, invoices, accounts) in `spaarke-records-index`
- Generates content embeddings via Azure OpenAI
- Already implemented in product repo

**Chosen approach**: Use **Path B** (direct index seeding) for documents + **Path C** (Sync-RecordsToIndex.ps1) for records. Direct seeding produces the same result as the BFF pipeline but is faster and simpler for automated demo setup. The key requirement is that the indexed data is complete and accurate, not that it flows through the production pipeline.

### 4.5 AI Enrichment Strategy

Document AI fields are **pre-baked during data generation** (not live-processed):

| Field | Pre-baked Value | Live Pipeline Equivalent |
|-------|----------------|--------------------------|
| `sprk_summary` | Generated alongside document content by Claude | ProfileSummaryJobHandler |
| `sprk_tldr` | Generated alongside document content | ProfileSummaryJobHandler |
| `sprk_keywords` | Generated alongside document content | ProfileSummaryJobHandler |
| `sprk_documenttype` | OptionSet value mapped from document category | DocumentClassificationService |
| `sprk_extractorganization` | Newline-separated org names from content | EntityExtractionService |
| `sprk_extractpeople` | Newline-separated person names | EntityExtractionService |
| `sprk_extractfees` | Monetary amounts found in content | EntityExtractionService |
| `sprk_extractdates` | Key dates from content | EntityExtractionService |
| `sprk_extractreference` | Case numbers, contract numbers | EntityExtractionService |
| `sprk_summarystatus` | 100000002 (Completed) | Set after analysis job completes |

Pre-baking means the demo environment is immediately usable without waiting for AI pipeline processing. The live pipeline can optionally re-process documents to validate it produces similar results.

---

## 5. Data Generation

### 5.1 Generation Approach

Claude Code generates all data interactively in the `spaarke-data-cli` repo:

1. **Scenario narrative** → Define the story, parties, timeline, key events
2. **Core entity JSON** → Accounts, contacts, matters, projects, budgets, invoices, work assignments
3. **Document content** → Markdown files for each document (realistic multi-page content)
4. **AI enrichment** → Summary, keywords, entities for each document (generated alongside content)
5. **Activity data** → Events, communications, KPIs, billing events, spend snapshots
6. **File manifest** → Maps document records to generated files with metadata

### 5.2 Data Quality Rules

| Rule | Implementation |
|------|---------------|
| **Temporal coherence** | All dates within scenario timeline; past events completed, future events pending |
| **Financial integrity** | Billing event amounts sum to invoice totals; spend snapshots match billing event aggregations |
| **Relationship completeness** | Every lookup field populated; no orphaned records |
| **Realistic names** | Law firm names, attorney names, corporate entities — all plausible |
| **RFC compliance** | Email addresses use `@example.com` (RFC 2606); EML files have valid headers |
| **Deterministic IDs** | Cross-file references use logical keys (`mvp-matter-001`, `mvp-acct-meridian`) resolved at load time |
| **OptionSet accuracy** | All choice fields use valid OptionSet integer values matching Dataverse schema |

### 5.3 Output Structure

```
output/
└── scenario-1-meridian/
    ├── accounts.json              # 4-6 account records
    ├── contacts.json              # 12-18 contact records
    ├── matters.json               # 1-2 matter records
    ├── projects.json              # 3-5 project records
    ├── budgets.json               # 1-2 budget records
    ├── budget-buckets.json        # 4-6 budget bucket records
    ├── invoices.json              # 8-12 invoice records
    ├── work-assignments.json      # 5-8 work assignment records
    ├── documents.json             # 50-80 document records (with AI profile fields)
    ├── events.json                # 40-60 event records
    ├── event-logs.json            # 80-120 event log records
    ├── communications.json        # 30-40 communication records
    ├── kpi-assessments.json       # 6-10 KPI assessment records
    ├── billing-events.json        # 50-80 billing event line items
    ├── spend-snapshots.json       # 6-12 monthly snapshots
    ├── file-manifest.json         # Maps document IDs → file paths + metadata
    └── files/
        ├── contracts/             # PDF files (CUAD-sourced + synthetic)
        ├── pleadings/             # PDF files (synthetic)
        ├── memos/                 # DOCX/MD files (synthetic)
        ├── emails/                # EML files (synthetic)
        ├── invoices/              # PDF files (synthetic)
        ├── expert-reports/        # DOCX files (synthetic)
        ├── court-orders/          # PDF files (synthetic)
        └── discovery/             # PDF/XLSX files (synthetic)
```

---

## 6. Leveraged Infrastructure

### 6.1 From Product Repo (`spaarke`)

| Asset | Path | Usage in This Project |
|-------|------|----------------------|
| **Demo data loader** | `scripts/Load-DemoSampleData.ps1` | Pattern for idempotent record creation, solution validation |
| **AI seed data deployer** | `scripts/seed-data/Deploy-All-AI-SeedData.ps1` | Layer 1 deployment (playbooks, actions, skills, tools, knowledge) |
| **AI seed JSON files** | `scripts/seed-data/*.json` | Layer 1 data definitions |
| **Record-to-index sync** | `scripts/ai-search/Sync-RecordsToIndex.ps1` | Index matter/project/invoice/account records |
| **Entity schema reference** | `src/server/shared/Spaarke.Dataverse/Models.cs` | Field names, OptionSet values, lookup patterns |
| **BFF API endpoints** | `src/server/api/Sprk.Bff.Api/Api/` | SPE upload, container management, document operations |
| **RAG indexing pipeline** | `src/server/api/Sprk.Bff.Api/Services/Ai/RagIndexingPipeline.cs` | Document chunking, embedding, index population |
| **Search index schemas** | `Models/Ai/KnowledgeDocument.cs`, `RecordMatching/SearchIndexDocument.cs` | Index field definitions |
| **Spend snapshot service** | `Services/Finance/SpendSnapshotService.cs` | Aggregation rules for financial data |
| **Demo records JSON** | `scripts/demo-data/demo-records.json` | Reference for record structure |

### 6.2 From This Repo (`spaarke-data-cli`)

| Asset | Path | Status |
|-------|------|--------|
| **Scenario 1 JSON data** | `output/scenario-1-meridian/*.json` | Generated (Phase 0, Tasks 001-004) |
| **Scenario 1 document files** | `output/scenario-1-meridian/files/` | Generated (Phase 0, Task 005) |
| **Phase 0 loading scripts** | `scripts/phase0/` | Generated (Phase 0, Task 006) — to be refactored into `scripts/setup/` |
| **Entity schemas** | `schemas/` | To be created — Dataverse-ready field definitions |
| **Scenario configs** | `scenarios/` | To be created — YAML scenario definitions |

---

## 7. Execution Flow

### 7.1 Prerequisites

Before running the pipeline:

1. **Azure CLI authenticated**: `az login` with account that has Dataverse access
2. **Spaarke solutions imported**: Custom entities must exist in target environment
3. **BFF API running**: For SPE file uploads and AI Search indexing
4. **Data generated**: JSON files and document files in `output/` directory

### 7.2 Pipeline Steps

```powershell
# Full automated run
./scripts/setup/Setup-DemoEnvironment.ps1 `
    -EnvironmentUrl "https://spaarke-demo.crm.dynamics.com" `
    -BffApiUrl "https://spaarke-bff-demo.azurewebsites.net" `
    -BffClientId "da03fe1a-4b1d-4297-a4ce-4b83cae498a9" `
    -SpeContainerId "b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp" `
    -AiSearchEndpoint "https://spaarke-search-demo.search.windows.net" `
    -Scenario "scenario-1-meridian" `
    -SpaarkeRepoPath "C:\code_files\spaarke"

# Or step-by-step for debugging:
# Step 1: AI seed data (Layer 1)
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "ai-seed" ...

# Step 2: Core records (Layer 2)
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "core-records" ...

# Step 3: Document records (Layer 3)
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "documents" ...

# Step 4: SPE files + AI Search (Layer 4)
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "files-and-index" ...

# Step 5: Activity records (Layer 5)
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "activities" ...

# Step 6: Record indexing
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "record-index" ...

# Step 7: Validate
./scripts/setup/Setup-DemoEnvironment.ps1 -StepOnly "validate" ...
```

### 7.3 Detailed Step Breakdown

#### Step 1: Deploy AI Seed Data (Layer 1)
- Delegates to `spaarke/scripts/seed-data/Deploy-All-AI-SeedData.ps1`
- Creates: event types, actions, tools, knowledge sources, skills, playbooks, output types
- **Idempotent**: Checks for existence before creating
- **Duration**: ~30 seconds

#### Step 2: Load Core Business Records (Layer 2)
- Reads: `accounts.json`, `contacts.json`, `matters.json`, `projects.json`, `budgets.json`, `budget-buckets.json`, `invoices.json`, `work-assignments.json`
- Creates records in dependency order (accounts first, then contacts with account lookup, then matters with account lookup, etc.)
- Resolves cross-entity references: logical IDs → Dataverse GUIDs via lookup queries
- **Idempotent**: Upsert via name/number match
- **Duration**: ~2-3 minutes

#### Step 3: Load Document Records (Layer 3)
- Reads: `documents.json`
- Creates `sprk_document` records with all AI profile fields pre-populated
- Sets matter/project/invoice lookup references
- Marks `sprk_summarystatus` = Completed, `sprk_hasdocument` = false (files not uploaded yet)
- **Duration**: ~2-3 minutes

#### Step 4a: Upload Files to SPE (Layer 4)
- Reads: `file-manifest.json` for document-to-file mapping
- Uploads each file to the shared demo SPE container via BFF API (`PUT /api/containers/{containerId}/files/{fileName}`)
- Container: `b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp`
- Files uploaded to container root with unique descriptive names (e.g., `mvp-doc-001_meridian-pinnacle-msa.pdf`)
- Patches `sprk_document` records with `graphitemid`, `graphdriveid`, `hasdocument` = true
- **Duration**: ~5-10 minutes (depends on file count and size)

#### Step 4b: Seed AI Search Indexes (Layer 4)
- Pre-generated document chunks uploaded directly to AI Search via REST API
- Seeds `spaarke-knowledge-index-v2` (2048-char chunks with 200-char overlap)
- Seeds `discovery-index` (4096-char chunks with 400-char overlap)
- Each chunk includes `contentVector3072` embedding (pre-generated during data generation)
- Sets parent entity scoping (parentEntityType, parentEntityId) for filtered search
- Updates `sprk_document` records: `searchindexed` = true, `searchindexname`, `searchindexedon`
- **Duration**: ~3-5 minutes

#### Step 5: Load Activity Records (Layer 5)
- Reads: `events.json`, `event-logs.json`, `communications.json`, `kpi-assessments.json`, `billing-events.json`, `spend-snapshots.json`
- Creates records with polymorphic regarding lookups resolved to Dataverse GUIDs
- Events created in chronological order with appropriate status (completed → active → pending)
- **Duration**: ~3-5 minutes

#### Step 6: Index Dataverse Records
- Delegates to `spaarke/scripts/ai-search/Sync-RecordsToIndex.ps1`
- Indexes matters, projects, invoices, accounts in `spaarke-records-index`
- Generates content embeddings via Azure OpenAI
- **Duration**: ~2-3 minutes

#### Step 7: Validate
- Queries each entity for expected record counts
- Verifies lookup relationships resolve (sample checks)
- Confirms AI enrichment fields are non-null on document records
- Tests SPE file accessibility via BFF API
- Runs a semantic search query to confirm index population
- Reports pass/fail summary
- **Duration**: ~1 minute

### 7.4 Total Pipeline Duration

| Step | Duration | Notes |
|------|----------|-------|
| AI seed data | ~30s | Skipped if already deployed |
| Core records | ~2-3 min | 50-60 records |
| Document records | ~2-3 min | 50-80 records |
| SPE upload + indexing | ~10-20 min | 20-30 files, bottleneck is indexing |
| Activity records | ~3-5 min | 200-350 records |
| Record indexing | ~2-3 min | 10-15 records |
| Validation | ~1 min | Query-based checks |
| **Total** | **~20-35 min** | End-to-end |

---

## 8. Teardown & Reset

```powershell
# Remove all demo data and rebuild
./scripts/setup/Remove-DemoData.ps1 `
    -EnvironmentUrl "https://spaarkedev1.crm.dynamics.com" `
    -BffApiUrl "https://spe-api-dev-67e2xz.azurewebsites.net" `
    -Scenario "scenario-1-meridian"
```

Deletion order (reverse of creation):
1. AI Search index entries (delete chunks for demo documents)
2. Activity records (events, communications, KPIs, billing, spend snapshots)
3. Document records (also triggers SPE file cleanup if configured)
4. Core business records (work assignments → invoices → budget buckets → budgets → projects → matters → contacts → accounts)
5. AI seed data (optional — usually left in place)

---

## 9. Resolved Decisions & Remaining Gaps

### 9.1 Resolved Decisions

| # | Decision | Resolution | Rationale |
|---|----------|-----------|-----------|
| 1 | **BFF API auth** | MSAL/OBO — acquire token for scope `api://da03fe1a-4b1d-4297-a4ce-4b83cae498a9/access_as_user` via Azure CLI or MSAL ConfidentialClient | Follows existing platform auth patterns (see `spaarke/.claude/patterns/auth/`) |
| 2 | **AI Search indexing path** | Direct index seeding — bypass BFF RAG pipeline | Same result, faster, simpler for demo setup; key requirement is data completeness and accuracy |
| 3 | **Document file formats** | Mix of **PDF and DOCX** — no markdown, no lorem ipsum | Documents must look authentic; use pandoc for MD→PDF/DOCX conversion |
| 4 | **Event types** | Already deployed as configuration in the Dataverse solution | Pipeline creates Event *records* (sprk_event), not Event *types* (sprk_eventtype) |
| 5 | **SPE container strategy** | Single shared container per business unit — flat structure, no internal folders | Demo container: `b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp` |

### 9.2 Known Gaps from Phase 0

| Gap | Description | Resolution |
|-----|-------------|------------|
| **Event logs not generated** | Phase 0 JSON doesn't include `sprk_eventlog` records | Generate event logs showing state transitions |
| **Budget buckets not generated** | Phase 0 has budgets but not `sprk_budgetbucket` records | Generate budget buckets with fee/expense/expert/other splits |
| **No EML/XLSX files** | Current files are all markdown-based | Generate proper EML files with RFC 5322 headers; add XLSX invoice attachments |
| **Document-to-entity lookups incomplete** | Some documents missing matter/project/invoice associations | Ensure every document has at least one record association |
| **Spend snapshot velocity** | MoM velocity not calculated in current data | Generate spend snapshots with proper velocity calculations |
| **Search index pre-seeding** | No chunked/embedded content generated for direct index seeding | Generate pre-chunked content with embeddings as fallback |

---

## 10. Success Criteria

| Criterion | Validation Method |
|-----------|-------------------|
| **Full pipeline runs unattended** | Claude Code executes `Setup-DemoEnvironment.ps1` end-to-end without manual intervention |
| **All record counts match** | Validation script reports expected counts for every entity |
| **Relationships resolve** | Opening a matter shows related projects, documents, events, invoices in sub-grids |
| **AI fields populated** | Document records show summaries, keywords, extracted entities |
| **Files accessible** | Documents open from SPE links in Dataverse forms |
| **Search works** | Semantic search returns relevant results for scenario-specific queries (e.g., "patent infringement", "Meridian") |
| **Financial data coherent** | Budget utilization chart shows realistic spend progression; invoice amounts reconcile |
| **KPI grades display** | Matter scorecard shows performance grades across assessment areas |
| **Idempotent** | Running pipeline twice produces no duplicates or errors |
| **Resetable** | `Remove-DemoData.ps1` + `Setup-DemoEnvironment.ps1` restores clean state |

---

## 11. Implementation Phases

### Phase A: Complete Data Generation (enhance Phase 0 output)
- Fill gaps: event logs, budget buckets, EML files, spend snapshot velocity
- Ensure all entity relationships are fully populated
- Convert key documents from MD to PDF/DOCX
- Generate pre-chunked content for AI Search fallback seeding
- **Deliverable**: Complete `output/scenario-1-meridian/` directory

### Phase B: Build Automation Scripts
- Create `scripts/setup/` directory with all new scripts
- Build `Setup-DemoEnvironment.ps1` orchestrator
- Implement SPE upload via BFF API
- Implement AI Search indexing trigger
- Build validation script
- Build teardown script
- **Deliverable**: Working `scripts/setup/` directory

### Phase C: End-to-End Test
- Run full pipeline against dev environment
- Resolve authentication and connectivity issues
- Tune timing/polling for async operations (indexing)
- Fix data quality issues found during validation
- **Deliverable**: Successfully populated dev environment

### Phase D: Documentation & Handoff
- Update DATA-PROVENANCE.md
- Write README for `scripts/setup/`
- Document environment prerequisites
- Record lessons learned
- **Deliverable**: Project complete, demo environment ready

---

## 12. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| BFF API auth blocks scripted uploads | Can't automate SPE file uploads | Medium | Fall back to direct Graph API calls with service principal |
| AI Search indexing takes too long | Pipeline exceeds 1 hour | Low | Use direct index seeding (Path B) as fallback |
| Dataverse rate limiting | Record creation fails or throttles | Medium | Add retry logic with exponential backoff; batch where possible |
| Entity schema drift | Field names in JSON don't match current schema | Low | Validate field names against live schema before loading |
| BFF API not deployed to dev | SPE and indexing unavailable | Medium | Make SPE/indexing steps optional with clear skip messages |
| CUAD PDF party names don't match scenario | Document content references wrong company names | Low | Accept mismatch in PDF content; metadata (sprk_document fields) has correct names |
