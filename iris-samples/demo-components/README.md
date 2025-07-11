# Demo Components

Basic demonstration components for InterSystems IRIS Interoperability.

## Components

### Business Components
- **Demo.FileService.cls** - Business Service that reads files
  - Uses EnsLib.File.InboundAdapter
  - Converts file content to Ens.StringRequest messages
  - Sends to Demo.FileOperation

- **Demo.FileOperation.cls** - Business Operation that writes files
  - Uses EnsLib.File.OutboundAdapter
  - Receives Ens.StringRequest messages
  - Writes content to timestamped files

### Production
- **Demo.Production.cls** - Production configuration (if exists)

## Purpose
These components provide basic examples of:
- File-based input/output processing
- String message handling
- Timestamped file generation
- Basic Business Service and Operation patterns

## Usage
1. Upload demo classes to IRIS
2. Configure production with these components
3. Test file processing workflow