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

// Parse command line arguments
program.parse();