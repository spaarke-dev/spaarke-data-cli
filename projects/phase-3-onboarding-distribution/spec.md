# Phase 3: Onboarding + Distribution — Spec

> **Project**: `phase-3-onboarding-distribution`
> **Parent Design**: [`spaarke/projects/spaarke-demo-data-setup-r1/design.md`](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md) — Section 12, Phase 3
> **Repository**: `spaarke-data-cli`
> **Timeline**: As needed (after Phase 2 delivers full demo environment)
> **Phase Dependencies**: Phase 2 (all scenarios working, validation suite complete)

---

## 1. Executive Summary

Transform the Spaarke Data CLI from an internal demo data tool into a customer-facing onboarding and environment management product. This phase adds data import from customer sources (CSV, Excel), automated dataset harvesting via OpenClaw, optional UI validation via Claude Computer Use, schema drift detection, and packages the tool for distribution via npm. After this phase, onboarding specialists can run `npx @spaarke/data-cli onboard --source customer-data.xlsx --mapping auto --target staging` to import a customer's data into their Spaarke environment.

---

## 2. Scope

### In Scope

- CSV source adapter for customer data import
- Excel (XLSX) source adapter for customer data import
- `onboard` command with mapping-driven import workflow
- Customer mapping YAML templates and examples
- Auto-detection of column-to-field mappings
- `schema diff` command to detect drift between local schemas and live environments
- OpenClaw adapter for automated open dataset harvesting
- Claude Computer Use validator for optional UI rendering checks
- Volume scaling refinement (`--volume light` / `--volume full`)
- Multi-environment support (dev, staging, demo, customer environments)
- npm global package publishing (`npm install -g @spaarke/data-cli`)
- GitHub Actions CI/CD pipeline (build, test, publish)
- Comprehensive documentation (getting started, adding scenarios, customer onboarding)

### Out of Scope

- Web-based UI for the tool (CLI only)
- Automatic schema migration (detect drift only, don't fix it)
- Multi-tenant SaaS deployment (tool runs locally, targets one environment at a time)
- Automated customer data anonymization (manual process, documented in guides)

---

## 3. Requirements

### 3.1 CSV Source Adapter

```bash
spaarke-data onboard --source ./customer-matters.csv --mapping ./mappings/customer-x.yaml --target staging
```

**Behavior**:
1. Parse CSV file with configurable delimiter, encoding, header row
2. Apply column-to-field mapping from YAML mapping file
3. Transform values using mapping rules (option set mapping, date format conversion, lookup resolution)
4. Validate transformed records against entity schemas
5. Load into target environment via Web API

**CSV features**:
- Auto-detect delimiter (comma, semicolon, tab, pipe)
- Handle quoted fields with embedded delimiters
- Support UTF-8 and UTF-16 encoding
- Skip header rows (configurable count)
- Handle empty/null values gracefully

### 3.2 Excel Source Adapter

```bash
spaarke-data onboard --source ./customer-export.xlsx --mapping ./mappings/customer-x.yaml --target staging
spaarke-data onboard --source ./customer-export.xlsx --sheet "Matters" --mapping auto --target staging
```

**Behavior**:
1. Parse XLSX file using `xlsx` or `exceljs` library
2. Support multi-sheet workbooks (map each sheet to an entity)
3. Apply same mapping logic as CSV adapter
4. Handle Excel-specific data types (dates as serial numbers, currency formatting)

**Additional dependency**: `exceljs` or `xlsx` npm package.

### 3.3 Onboard Command

```bash
# With explicit mapping
spaarke-data onboard --source ./data.csv --mapping ./mappings/my-mapping.yaml --target staging

# With auto-detection
spaarke-data onboard --source ./data.xlsx --mapping auto --target staging

# Dry run (validate without loading)
spaarke-data onboard --source ./data.csv --mapping auto --target staging --dry-run

# Preview mapping (show what would be mapped)
spaarke-data onboard --source ./data.csv --mapping auto --preview
```

**Auto-detection** (`--mapping auto`):
1. Read column headers from source file
2. Compare against known entity field names and common aliases
3. Score each column→field mapping candidate by string similarity
4. Present proposed mapping to user for confirmation (interactive) or apply with confidence threshold (non-interactive)
5. Generate mapping YAML for future reuse

**Mapping YAML format** (extends existing `mappings/_template.yaml`):

```yaml
mapping:
  name: "customer-acme"
  description: "Mapping for Acme Corp matter export"
  source_format: xlsx
  sheets:
    - name: "Matters"
      entity: sprk_matter
      columns:
        "Matter Name": sprk_name
        "Matter Number": sprk_matternumber
        "Practice Area": sprk_practicearea
        "Status": sprk_matterstatus
        "Open Date": sprk_opendate
        "Responsible Attorney": sprk_responsibleattorney_ref

    - name: "Contacts"
      entity: contact
      columns:
        "Full Name": fullname
        "Email": emailaddress1
        "Job Title": jobtitle

  transforms:
    sprk_practicearea:
      type: option_set_map
      values:
        "Litigation": 100000000
        "Corporate": 100000001

  relationships:
    # How to resolve cross-entity references in the source data
    sprk_responsibleattorney_ref:
      target_entity: contact
      match_field: fullname
      source_column: "Responsible Attorney"
```

### 3.4 Schema Diff Command

```bash
spaarke-data schema diff --source ./schemas/ --target dev
spaarke-data schema diff --source ./schemas/ --target staging --verbose
```

**Behavior**:
1. Load local schemas from `schemas/` directory
2. Fetch current schemas from target environment via Web API metadata
3. Compare and report differences:
   - New fields in environment (not in local schemas)
   - Removed fields (in local but not in environment)
   - Type changes
   - Option set value changes
   - New/removed relationships
4. Exit code 0 = no drift, 1 = drift detected

**Use case**: Before running `load` or `onboard`, verify the target environment schema matches what the tool expects. Catches issues from Dataverse solution updates or manual customizations.

### 3.5 OpenClaw Adapter

```bash
spaarke-data harvest all --output ./sources/ --use-openclaw
spaarke-data harvest cuad --output ./sources/cuad/ --use-openclaw
```

**Behavior**:
1. Launch OpenClaw agent in isolated environment (Docker container)
2. Instruct agent to navigate to dataset source (CUAD GitHub, Kaggle, Caselaw Access)
3. Download dataset files
4. Organize into `sources/{dataset}/` directory structure
5. Log all agent actions for audit

**Safety requirements**:
- Run in isolated container (no access to local filesystem beyond `sources/` mount)
- Review all downloaded content before incorporation
- Log all URLs visited and actions taken
- Respect robots.txt
- Rate limit requests

**Fallback**: If OpenClaw is unavailable or fails, fall back to direct download (curl/wget) for datasets with known URLs.

### 3.6 Claude Computer Use Validator

```bash
spaarke-data validate --target dev --ui-check
spaarke-data validate --target dev --ui-check --scenario meridian-v-pinnacle
```

**Behavior**:
1. Launch Claude Computer Use agent
2. Navigate to Dataverse environment in browser
3. For each scenario, verify:
   - Matter form renders with related records (projects, documents, events)
   - Document grid shows files with thumbnails
   - Event timeline displays correctly
   - Invoice subgrid shows line items
   - AI enrichment fields (summary, keywords) display on document forms
4. Capture screenshots as evidence
5. Report pass/fail with screenshot links

**Not a blocking gate**: UI validation is supplementary. API validation (Phase 2's `validate` command) remains the primary quality check.

### 3.7 npm Distribution

```bash
# Install globally
npm install -g @spaarke/data-cli

# Or run directly
npx @spaarke/data-cli generate --scenario all
```

**Package configuration**:
- Package name: `@spaarke/data-cli`
- Binary name: `spaarke-data`
- Scope: `@spaarke` (private npm org)
- Version: semver, starting at `1.0.0` for Phase 3 release
- Engines: Node.js >= 18

### 3.8 CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ci.yml`):

| Job | Trigger | Steps |
|-----|---------|-------|
| `build` | Push to any branch | Install deps → TypeScript compile → Lint |
| `test` | Push to any branch | Unit tests → Integration tests (mocked) |
| `publish` | Tag `v*` on `master` | Build → Test → `npm publish` to private registry |

---

## 4. Technical Approach

### 4.1 New/Modified Source Files

```
src/
├── adapters/
│   ├── csv-adapter.ts              # NEW: CSV file parser
│   ├── excel-adapter.ts            # NEW: XLSX file parser
│   └── openclaw-adapter.ts         # NEW: OpenClaw browser automation orchestrator
│
├── cli/
│   ├── onboard.ts                  # NEW: onboard command handler
│   └── schema.ts                   # UPDATE: add diff subcommand
│
├── core/
│   ├── mapping-engine.ts           # NEW: column→field mapping + value transforms
│   ├── auto-mapper.ts              # NEW: auto-detection of column mappings
│   └── schema-registry.ts          # UPDATE: add diff logic
│
├── validators/
│   └── computer-use-validator.ts   # NEW: Claude Computer Use UI checks
│
└── types/
    └── mapping.ts                  # NEW: mapping YAML type definitions

.github/
└── workflows/
    └── ci.yml                      # NEW: CI/CD pipeline

docs/
├── getting-started.md              # NEW: installation and first run guide
├── adding-scenarios.md             # NEW: how to create custom scenarios
├── customer-onboarding.md          # NEW: step-by-step onboarding guide
└── DATA-PROVENANCE.md              # UPDATE: finalize all source licensing
```

### 4.2 Auto-Mapping Algorithm

```typescript
function autoDetectMapping(
  columns: string[],
  entitySchemas: EntitySchema[]
): MappingProposal {
  // For each column header:
  // 1. Exact match against field display names
  // 2. Exact match against field logical names
  // 3. Fuzzy match (Levenshtein distance < 3)
  // 4. Common alias matching ("Matter Name" → sprk_name, "Attorney" → contact lookup)
  // 5. Score each candidate, pick best match above confidence threshold
  // Return proposed mapping with confidence scores
}
```

### 4.3 Dependencies to Add

```json
{
  "dependencies": {
    "exceljs": "^4.4.0",
    "csv-parse": "^5.5.0"
  }
}
```

---

## 5. Success Criteria

| Criterion | Measurement |
|-----------|-------------|
| **CSV import works** | Customer CSV file with 100 matters imports correctly |
| **Excel import works** | Multi-sheet XLSX with matters + contacts imports correctly |
| **Auto-mapping works** | `--mapping auto` correctly maps 80%+ of columns for common formats |
| **Dry run works** | `--dry-run` reports what would be imported without touching Dataverse |
| **Schema diff works** | Detects intentionally added/removed field in test environment |
| **npm install works** | `npm install -g @spaarke/data-cli && spaarke-data --version` succeeds |
| **CI pipeline works** | Push to master triggers build + test; tag triggers publish |
| **Onboarding guide complete** | Non-developer can follow `customer-onboarding.md` to import a CSV |
| **Multi-environment** | Same tool targets dev, staging, and customer environments via config |

---

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Customer data formats are wildly inconsistent | Auto-mapping fails; manual mapping needed | Provide mapping template + examples; document common formats; support `--preview` for iteration |
| OpenClaw dependency is unstable or discontinued | Harvesting feature doesn't work | Keep as optional; direct download fallback always works |
| Claude Computer Use accuracy too low for reliable UI validation | False positives/negatives in UI checks | Keep as supplementary, not blocking; human spot-check remains primary |
| npm scope `@spaarke` needs organization setup | Can't publish package | Set up npm org before Phase 3; or publish as unscoped `spaarke-data-cli` |
| Customer environments have customized schemas | Onboarding fails on non-standard entities | Schema diff catches this upfront; mapping files handle custom fields |
| Large customer files (10K+ rows) cause memory issues | Tool crashes on real-world data | Stream CSV/Excel parsing instead of loading entire file; test with large fixtures |

---

## 7. Deliverables

1. **CSV source adapter** (`src/adapters/csv-adapter.ts`)
2. **Excel source adapter** (`src/adapters/excel-adapter.ts`)
3. **Onboard command** (`src/cli/onboard.ts`)
4. **Mapping engine** + auto-mapper (`src/core/mapping-engine.ts`, `auto-mapper.ts`)
5. **Schema diff command** (update to `src/cli/schema.ts`)
6. **OpenClaw adapter** (`src/adapters/openclaw-adapter.ts`)
7. **Computer Use validator** (`src/validators/computer-use-validator.ts`)
8. **CI/CD pipeline** (`.github/workflows/ci.yml`)
9. **npm package** published to `@spaarke/data-cli`
10. **Documentation**: getting-started.md, adding-scenarios.md, customer-onboarding.md

---

## 8. Constraints

- **CLI only**: No web UI or desktop app — terminal-based tool only
- **Node.js 18+**: Required runtime; documented in package.json engines
- **Azure CLI required**: Authentication depends on `az login` being configured
- **Private npm scope**: Published to `@spaarke` org, not public registry
- **No data anonymization**: Customer data import assumes data is already sanitized; document this requirement

---

## 9. Inputs from Phase 2

| Phase 2 Output | How Phase 3 Uses It |
|----------------|---------------------|
| `validate` command | Extended with `--ui-check` for Computer Use validation |
| `schemas/*.schema.json` | Used by schema diff, auto-mapper, and onboarding validation |
| `harvest` command | Extended with `--use-openclaw` flag |
| Adapter pattern (CUAD, Caselaw) | Template for CSV/Excel adapter implementations |
| Transform layer | Reused for customer data value transformations |
| Scenario YAML format | Referenced in `adding-scenarios.md` documentation |
| Full demo environment | Used to test onboarding into a populated environment (no conflicts) |
