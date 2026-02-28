/**
 * Type definitions for scenario YAML files.
 */

export interface ScenarioDefinition {
  name: string;
  description: string;
  type: "litigation" | "corporate" | "compliance" | "estate" | "management";
  matters: MatterDefinition[];
  shared_entities?: SharedEntityRef[];
}

export interface MatterDefinition {
  name: string;
  matter_type: string;
  practice_area: string;
  status: string;
  parties: PartyDefinition[];
  documents: DocumentDefinition[];
  events: EventDefinition[];
  financials?: FinancialDefinition;
}

export interface PartyDefinition {
  role: string;
  name: string;
  type: "organization" | "individual";
}

export interface DocumentDefinition {
  title: string;
  document_type: string;
  source: "template" | "cuad" | "caselaw" | "synthetic";
  template?: string;
  ai_enrichment: boolean;
}

export interface EventDefinition {
  type: string;
  description: string;
  relative_date: string; // e.g., "-30d", "+7d", "filing_date"
}

export interface FinancialDefinition {
  budget_amount: number;
  invoice_count: number;
  currency: string;
}

export interface SharedEntityRef {
  type: string;
  ref: string; // reference to _shared-entities.yaml
}
