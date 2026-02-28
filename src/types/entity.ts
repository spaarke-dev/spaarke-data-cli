/**
 * Type definitions for Dataverse entity schemas and records.
 */

export interface EntitySchema {
  logical_name: string;
  display_name: string;
  primary_key: string;
  primary_name_attribute: string;
  fields: FieldDefinition[];
  relationships: RelationshipDefinition[];
}

export interface FieldDefinition {
  logical_name: string;
  display_name: string;
  type: FieldType;
  required: boolean;
  max_length?: number;
  option_set?: OptionSetValue[];
}

export type FieldType =
  | "string"
  | "memo"
  | "integer"
  | "decimal"
  | "money"
  | "boolean"
  | "datetime"
  | "lookup"
  | "optionset"
  | "uniqueidentifier";

export interface OptionSetValue {
  value: number;
  label: string;
}

export interface RelationshipDefinition {
  name: string;
  type: "many-to-one" | "one-to-many" | "many-to-many";
  related_entity: string;
  lookup_field?: string;
}

export interface EntityRecord {
  [key: string]: unknown;
}
