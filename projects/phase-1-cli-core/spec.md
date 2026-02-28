# Phase 1: CLI Core + Repeatable Loading — Spec

> **Project**: `phase-1-cli-core`
> **Parent Design**: [`spaarke/projects/spaarke-demo-data-setup-r1/design.md`](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md) — Section 12, Phase 1
> **Repository**: `spaarke-data-cli`
> **Timeline**: 1-2 weeks
> **Phase Dependencies**: Phase 0 (data design validated, loading patterns proven)

---

## 1. Executive Summary

Wrap Phase 0's proven data generation and loading process into the `spaarke-data` CLI tool so that anyone on the team (developers, sales engineers, QA) can reset and repopulate the dev environment with a single command. This phase implements three core commands (`generate`, `load`, `reset`), formalizes Scenario 1 as a YAML definition, and exports Dataverse entity schemas for runtime validation.

After Phase 1, the workflow changes from "ask Ralph to run the PowerShell scripts" to `spaarke-data load --target dev`.

---

## 2. Scope

### In Scope

- Implement `generate` command — calls Claude API to produce entity JSON from scenario YAML definitions
- Implement `load` command — orchestrates Dataverse Web API upserts in dependency order + SPE file upload via BFF API
- Implement `reset` command — reverse-order delete + reload
- Formalize Scenario 1 (Meridian v. Pinnacle) as a YAML scenario definition
- Export entity schemas from live Dataverse via Web API metadata endpoint
- Create `config/environments.yaml` support for named environments (`--target dev`)
- Basic post-load validation (record counts, lookup integrity)
- npm scripts for development (`npm run dev -- generate --scenario meridian-v-pinnacle`)

### Out of Scope

- Scenarios 2-5 (Phase 2)
- CUAD/Caselaw source adapters (Phase 2)
- AI Search index seeding (Phase 2)
- CMT/PAC CLI bulk loader (Phase 2 — Web API is sufficient for one scenario)
- Customer onboarding commands (Phase 3)
- npm global package publishing (Phase 3)
- CI/CD pipeline (Phase 3)

---

## 3. Requirements

### 3.1 Generate Command

```bash
spaarke-data generate --scenario meridian-v-pinnacle
spaarke-data generate --scenario meridian-v-pinnacle --layer records
spaarke-data generate --scenario meridian-v-pinnacle --layer documents
spaarke-data generate --scenario meridian-v-pinnacle --layer activity
```

**Behavior**:
1. Read scenario YAML definition from `scenarios/{name}.yaml`
2. Read entity schemas from `schemas/` for field validation
3. Call Claude API to generate entity records matching the scenario narrative
4. Write JSON output files to `output/{scenario-name}/`
5. For document layer: also generate actual files (PDF, DOCX, EML) to `output/{scenario-name}/files/`
6. For each document: generate AI enrichment fields (summary, keywords, entities, classification)

**Configuration**:
- Claude API key from environment variable `ANTHROPIC_API_KEY`
- Model configurable in `config/defaults.yaml` (default: `claude-sonnet-4-6`)
- Output directory configurable (default: `./output/`)

### 3.2 Load Command

```bash
spaarke-data load --target dev
spaarke-data load --target dev --layer records
spaarke-data load --target dev --layer files
spaarke-data load --target dev --data ./output/meridian-v-pinnacle/
```

**Behavior**:
1. Resolve target environment from `config/environments.yaml`
2. Authenticate via `az account get-access-token --resource {dataverse_url}`
3. Load records in dependency order:
   - Layer 1: Reference/config records (if any)
   - Layer 2: Accounts → Contacts → Matters → Projects → Budgets → Invoices
   - Layer 3: Document records (with AI enrichment fields)
   - Layer 4: Upload files to SPE via BFF API, patch document records with storage refs
   - Layer 5: Events → Event Logs → Communications → KPI Assessments → Work Assignments → Billing Events → Spend Snapshots
4. Use Web API upsert with alternate keys for idempotency
5. Report progress (records loaded per entity, errors encountered)
6. Batch operations where possible (Dataverse `$batch` endpoint, up to 1000 per batch)

**Error handling**:
- Continue on individual record failure (log error, skip record, continue)
- Summary report at end: X loaded, Y failed, Z skipped (already exists)
- Exit code 1 if any failures

### 3.3 Reset Command

```bash
spaarke-data reset --target dev --confirm
spaarke-data reset --target dev --scenario meridian-v-pinnacle --confirm
```

**Behavior**:
1. **Require** `--confirm` flag (safety gate — no accidental wipes)
2. Validate target environment is NOT production (check against blocklist in config)
3. Delete records in reverse dependency order:
   - Spend Snapshots → Billing Events → Work Assignments → KPI Assessments
   - Communications → Event Logs → Events
   - Document records (after deleting SPE files)
   - SPE container contents (via BFF API)
   - Invoices → Budgets → Projects → Matters
   - Contacts → Accounts (preserve system accounts — only delete accounts with scenario prefix)
4. Reload using `load` command logic
5. Report: X deleted, Y loaded, validation passed/failed

### 3.4 Scenario YAML Format

Formalize Scenario 1 as a YAML definition (`scenarios/meridian-v-pinnacle.yaml`):

```yaml
name: meridian-v-pinnacle
display_name: "Meridian Corp v. Pinnacle Industries"
description: "Patent infringement dispute over proprietary manufacturing process"
type: litigation

narrative:
  summary: >
    Active patent litigation. Meridian Corp (client) alleges Pinnacle Industries
    infringed on proprietary manufacturing process patents. Six months into litigation
    with discovery deadlines, expert depositions, and budget pressure.
  timeline_start: "2025-08-15"  # Matter opened
  timeline_end: "2026-06-30"    # Projected trial date

entities:
  accounts:
    - id: mvp-acct-meridian
      name: "Meridian Corp"
      role: client
      industry: "Manufacturing"
    - id: mvp-acct-pinnacle
      name: "Pinnacle Industries"
      role: opposing_party
      industry: "Technology"
    # ... law firms

  contacts:
    - id: mvp-contact-chen
      name: "Sarah Chen"
      title: "General Counsel"
      account_ref: mvp-acct-meridian
    # ... attorneys, paralegals, etc.

  matters:
    - id: mvp-matter-001
      name: "Meridian Corp v. Pinnacle Industries"
      type: litigation
      status: active
      # ... fields

  documents:
    - id: mvp-doc-001
      title: "Master Services Agreement — Meridian/Pinnacle"
      type: contract
      source: cuad  # or synthetic, template
      ai_enrichment: true
    # ...

  events:
    - id: mvp-event-001
      name: "File Initial Complaint"
      type: filing_deadline
      relative_date: "timeline_start+0d"
      status: completed
    # ...
```

The YAML defines the scenario structure. The `generate` command uses it as input to Claude API for full record generation.

### 3.5 Entity Schema Export

```bash
spaarke-data schema export --target dev --output ./schemas/
```

**Behavior**:
1. Connect to Dataverse Web API metadata endpoint
2. For each entity used in scenarios: export field definitions, types, option sets, relationships
3. Write to `schemas/{entity_logical_name}.schema.json`
4. Used by `generate` command to validate generated data matches actual schema

**Entities to export**:
- `account`, `contact`
- `sprk_matter`, `sprk_project`, `sprk_invoice`, `sprk_budget`
- `sprk_document`, `sprk_event`, `sprk_eventlog`, `sprk_communication`
- `sprk_kpiassessment`, `sprk_workassignment`
- `sprk_billingevent`, `sprk_spendsnapshot` (or equivalent entity names)

### 3.6 Environment Configuration

```yaml
# config/environments.yaml
environments:
  dev:
    dataverse_url: https://spaarkedev1.crm.dynamics.com
    bff_api_url: https://spe-api-dev-67e2xz.azurewebsites.net
    search_url: https://spaarke-search-dev.search.windows.net
    description: Development environment
    protected: false

  # Production environments get protected: true (reset refuses to run)
```

### 3.7 Basic Validation

After `load` completes, run automatic checks:

1. **Record count validation**: Query each entity, compare actual count to expected count from scenario
2. **Lookup integrity**: For a sample of records, verify lookup fields resolve to existing records
3. **Field completeness**: Verify `sprk_document` records have non-null AI enrichment fields
4. Report pass/fail with details

---

## 4. Technical Approach

### 4.1 Project Structure (new/modified files)

```
src/
├── cli/
│   ├── index.ts              # UPDATE: wire up real command handlers
│   ├── generate.ts           # NEW: generate command implementation
│   ├── load.ts               # NEW: load command implementation
│   ├── reset.ts              # NEW: reset command implementation
│   └── schema.ts             # NEW: schema export command (partial)
│
├── core/
│   ├── pipeline.ts           # NEW: orchestrates generate → validate flow
│   ├── scenario-loader.ts    # NEW: parses scenario YAML, resolves references
│   └── schema-registry.ts    # NEW: loads and validates against entity schemas
│
├── adapters/
│   └── claude-adapter.ts     # NEW: Claude API integration for content generation
│
├── loaders/
│   ├── webapi-loader.ts      # NEW: Dataverse Web API upsert (port from Phase 0 PowerShell)
│   └── spe-loader.ts         # NEW: BFF API file upload (port from Phase 0 PowerShell)
│
├── validators/
│   ├── count-validator.ts    # NEW: record count checks
│   └── relationship-validator.ts  # NEW: lookup integrity checks
│
└── types/
    ├── scenario.ts           # UPDATE: match actual YAML schema
    ├── entity.ts             # UPDATE: match exported schema format
    └── config.ts             # UPDATE: add protected flag, auth config
```

### 4.2 Authentication

Use Azure CLI token acquisition (same as Phase 0):

```typescript
// Get bearer token for Dataverse
const { stdout } = await exec(`az account get-access-token --resource ${dataverseUrl} --query accessToken -o tsv`);
const token = stdout.trim();
```

For BFF API authentication, use the same pattern with the BFF API's resource URL.

No new auth infrastructure — leverage existing `az` CLI login.

### 4.3 Web API Loader Design

Port Phase 0's PowerShell loading logic to TypeScript:

```typescript
interface LoaderResult {
  entity: string;
  loaded: number;
  failed: number;
  skipped: number;
  errors: LoadError[];
}

async function loadEntity(
  entity: string,
  records: EntityRecord[],
  config: EnvironmentConfig,
  token: string
): Promise<LoaderResult> {
  // Upsert via Web API using alternate keys
  // Batch in groups of 50 (configurable)
  // Continue on failure, collect errors
}
```

### 4.4 Claude API Integration

Use the Anthropic SDK (`@anthropic-ai/sdk`) for content generation:

```typescript
import Anthropic from "@anthropic-ai/sdk";

async function generateEntityRecords(
  scenario: ScenarioDefinition,
  entityType: string,
  schema: EntitySchema
): Promise<EntityRecord[]> {
  // Build prompt with scenario context + entity schema
  // Call Claude API with structured output
  // Validate response against schema
  // Return typed records
}
```

### 4.5 Dependencies to Add

```json
{
  "dependencies": {
    "@anthropic-ai/sdk": "^0.39.0",
    "commander": "^12.0.0",
    "yaml": "^2.4.0",
    "chalk": "^5.3.0",
    "ora": "^8.0.0"
  }
}
```

---

## 5. Success Criteria

| Criterion | Measurement |
|-----------|-------------|
| **Generate works** | `spaarke-data generate --scenario meridian-v-pinnacle` produces complete JSON + files |
| **Load works** | `spaarke-data load --target dev` loads all records + files into Dataverse |
| **Reset works** | `spaarke-data reset --target dev --confirm` wipes and reloads cleanly |
| **Idempotent** | Running `load` twice produces no duplicates |
| **Schema export** | `spaarke-data schema export --target dev` produces valid schema files |
| **Validation passes** | Post-load checks report all-green on record counts and relationships |
| **Non-developer usable** | A sales engineer can run `npm run dev -- load --target dev` with only env setup docs |
| **Parity with Phase 0** | CLI-loaded data is identical to Phase 0 manually-loaded data |

---

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Claude API rate limits during generation | Slow or failed generation for large scenarios | Implement retry with backoff; cache intermediate results; generate in chunks |
| Claude API output format inconsistency | Generated JSON doesn't match expected schema | Use structured output mode; validate each response against entity schema before writing |
| Web API batch size limits | Failures on large batch requests | Start with batch size 50; reduce on 413 errors; configurable in defaults.yaml |
| Token expiration during long load operations | Auth failures mid-load | Refresh token before each entity batch; add token expiry tracking |
| Phase 0 loading scripts had undocumented workarounds | CLI port misses edge cases | Review Phase 0 scripts carefully; keep Phase 0 scripts as regression baselines |

---

## 7. Deliverables

1. **Working CLI commands**: `generate`, `load`, `reset`, `schema export`
2. **Scenario 1 YAML**: `scenarios/meridian-v-pinnacle.yaml`
3. **Entity schemas**: `schemas/*.schema.json` exported from dev environment
4. **Source code**: `src/cli/`, `src/core/`, `src/adapters/claude-adapter.ts`, `src/loaders/`, `src/validators/`
5. **Updated dependencies**: `package.json` with `@anthropic-ai/sdk`
6. **Documentation**: Updated README.md with setup instructions and usage examples

---

## 8. Constraints

- **Web API only**: No CMT/PAC CLI loader in this phase — Web API is sufficient for one scenario
- **Single scenario**: Only Meridian v. Pinnacle is formalized as YAML — others added in Phase 2
- **Azure CLI auth only**: No service principal or app registration — uses developer's `az login`
- **No AI Search**: Search index population deferred to Phase 2
- **Phase 0 parity**: CLI output must match Phase 0's manual loading — use Phase 0 data as test baseline

---

## 9. Inputs from Phase 0

This phase directly depends on Phase 0 outputs:

| Phase 0 Output | How Phase 1 Uses It |
|----------------|---------------------|
| `output/scenario-1-meridian/*.json` | Reference data for YAML scenario formalization; test baseline for CLI output comparison |
| `scripts/phase0/Load-CoreRecords.ps1` | Loading order and Web API patterns ported to TypeScript `webapi-loader.ts` |
| `scripts/phase0/Upload-SpeFiles.ps1` | SPE upload pattern ported to TypeScript `spe-loader.ts` |
| `scripts/phase0/Remove-Scenario1Data.ps1` | Deletion order ported to `reset` command |
| Entity field names and relationships discovered | Codified in `schemas/*.schema.json` and `scenarios/meridian-v-pinnacle.yaml` |
| Lessons learned (load order issues, field quirks) | Addressed in CLI implementation from the start |
