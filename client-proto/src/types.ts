// Type definitions for IRIS Atelier API

export interface ConnectionConfig {
  server: string;
  port: number;
  pathPrefix?: string;
  username: string;
  password: string;
  https?: boolean;
  namespace?: string;
}

export interface ResponseStatus {
  errors: string[];
  summary: string;
}

export interface AtelierResponse<T = any> {
  status: ResponseStatus;
  console: string[];
  result: T;
  retryafter?: string;
}

export interface ServerInfo {
  version: string;
  id: string;
  api: number;
  features: Array<{ name: string; enabled: string }>;
  namespaces: string[];
}

export interface Document {
  name: string;
  db: string;
  ts: string;
  upd: boolean;
  cat: "RTN" | "CLS" | "CSP" | "OTH";
  status: string;
  enc: boolean;
  flags: number;
  content: string[] | Buffer;
}

export interface Namespace {
  name: string;
  status: string;
}