# IRIS Samples - InterSystems IRIS Interoperability Examples

This directory contains various InterSystems IRIS Interoperability examples and test cases organized by functionality.

## Directory Structure

### [csv-to-xml/](csv-to-xml/)
Complete CSV to XML conversion workflow demonstrating:
- File-based message processing
- CSV parsing and XML generation
- Business Service and Operation patterns
- Production configuration with settings
- Message tracing and session management

### [simple-production-test/](simple-production-test/)
Basic file passthrough test for:
- Production API testing
- Simple file processing workflow
- Basic component validation

### [demo-components/](demo-components/)
Demonstration components showing:
- Basic Business Service and Operation patterns
- File input/output processing
- String message handling

### [step5-production-api/](step5-production-api/)
Production Management API testing:
- API endpoint validation
- Production lifecycle management
- Status monitoring

### [download/](download/)
Downloaded classes for testing and reference

### [upload/](upload/)
Test classes for upload functionality validation

## Legacy Files
- **Simple.Production.cls** - Basic production configuration
- **Testing.Production.cls** - Production for testing workflows
- **Test.StoredProc.cls** - Stored procedure examples

## Usage
Each subdirectory contains:
- `.cls` files with InterSystems IRIS class definitions
- `README.md` with specific documentation
- Sample data files where applicable

Upload the classes to your IRIS instance and follow the individual README files for testing procedures.

## Testing Examples

### CSV to XML Processing
```bash
# Upload and test CSV to XML workflow
node dist/index.js upload-compile CSV.PersonRecord.cls ../iris-samples/csv-to-xml/CSV.PersonRecord.cls
node dist/index.js upload-compile CSV.FileService.cls ../iris-samples/csv-to-xml/CSV.FileService.cls
node dist/index.js upload-compile CSV.XMLFileOperation.cls ../iris-samples/csv-to-xml/CSV.XMLFileOperation.cls
node dist/index.js upload-compile CSV.ProcessingProduction.cls ../iris-samples/csv-to-xml/CSV.ProcessingProduction.cls

# Start production and test
node dist/index.js prod-start --production CSV.ProcessingProduction
```

### Production Management
```bash
# List all productions
node dist/index.js prod-list

# Export logs and traces
node dist/index.js export-event-log --max-entries 20
node dist/index.js export-message-trace --max-entries 10
```