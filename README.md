# Spaarke Data CLI

> Scenario-driven data generation, loading, and environment management for the Spaarke platform.

## Overview

`spaarke-data` is a CLI tool that generates, loads, validates, and resets demo/test data across the Spaarke platform's data layers:

- **Dataverse records** — Matters, Documents, Events, Invoices, Contacts, and more
- **SharePoint Embedded files** — PDFs, DOCX, EML, XLSX with realistic legal content
- **Azure AI Search indexes** — Pre-built search documents for semantic search
- **AI enrichment profiles** — Pre-baked summaries, keywords, entities, classifications

## Use Cases

| Use Case | Data Source | Who Runs It |
|----------|-----------|-------------|
| **Internal demo** | Open datasets + synthetic | Developers, sales engineers |
| **Customer-tailored demo** | Open data with customer branding | Sales engineers |
| **Customer onboarding** | Customer's actual data (CSV, Excel) | Onboarding team |
| **Environment refresh** | Seed files or snapshots | DevOps, QA |

## Quick Start

```bash
# Install dependencies
npm install

# Generate demo data for all scenarios
npm run dev -- generate --scenario all

# Load into dev environment
npm run dev -- load --target dev

# Validate loaded data
npm run dev -- validate --target dev
```

## Commands

```bash
spaarke-data generate   # Generate seed data from scenario definitions
spaarke-data load       # Load generated data into a target environment
spaarke-data validate   # Validate loaded data against expectations
spaarke-data reset      # Reset environment (wipe + reload)
spaarke-data schema     # Inspect and export Dataverse schema
spaarke-data harvest    # Download open legal datasets
spaarke-data onboard    # Customer onboarding — import from external sources
```

Use `--help` on any command for full options.

## Built-in Demo Scenarios

1. **Meridian v. Pinnacle** — Active commercial litigation with discovery documents
2. **Atlas/Horizon Acquisition** — M&A due diligence with corporate documents
3. **Compliance Audit** — Regulatory review with policy documents
4. **Morrison Estate** — Estate planning and administration
5. **Outside Counsel Management** — Multi-firm legal spend and budgeting

## Project Structure

```
src/
├── cli/          # Command handlers (Commander.js)
├── core/         # Pipeline engine, scenario loader, schema registry
├── adapters/     # Source adapters (Claude, CSV, CUAD, Caselaw, etc.)
├── transforms/   # Data transformers (entity, document, activity, enrichment)
├── loaders/      # Target loaders (CMT, Web API, SPE, AI Search)
├── validators/   # Post-load validation (MCP, counts, relationships)
└── types/        # Shared TypeScript types

config/           # Environment configs and defaults
scenarios/        # Built-in demo scenario YAML definitions
schemas/          # Dataverse entity schemas (exported from live)
templates/        # Document content templates
mappings/         # Customer onboarding mapping configs
```

## Design Document

Full design specification: [`spaarke/projects/spaarke-demo-data-setup-r1/design.md`](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md)

## License

Proprietary — Spaarke
