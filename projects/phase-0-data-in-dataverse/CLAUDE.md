# Phase 0: Data in Dataverse — Project Context

## Project Overview
Load Scenario 1 (Meridian Corp v. Pinnacle Industries) into Spaarke dev environment using PowerShell + Claude Code. No CLI infrastructure.

## Target Environment
- **Dataverse**: `https://spaarkedev1.crm.dynamics.com`
- **BFF API**: `https://spe-api-dev-67e2xz.azurewebsites.net`
- **Web API**: `{dataverse_url}/api/data/v9.2/{entity_collection}`
- **Auth**: `az account get-access-token --resource https://spaarkedev1.crm.dynamics.com`

## Scenario: Meridian Corp v. Pinnacle Industries
Patent infringement litigation. Meridian (client) vs Pinnacle (opposing). 6 months in with discovery deadlines, expert depositions, budget pressure.

## Entity ID Convention
All entity IDs use prefix `mvp-` (Meridian v. Pinnacle):
- Accounts: `mvp-acct-meridian`, `mvp-acct-pinnacle`, `mvp-acct-baker-llp`, `mvp-acct-chen-law`
- Contacts: `mvp-contact-chen`, `mvp-contact-morrison`, etc.
- Matter: `mvp-matter-001`
- Projects: `mvp-proj-discovery`, `mvp-proj-expert`, `mvp-proj-trial-prep`
- Documents: `mvp-doc-001` through `mvp-doc-080`
- Events: `mvp-event-001` through `mvp-event-060`

## Key Patterns
- **Upsert**: Use `PATCH` with alternate key for idempotency
- **Lookups**: Use `@odata.bind` format: `"sprk_Matter@odata.bind": "/sprk_matters(guid)"`
- **Throttling**: 500ms delay between API calls
- **Batch**: Dataverse `$batch` for up to 1000 operations
- **Email domains**: Use `@example.com` per RFC 2606

## Applicable Resources (from spaarke repo)
- `projects/ai-spaarke-platform-enhancements-r1/scripts/Invoke-DataverseApi.ps1` — Web API helper
- `projects/ai-spaarke-platform-enhancements-r1/scripts/Create-ActionSeedRecords.ps1` — Seed pattern
- `src/server/shared/Spaarke.Dataverse/Models.cs` — Entity field definitions
- `src/server/api/Sprk.Bff.Api/Api/UploadEndpoints.cs` — File upload endpoints

## 🚨 MANDATORY: Task Execution Protocol
When executing tasks for this project, Claude Code MUST invoke the `task-execute` skill.
See root CLAUDE.md for full protocol details.
