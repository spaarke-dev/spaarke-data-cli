# Phase 0: Data in Dataverse

> **Status**: In Progress
> **Timeline**: 3-5 days
> **Branch**: `work/phase-0-data-in-dataverse`

## Purpose

Load the first complete demo scenario ("Meridian Corp v. Pinnacle Industries" — active patent litigation) into the Spaarke dev environment using PowerShell scripts and Claude Code for data generation. No CLI infrastructure — validate the scenario design and loading process before building tooling.

## Graduation Criteria

- [ ] ~220-350 Dataverse records loaded across all entity types
- [ ] 20-30 document files uploaded to SharePoint Embedded
- [ ] AI enrichment fields populated on all document records
- [ ] Loading scripts are idempotent (re-runnable without duplicates)
- [ ] DATA-PROVENANCE.md documents all data sources
- [ ] Data renders correctly on Dataverse forms (manual spot-check)

## Quick Links

- [Specification](spec.md)
- [Implementation Plan](plan.md)
- [Task Index](tasks/TASK-INDEX.md)
- [Parent Design Document](https://github.com/spaarke-dev/spaarke/blob/master/projects/spaarke-demo-data-setup-r1/design.md)
