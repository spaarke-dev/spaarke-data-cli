/**
 * Type definitions for CLI configuration.
 */

export interface EnvironmentConfig {
  dataverse_url: string;
  bff_api_url: string;
  search_url: string;
  description?: string;
}

export interface EnvironmentsFile {
  environments: Record<string, EnvironmentConfig>;
}

export interface DefaultsConfig {
  generation: {
    volumes: Record<string, VolumePreset>;
    ai_model: string;
    output_dir: string;
    output_format: "json" | "cmt";
  };
  loading: {
    method: "webapi" | "cmt";
    batch_size: number;
    retry_count: number;
    retry_delay_ms: number;
  };
  validation: {
    check_lookups: boolean;
    min_records_per_scenario: number;
  };
}

export interface VolumePreset {
  documents_per_matter: number;
  events_per_matter: number;
  communications_per_matter: number;
  total_documents_target: number;
}
