#!/usr/bin/env node

import { Command } from 'commander';
import fs from 'fs';
import path from 'path';
import { IrisClient } from './iris-client';
import { ConnectionConfig } from './types';

const program = new Command();

// Load configuration
function loadConfig(configPath?: string): ConnectionConfig {
  const defaultConfigPath = path.join(__dirname, '..', 'config.json');
  const configFile = configPath || defaultConfigPath;
  
  try {
    const configData = fs.readFileSync(configFile, 'utf8');
    return JSON.parse(configData);
  } catch (error) {
    console.error(`Error loading config from ${configFile}:`, error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

// Verbose logging function
function verboseLog(message: string, verbose: boolean = false) {
  if (verbose) {
    console.log(`[VERBOSE] ${message}`);
  }
}

program
  .name('iris-client')
  .description('InterSystems IRIS Client Prototype')
  .version('1.0.0');

program
  .command('test')
  .description('Test connection to IRIS server')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog(`Configuration loaded: ${JSON.stringify(config, null, 2)}`, options.verbose);
    verboseLog(`Base URL: ${client['buildBaseUrl']?.() || 'N/A'}`, options.verbose);
    
    console.log('Testing connection to IRIS server...');
    console.log(`Target: ${client.getConnectionInfo()}`);
    
    try {
      const connected = await client.connect();
      if (connected) {
        console.log('✅ Connection successful!');
        console.log(`Authentication status: ${client.isAuthenticated() ? 'Authenticated' : 'Not authenticated'}`);
      } else {
        console.log('❌ Connection failed');
        process.exit(1);
      }
    } catch (error) {
      console.error('❌ Connection error:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('server-info')
  .description('Get server information')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog(`Connecting to ${client.getConnectionInfo()}`, options.verbose);
    
    try {
      const serverInfo = await client.getServerInfo();
      
      console.log('Server Information:');
      console.log(`  Version: ${serverInfo.version}`);
      console.log(`  ID: ${serverInfo.id}`);
      console.log(`  API Version: ${serverInfo.api}`);
      console.log(`  Available Namespaces: ${serverInfo.namespaces.length}`);
      
      if (options.verbose) {
        console.log(`\\nNamespaces: ${serverInfo.namespaces.join(', ')}`);
        console.log(`\\nFeatures:`);
        serverInfo.features.forEach(feature => {
          console.log(`  - ${feature.name}: ${feature.enabled}`);
        });
      }
      
    } catch (error) {
      console.error('❌ Error getting server info:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('namespaces')
  .description('List all available namespaces')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog(`Connecting to ${client.getConnectionInfo()}`, options.verbose);
    
    try {
      const namespaces = await client.getNamespaces();
      
      console.log(`Found ${namespaces.length} namespaces:`);
      namespaces.forEach((ns, index) => {
        console.log(`  ${index + 1}. ${ns}`);
      });
      
      if (options.verbose) {
        console.log(`\\nCurrent namespace: ${config.namespace || 'USER'}`);
        console.log(`Server: ${config.server}:${config.port}`);
      }
      
    } catch (error) {
      console.error('❌ Error getting namespaces:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('namespace-info')
  .description('Get information about a specific namespace')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Getting info for namespace: ${namespace}`, options.verbose);
    
    try {
      const result = await client.getNamespaceInfo(namespace);
      
      console.log(`Namespace Information for '${namespace}':`);
      if (result.result) {
        console.log(`  Status: ${result.status.summary || 'OK'}`);
        
        if (options.verbose) {
          console.log(`\\nFull response:`);
          console.log(JSON.stringify(result, null, 2));
        }
      }
      
    } catch (error) {
      console.error(`❌ Error getting namespace info for '${namespace}':`, error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('docs')
  .description('List documents in a namespace')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-t, --type <type>', 'Document type (CLS, RTN, CSP, OTH, *)', '*')
  .option('-f, --filter <pattern>', 'Name filter pattern')
  .option('-g, --generated', 'Include generated documents')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Listing documents in namespace: ${namespace}`, options.verbose);
    verboseLog(`Type filter: ${options.type}`, options.verbose);
    if (options.filter) verboseLog(`Name filter: ${options.filter}`, options.verbose);
    
    try {
      const result = await client.getDocumentList(
        namespace,
        '*',
        options.type,
        options.filter,
        options.generated
      );
      
      if (result.result.content) {
        const docs = result.result.content;
        console.log(`Found ${docs.length} documents in namespace '${namespace}':`);
        
        docs.forEach((doc: any, index: number) => {
          console.log(`  ${index + 1}. ${doc.name} (${doc.cat})`);
          if (options.verbose) {
            console.log(`     Modified: ${doc.ts}, Database: ${doc.db}`);
          }
        });
      }
      
    } catch (error) {
      console.error(`❌ Error listing documents:`, error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// ===== STEP 4: CLASS MANAGEMENT COMMANDS =====

program
  .command('classes')
  .description('List classes in a namespace')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-f, --filter <pattern>', 'Class name filter pattern')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Listing classes in namespace: ${namespace}`, options.verbose);
    if (options.filter) verboseLog(`Filter: ${options.filter}`, options.verbose);
    
    try {
      const result = await client.getClasses(namespace, options.filter);
      
      if (result.result?.content) {
        const classes = result.result.content;
        console.log(`Found ${classes.length} classes in namespace '${namespace}':`);
        
        classes.forEach((cls: any, index: number) => {
          console.log(`  ${index + 1}. ${cls.name}`);
          if (options.verbose) {
            console.log(`     Modified: ${cls.ts}, Database: ${cls.db}`);
          }
        });
      }
    } catch (error) {
      console.error('❌ Error listing classes:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('packages')
  .description('List packages in a namespace')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Listing packages in namespace: ${namespace}`, options.verbose);
    
    try {
      const packages = await client.getPackages(namespace);
      
      console.log(`Found ${packages.length} packages in namespace '${namespace}':`);
      packages.forEach((pkg, index) => {
        console.log(`  ${index + 1}. ${pkg}`);
      });
    } catch (error) {
      console.error('❌ Error listing packages:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('upload')
  .description('Upload a class file to IRIS')
  .argument('<className>', 'Class name (e.g., Test.Sample.cls)')
  .argument('<filePath>', 'Path to the class file')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('--no-overwrite', 'Prevent overwriting existing class')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (className, filePath, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Uploading class: ${className} from ${filePath}`, options.verbose);
    
    try {
      if (!fs.existsSync(filePath)) {
        console.error(`❌ File not found: ${filePath}`);
        process.exit(1);
      }
      
      const content = fs.readFileSync(filePath, 'utf8').split('\n');
      const result = await client.uploadClass(className, content, namespace, options.overwrite, true);
      
      if (result.status?.errors?.length > 0) {
        console.error('❌ Upload failed with errors:');
        result.status.errors.forEach(error => console.error(`  - ${error}`));
        process.exit(1);
      } else {
        console.log(`✅ Successfully uploaded class '${className}' to namespace '${namespace}'`);
        if (options.verbose) {
          console.log(`Status: ${result.status?.summary || 'OK'}`);
        }
      }
    } catch (error) {
      console.error('❌ Error uploading class:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('download')
  .description('Download a class from IRIS')
  .argument('<className>', 'Class name to download')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-o, --output <filePath>', 'Output file path (optional)')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (className, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Downloading class: ${className}`, options.verbose);
    
    try {
      const result = await client.downloadClass(className, namespace);
      
      if (result.result?.content) {
        const content = result.result.content.join('\n');
        
        if (options.output) {
          fs.writeFileSync(options.output, content);
          console.log(`✅ Class '${className}' downloaded to ${options.output}`);
        } else {
          console.log(`Class '${className}' content:`);
          console.log(content);
        }
        
        if (options.verbose) {
          console.log(`\\nClass info:`);
          console.log(`  Name: ${result.result.name}`);
          console.log(`  Category: ${result.result.cat}`);
          console.log(`  Modified: ${result.result.ts}`);
          console.log(`  Database: ${result.result.db}`);
        }
      }
    } catch (error) {
      console.error('❌ Error downloading class:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('download-package')
  .description('Download all classes in a package')
  .argument('<packageName>', 'Package name to download')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-d, --dir <directory>', 'Output directory (default: ./package_name)')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (packageName, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    const outputDir = options.dir || `./${packageName}`;
    
    verboseLog(`Downloading package: ${packageName}`, options.verbose);
    
    try {
      // Create output directory
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }
      
      const results = await client.downloadPackage(packageName, namespace);
      
      console.log(`Found ${results.length} classes in package '${packageName}':`);
      
      for (const result of results) {
        if (result.result?.content && result.result?.name) {
          const fileName = `${result.result.name}`;
          const filePath = path.join(outputDir, fileName);
          const content = result.result.content.join('\n');
          
          fs.writeFileSync(filePath, content);
          console.log(`  ✅ Downloaded: ${fileName}`);
          
          if (options.verbose) {
            console.log(`     Modified: ${result.result.ts}, Database: ${result.result.db}`);
          }
        }
      }
      
      console.log(`\\n✅ Package '${packageName}' downloaded to directory: ${outputDir}`);
    } catch (error) {
      console.error('❌ Error downloading package:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('compile')
  .description('Compile a class or multiple classes')
  .argument('<classNames...>', 'Class names to compile')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-f, --flags <flags>', 'Compilation flags', 'cuk')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (classNames, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Compiling classes: ${classNames.join(', ')}`, options.verbose);
    verboseLog(`Flags: ${options.flags}`, options.verbose);
    
    try {
      const result = await client.compileDocuments(classNames, namespace, options.flags);
      
      if (result.status?.errors?.length > 0) {
        console.error('❌ Compilation failed with errors:');
        result.status.errors.forEach(error => {
          if (typeof error === 'object') {
            console.error(`  - ${JSON.stringify(error, null, 2)}`);
          } else {
            console.error(`  - ${error}`);
          }
        });
        process.exit(1);
      } else {
        console.log(`✅ Successfully compiled ${classNames.length} class(es)`);
        
        if (result.console?.length > 0) {
          console.log('\\nCompilation output:');
          result.console.forEach(line => console.log(`  ${line}`));
        }
        
        if (options.verbose && result.result?.content) {
          console.log(`\\nCompiled documents: ${result.result.content.length}`);
        }
      }
    } catch (error) {
      console.error('❌ Error compiling classes:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('upload-compile')
  .description('Upload and compile a class file')
  .argument('<className>', 'Class name (e.g., Test.Sample.cls)')
  .argument('<filePath>', 'Path to the class file')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-f, --flags <flags>', 'Compilation flags', 'cuk')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (className, filePath, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    
    verboseLog(`Uploading and compiling class: ${className}`, options.verbose);
    
    try {
      if (!fs.existsSync(filePath)) {
        console.error(`❌ File not found: ${filePath}`);
        process.exit(1);
      }
      
      const content = fs.readFileSync(filePath, 'utf8').split('\n');
      const results = await client.uploadAndCompileClass(className, content, namespace, options.flags);
      
      // Check upload result
      if (results.upload.status?.errors?.length > 0) {
        console.error('❌ Upload failed with errors:');
        results.upload.status.errors.forEach(error => {
          if (typeof error === 'object') {
            console.error(`  - ${JSON.stringify(error, null, 2)}`);
          } else {
            console.error(`  - ${error}`);
          }
        });
        process.exit(1);
      }
      
      console.log(`✅ Successfully uploaded class '${className}'`);
      
      // Check compilation result
      if (results.compile.status?.errors?.length > 0) {
        console.error('❌ Compilation failed with errors:');
        results.compile.status.errors.forEach(error => {
          if (typeof error === 'object') {
            console.error(`  - ${JSON.stringify(error, null, 2)}`);
          } else {
            console.error(`  - ${error}`);
          }
        });
        process.exit(1);
      }
      
      console.log(`✅ Successfully compiled class '${className}'`);
      
      if (results.compile.console?.length > 0) {
        console.log('\\nCompilation output:');
        results.compile.console.forEach(line => console.log(`  ${line}`));
      }
    } catch (error) {
      console.error('❌ Error uploading and compiling class:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('query')
  .description('Execute an SQL query')
  .argument('<sql>', 'SQL query to execute')
  .option('-n, --namespace <name>', 'Namespace name')
  .option('-p, --parameters <params...>', 'Query parameters')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (sql, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    const namespace = options.namespace || config.namespace;
    const parameters = options.parameters || [];
    
    verboseLog(`Executing SQL query in namespace: ${namespace}`, options.verbose);
    verboseLog(`Query: ${sql}`, options.verbose);
    if (parameters.length > 0) verboseLog(`Parameters: ${parameters.join(', ')}`, options.verbose);
    
    try {
      const result = await client.executeQuery(sql, parameters, namespace);
      
      if (result.status?.errors?.length > 0) {
        console.error('❌ Query execution failed with errors:');
        result.status.errors.forEach(error => console.error(`  - ${error}`));
        process.exit(1);
      } else {
        console.log('✅ Query executed successfully');
        
        if (result.result?.content) {
          const content = result.result.content;
          if (Array.isArray(content) && content.length > 0) {
            console.log(`\nResults (${content.length} rows):`);
            
            // Display first few rows in a readable format
            const displayRows = Math.min(content.length, 10);
            for (let i = 0; i < displayRows; i++) {
              const row = content[i];
              if (typeof row === 'object') {
                console.log(`  Row ${i + 1}: ${JSON.stringify(row)}`);
              } else {
                console.log(`  Row ${i + 1}: ${row}`);
              }
            }
            
            if (content.length > 10) {
              console.log(`  ... and ${content.length - 10} more rows`);
            }
          } else {
            console.log('\nQuery executed with no results.');
          }
        }
        
        if (options.verbose) {
          console.log('\nFull response:');
          console.log(JSON.stringify(result, null, 2));
        }
      }
    } catch (error) {
      console.error('❌ Error executing query:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// =============================================================================
// PRODUCTION MANAGEMENT COMMANDS (Step 5)
// =============================================================================

program
  .command('prod-test')
  .description('Test the production management API (Step 5)')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog('Testing production management API...', options.verbose);
    
    try {
      const result = await client.testProductionApi();
      
      if (result && result.success === 1) {
        console.log('✅ Production management API is working');
        if (options.verbose) {
          console.log('\nAPI Test Response:');
          console.log(JSON.stringify(result, null, 2));
        }
      } else {
        console.log('❌ Production management API test failed');
        console.log(JSON.stringify(result, null, 2));
        process.exit(1);
      }
    } catch (error) {
      console.error('❌ Error testing production API:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('prod-status')
  .description('Get production management API status (Step 5)')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog('Getting production management API status...', options.verbose);
    
    try {
      const result = await client.getProductionApiStatus();
      
      console.log('✅ Production API Status:');
      console.log(`  API: ${result.api} v${result.version}`);
      console.log(`  Project: ${result.project || 'N/A'}`);
      console.log(`  Step: ${result.step || 'N/A'}`);
      console.log(`  Namespace: ${result.namespace}`);
      console.log(`  Server: ${result.server}`);
      console.log(`  Ensemble Available: ${result.ensembleAvailable}`);
      console.log(`  Production Count: ${result.productionCount}`);
      console.log(`  Web App Path: ${result.webAppPath || 'N/A'}`);
      console.log(`  Endpoints: ${result.endpoints ? result.endpoints.join(', ') : 'N/A'}`);
      
      if (options.verbose) {
        console.log('\nFull Status Response:');
        console.log(JSON.stringify(result, null, 2));
      }
    } catch (error) {
      console.error('❌ Error getting production API status:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('prod-list')
  .description('List all productions in the namespace (Step 5)')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog('Listing productions...', options.verbose);
    
    try {
      const result = await client.getProductionInfo(options.verbose);
      
      console.log('✅ Production List:');
      console.log(`  Namespace: ${result.namespace}`);
      console.log(`  Ensemble Available: ${result.ensembleAvailable}`);
      console.log(`  Production Count: ${result.count}`);
      
      if (result.productions && result.productions.length > 0) {
        console.log('\n  Productions:');
        result.productions.forEach((prod, i) => {
          console.log(`    ${i + 1}. ${prod.Name}`);
          console.log(`       Status: ${prod.Status}`);
          if (prod.State) console.log(`       State: ${prod.State}`);
          if (prod.AutoStart !== undefined) console.log(`       Auto Start: ${prod.AutoStart}`);
          if (prod.LastStartTime) console.log(`       Last Start: ${prod.LastStartTime}`);
          if (prod.LastStopTime) console.log(`       Last Stop: ${prod.LastStopTime}`);
          console.log('');
        });
      } else {
        console.log('\n  No productions found in this namespace.');
        if (!result.ensembleAvailable) {
          console.log('  Note: Ensemble/Interoperability may not be enabled in this namespace.');
        }
      }
      
      if (options.verbose) {
        console.log('\nFull Production List Response:');
        console.log(JSON.stringify(result, null, 2));
      }
    } catch (error) {
      console.error('❌ Error listing productions:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('prod-check')
  .description('Check if production management API is available (Step 5)')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog('Checking production management API availability...', options.verbose);
    
    try {
      const available = await client.isProductionApiAvailable();
      
      if (available) {
        console.log('✅ Production management API is available and working');
        
        if (options.verbose) {
          // Also get detailed status when verbose
          const status = await client.getProductionApiStatus();
          console.log('\nDetailed API Status:');
          console.log(`  API: ${status.api} v${status.version}`);
          console.log(`  Web App Path: ${status.webAppPath}`);
          console.log(`  Ensemble: ${status.ensembleAvailable ? 'Available' : 'Not Available'}`);
        }
      } else {
        console.log('❌ Production management API is not available');
        console.log('   Please ensure:');
        console.log('   - IRIS server is running');
        console.log('   - Api.MCPInterop REST API is deployed');
        console.log('   - Web application /api/mcp-interop exists');
        process.exit(1);
      }
    } catch (error) {
      console.error('❌ Error checking production API:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// =============================================================================
// EXECUTE COMMANDS (Step 6.1)
// =============================================================================

program
  .command('execute')
  .description('Execute ObjectScript code (Step 6.1)')
  .argument('<code>', 'ObjectScript code to execute')
  .option('-c, --config <path>', 'Configuration file path')
  .option('-t, --timeout <ms>', 'Execution timeout in milliseconds')
  .option('-v, --verbose', 'Verbose output')
  .action(async (code, options) => {
    const config = loadConfig(options.config);
    const client = new IrisClient(config);
    
    verboseLog(`Executing ObjectScript code...`, options.verbose);
    verboseLog(`Code: ${code}`, options.verbose);
    if (options.timeout) verboseLog(`Timeout: ${options.timeout}ms`, options.verbose);
    
    try {
      const result = await client.executeCode(code, options.timeout);
      
      if (result.success === 1) {
        console.log('✅ Code executed successfully');
        console.log(`  Result: ${result.result}`);
        
        if (result.returnValue !== undefined) {
          console.log(`  Return Value: ${result.returnValue}`);
        }
        
        if (options.verbose) {
          console.log('\nFull Response:');
          console.log(JSON.stringify(result, null, 2));
        }
      } else {
        console.log('❌ Code execution failed');
        console.log(`  Error: ${result.error}`);
        process.exit(1);
      }
    } catch (error) {
      console.error('❌ Error executing code:', error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

// Parse command line arguments
program.parse();