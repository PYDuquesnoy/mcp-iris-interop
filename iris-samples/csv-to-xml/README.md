# CSV to XML Processing Test

This test demonstrates a complete CSV to XML conversion workflow using InterSystems IRIS Interoperability.

## Components

### Message Classes
- **CSV.PersonRecord.cls** - Message class representing a person record from CSV data
  - Properties: Firstname, Lastname, DOB, Address
  - Methods: XML export, CSV parsing, display formatting

### Business Components
- **CSV.FileService.cls** - Business Service that reads CSV files
  - Uses EnsLib.File.InboundAdapter
  - Parses CSV lines into PersonRecord messages
  - Sends messages asynchronously for processing

- **CSV.XMLFileOperation.cls** - Business Operation that writes XML files
  - Uses EnsLib.File.OutboundAdapter
  - Receives PersonRecord messages
  - Converts to XML and writes individual files

### Production
- **CSV.ProcessingProduction.cls** - Production configuration
  - Monitors `/home/irisowner/dev/shared/in` for `*.csv` files
  - Processes through FileService → XMLFileOperation chain
  - Outputs XML files to `/home/irisowner/dev/shared/out`
  - Has testing enabled and SessionScope set to Message

## Test Data
- **sample-people.csv** - Sample CSV file with 4 person records

## Expected Results

### Input CSV Format
```csv
John,Doe,1985-03-15,123 Main St
Jane,Smith,1990-07-22,456 Oak Ave
Bob,Johnson,1978-12-03,789 Pine Rd
Alice,Williams,1992-05-18,321 Elm St
```

### Output XML Format
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Person>
  <Firstname>John</Firstname>
  <Lastname>Doe</Lastname>
  <DOB>1985-03-15</DOB>
  <Address>123 Main St</Address>
</Person>
```

## Features Demonstrated
- File-based message processing
- CSV parsing and validation
- XML generation with proper escaping
- Asynchronous message flow
- Production configuration with settings
- Message tracing and logging

## Usage
1. Upload all classes to IRIS
2. Start the CSV.ProcessingProduction
3. Copy sample-people.csv to the input directory
4. Check output directory for generated XML files