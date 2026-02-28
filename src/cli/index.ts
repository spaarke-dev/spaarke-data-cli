#!/usr/bin/env node

import { Command } from "commander";

const program = new Command();

program
  .name("spaarke-data")
  .description(
    "Scenario-driven data generation, loading, and environment management for the Spaarke platform"
  )
  .version("0.1.0");

// ─── GENERATE ────────────────────────────────────────────────────
program
  .command("generate")
  .description("Generate seed data from a scenario definition")
  .requiredOption(
    "-s, --scenario <name>",
    'Scenario name or "all" for all scenarios'
  )
  .option(
    "-v, --volume <level>",
    "Volume level: light (~100 docs) or full (~500+ docs)",
    "full"
  )
  .option(
    "-l, --layer <layer>",
    "Generate only a specific layer: records, documents, activity"
  )
  .option("-c, --config <path>", "Path to custom scenario YAML file")
  .action(async (options) => {
    console.log("generate command — not yet implemented", options);
  });

// ─── LOAD ────────────────────────────────────────────────────────
program
  .command("load")
  .description("Load generated data into a target environment")
  .requiredOption(
    "-t, --target <env>",
    "Target environment name or Dataverse URL"
  )
  .option("-d, --data <path>", "Path to generated data directory", "./output/")
  .option(
    "-l, --layer <layer>",
    "Load only a specific layer: records, files, search-index"
  )
  .action(async (options) => {
    console.log("load command — not yet implemented", options);
  });

// ─── VALIDATE ────────────────────────────────────────────────────
program
  .command("validate")
  .description("Validate loaded data against expectations")
  .requiredOption("-t, --target <env>", "Target environment name or URL")
  .option("-s, --scenario <name>", "Validate a specific scenario only")
  .option("--verbose", "Show detailed per-entity report")
  .action(async (options) => {
    console.log("validate command — not yet implemented", options);
  });

// ─── RESET ───────────────────────────────────────────────────────
program
  .command("reset")
  .description("Reset environment — wipe and optionally reload")
  .requiredOption("-t, --target <env>", "Target environment name or URL")
  .option("-s, --scenario <name>", "Reset a specific scenario only")
  .option("--confirm", "Skip confirmation prompt (required for non-interactive)")
  .action(async (options) => {
    console.log("reset command — not yet implemented", options);
  });

// ─── SCHEMA ──────────────────────────────────────────────────────
const schema = program
  .command("schema")
  .description("Inspect and export Dataverse schema");

schema
  .command("export")
  .description("Export entity schemas from a target environment")
  .requiredOption("-t, --target <env>", "Target environment name or URL")
  .option("-o, --output <path>", "Output directory", "./schemas/")
  .action(async (options) => {
    console.log("schema export — not yet implemented", options);
  });

schema
  .command("diff")
  .description("Compare local schemas against a target environment")
  .requiredOption("-s, --source <path>", "Local schema directory")
  .requiredOption("-t, --target <env>", "Target environment name or URL")
  .action(async (options) => {
    console.log("schema diff — not yet implemented", options);
  });

// ─── HARVEST ─────────────────────────────────────────────────────
program
  .command("harvest")
  .description("Download open legal datasets")
  .argument("<dataset>", 'Dataset name: cuad, caselaw, all')
  .option("-q, --query <query>", "Search query (for caselaw)")
  .option("-o, --output <path>", "Output directory", "./sources/")
  .action(async (dataset, options) => {
    console.log(`harvest ${dataset} — not yet implemented`, options);
  });

// ─── ONBOARD ─────────────────────────────────────────────────────
program
  .command("onboard")
  .description("Customer onboarding — import from external data sources")
  .requiredOption("-s, --source <path>", "Path to customer data file (CSV, XLSX)")
  .requiredOption("-t, --target <env>", "Target environment name or URL")
  .option(
    "-m, --mapping <path>",
    'Path to mapping YAML or "auto" for auto-detection',
    "auto"
  )
  .action(async (options) => {
    console.log("onboard command — not yet implemented", options);
  });

program.parse();
