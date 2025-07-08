# IRIS Sample Classes

This directory contains sample InterSystems IRIS ObjectScript classes for testing upload/download functionality.

## Directory Structure

- **`upload/`** - Sample classes ready for upload to IRIS
- **`download/`** - Downloaded classes from IRIS for verification

## Sample Classes for Upload

### Test.Sample.cls
Basic ObjectScript class demonstrating properties and methods.

### Test.REST.cls  
REST API class extending %CSP.REST with sample endpoints.

### Test.Utility.cls
Utility class with static methods for common operations.

## Usage

### With client-proto TypeScript client:
```bash
# Upload a class
npm run build && node dist/index.js upload Test.Sample.cls ../iris-samples/upload/Test.Sample.cls

# Download a class  
npm run build && node dist/index.js download Test.Sample.cls
```

### With curl-test scripts:
The curl-test scripts use these samples as reference but generate their own test classes inline for consistency.

### With exec-proto:
The exec-proto classes are stored separately in `exec-proto/server-classes/` as they are working deployed classes.

## Class Descriptions

- **Test.Sample.cls**: Demonstrates basic ObjectScript syntax, properties, and methods
- **Test.REST.cls**: Shows REST API implementation patterns using %CSP.REST
- **Test.Utility.cls**: Contains utility methods and demonstrates class method usage

These classes serve as examples for understanding IRIS class structure and can be used for testing upload/download functionality across the project.