# ENSDEMO Namespace Classes

This directory contains ObjectScript classes downloaded from the ENSDEMO namespace of InterSystems IRIS, which provides demonstration classes for Ensemble/IRIS Interoperability features.

## Overview

ENSDEMO (Ensemble Demo) namespace contains comprehensive examples and demonstration classes for:
- InterSystems Ensemble/IRIS Interoperability framework
- Business Services, Business Processes, and Business Operations
- Data transformations and message routing
- Production configurations and monitoring
- Web services and REST API implementations

## Download Status

- **Source Namespace**: ENSDEMO
- **Total Classes Available**: 5,104 classes (1,646 non-% classes)
- **Downloaded Classes**: 203 non-% classes (partial download)
- **Download Method**: TypeScript client with filtering for non-% classes only
- **Download Date**: 2025-07-08
- **Status**: Partial download in progress - % classes filtered out to avoid duplicates with system/ directory

## Expected Contents

The ENSDEMO namespace typically includes:

### Interoperability Framework Classes
- **Business Services** - Inbound adapters and message processors
- **Business Processes** - Message routing and transformation logic
- **Business Operations** - Outbound adapters and external system connectors
- **Data Transformations** - Message format conversion utilities
- **Productions** - Complete interoperability solutions

### Sample Applications
- **Healthcare** - HL7 message processing examples
- **Financial** - SWIFT and financial messaging
- **Web Services** - SOAP and REST API demonstrations
- **File Processing** - Batch file handling examples
- **Database Integration** - SQL and database connectivity

### Development Tools
- **Testing Utilities** - Message testing and validation tools
- **Monitoring Components** - Production monitoring and alerting
- **Configuration Classes** - Setup and deployment utilities
- **Documentation Generators** - API and configuration documentation

### Dashboard and UI Components
- **CSPX.Dashboard.*** - Dashboard widget components:
  - Charts (Bar, Line, Pie)
  - Meters and Gauges
  - Grids and Tables
  - Indicators and Lamps

## File Organization

Classes maintain their original package structure:
```
CSPX.Dashboard.BarChart.cls
Ens.Production.cls
Demo.HL7.Router.cls
Sample.WebService.cls
```

## Usage

These classes serve as:
- **Learning Resources** - Understanding Ensemble/IRIS Interoperability patterns
- **Template Code** - Starting points for new integrations
- **Best Practices** - Recommended implementation approaches
- **Testing Examples** - Validation and testing methodologies

## System Classes

The ENSDEMO namespace contained 637 % system classes which were downloaded but subsequently removed to avoid duplicates. All system classes are available in the `../system/` directory which contains the complete collection of % classes from the SAMPLES namespace.

## Notes

The ENSDEMO namespace is one of the largest sample namespaces in InterSystems IRIS, containing extensive interoperability and integration examples. While % system classes were removed from this directory to avoid duplicates, they remain available in the centralized system/ directory.

The download used the TypeScript client which properly handles URL encoding for system classes containing the % character.