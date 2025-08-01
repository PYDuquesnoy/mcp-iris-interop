# Legacy InterSystems IRIS Samples

This directory contains ObjectScript classes downloaded from multiple namespaces of InterSystems IRIS, providing comprehensive collections of sample code, demonstrations, and system classes for reference and learning.

## Directory Structure

- `cachesamples/` - Contains 406 non-% ObjectScript class files from the SAMPLES namespace (3.0MB total)
- `system/` - Contains 3,458 % system classes from SAMPLES namespace (47MB total) 
- `cacheensdemo/` - Contains 203 non-% interoperability classes from ENSDEMO namespace (1.2MB total)
- `ensLib/` - Contains 1,276 Ens/EnsLib/EnsPortal classes from IRISAPP namespace (14MB total) - **Complete Interoperability Framework**

## Contents

The downloaded classes include a wide variety of InterSystems IRIS sample code organized into several categories:

### Core Sample Classes
- **Sample.*** - Basic sample classes demonstrating core functionality:
  - `Sample.Person.cls` - Person class with embedded objects and indices
  - `Sample.Company.cls` - Company management example
  - `Sample.Employee.cls` - Employee data modeling
  - `Sample.Address.cls` - Address handling with embedded objects
  - `Sample.Customer.cls` - Customer relationship management

### Aviation Demo
- **Aviation.*** - NTSB aviation safety data demonstration:
  - Aircraft, Crew, Event classes for aviation incident tracking
  - DeepSee cubes for aviation data analysis
  - KPI and reporting classes

### Business Intelligence & Analytics
- **DeepSee.*** - Comprehensive DeepSee/Analytics samples:
  - Study classes (Patient, Doctor, Diagnosis, etc.)
  - Model classes for cubes and KPIs
  - Dashboard and widget examples
  - PMML (Predictive Model Markup Language) implementations

### Web Development Samples
- **ZEN*** - Zen application framework examples:
  - ZENApp - Application development samples
  - ZENDemo - Component and widget demonstrations
  - ZENMobile - Mobile application examples
  - ZENTest - Testing framework samples
  - ZENMVC - Model-View-Controller pattern examples

### Data Mining & Machine Learning
- **DataMining.*** - Data mining and analytics:
  - Cluster analysis examples
  - IRIS dataset samples
  - PMML model implementations

### HoleFoods Demo
- **HoleFoods.*** - Complete business application example:
  - Transaction processing
  - Product and outlet management
  - Regional analysis and reporting

### Web Services & Integration
- **SOAP.*** - Web services examples
- **REST.*** - REST API demonstrations
- **INFORMATION.SCHEMA.*** - Information schema views

### Other Notable Categories
- **Cinema.*** - Movie theater management system
- **News.*** - News article processing and analysis
- **Wasabi.*** - Order entry and product management
- **User.*** - User management and authentication
- **Studio.*** - Development environment extensions

## System Classes

The collection also includes InterSystems system classes (those starting with %) that provide:
- DeepSee framework components
- PMML (Predictive Model Markup Language) definitions
- Collection and data type classes
- Compiler and development tools
- CSP (Cache Server Pages) framework
- Database and persistence utilities

## Usage

These classes serve as:
- **Learning Resources** - Understand InterSystems IRIS development patterns
- **Code Examples** - Reference implementations for common tasks
- **Template Code** - Starting points for new development
- **Best Practices** - Demonstration of recommended coding approaches

## Download Information

### SAMPLES Namespace
- **Source**: SAMPLES namespace from InterSystems IRIS instance
- **Download Date**: 2025-07-08
- **Files**: 406 classes (non-% classes only)
- **Size**: 3.0MB
- **Method**: Custom script filtering out % system classes

### SAMPLES System Classes
- **Source**: SAMPLES namespace % system classes
- **Download Date**: 2025-07-08
- **Files**: 3,458 classes (% classes, download completed)
- **Size**: 47MB
- **Method**: TypeScript client with proper URL encoding

### ENSDEMO Namespace
- **Source**: ENSDEMO namespace from InterSystems IRIS instance  
- **Download Date**: 2025-07-08
- **Files**: 203 non-% interoperability classes
- **Size**: 1.2MB
- **Method**: Custom script filtering non-% classes (Demo.*, CSPX.*)

### IRISAPP Namespace (Ens/EnsLib Framework)
- **Source**: IRISAPP namespace from InterSystems IRIS instance
- **Download Date**: 2025-07-10
- **Files**: 1,276 Ens/EnsLib/EnsPortal classes
- **Size**: 14MB
- **Content**: Complete InterSystems IRIS Interoperability framework
- **Method**: Custom script accessing mapped classes via IRISAPP
- **Critical Classes**: EnsLib.Testing.Service, EnsLib.Testing.Request, EnsPortal.TestingService

## File Organization

Classes are stored with their original names including package structure:
```
Sample.Person.cls
Aviation.Aircraft.cls
DeepSee.Study.Patient.cls
ZENApp.HelpDesk.cls
HoleFoods.Transaction.cls
```

This maintains the original namespace and package organization for easy reference and potential import into other IRIS instances.