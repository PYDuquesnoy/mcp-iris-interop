# Simple Production Test

Basic file passthrough test using InterSystems IRIS Interoperability.

## Components

### Production
- **Test.SimpleProduction.cls** - Simple production for API testing
  - File service that monitors `/home/irisowner/dev/shared/in` for `*.txt` files
  - File operation that writes to `/home/irisowner/dev/shared/out`
  - Uses EnsLib.File.PassthroughService and EnsLib.File.PassthroughOperation

## Purpose
This test was used to:
- Verify basic production functionality
- Test file processing workflow
- Validate API endpoints for production management
- Demonstrate simple file passthrough without transformation

## Usage
1. Upload Test.SimpleProduction.cls to IRIS
2. Start the production
3. Place `.txt` files in the input directory
4. Files are copied to the output directory with timestamp suffixes