#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const iris_client_1 = require("./iris-client");
const program = new commander_1.Command();
// Load configuration
function loadConfig(configPath) {
    const defaultConfigPath = path_1.default.join(__dirname, '..', 'config.json');
    const configFile = configPath || defaultConfigPath;
    try {
        const configData = fs_1.default.readFileSync(configFile, 'utf8');
        return JSON.parse(configData);
    }
    catch (error) {
        console.error(`Error loading config from ${configFile}:`, error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
}
// Verbose logging function
function verboseLog(message, verbose = false) {
    if (verbose) {
        console.log(`[VERBOSE] ${message}`);
    }
}
program
    .name('exec-proto')
    .description('ObjectScript Code Execution Prototype')
    .version('1.0.0');
program
    .command('test')
    .description('Test connection to IRIS server')
    .option('-c, --config <path>', 'Configuration file path')
    .option('-v, --verbose', 'Verbose output')
    .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new iris_client_1.IrisClient(config);
    verboseLog(`Configuration loaded: ${JSON.stringify(config, null, 2)}`, options.verbose);
    verboseLog(`Base URL: ${client.getConnectionInfo()}`, options.verbose);
    console.log('Testing connection to IRIS server...');
    console.log(`Target: ${client.getConnectionInfo()}`);
    try {
        const isConnected = await client.testConnection();
        if (isConnected) {
            console.log('✅ Connection successful');
        }
        else {
            console.log('❌ Connection failed');
            process.exit(1);
        }
    }
    catch (error) {
        console.error('❌ Connection error:', error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
});
program
    .command('execute')
    .description('Execute ObjectScript code')
    .argument('<code>', 'ObjectScript code to execute')
    .option('-c, --config <path>', 'Configuration file path')
    .option('-v, --verbose', 'Verbose output')
    .action(async (code, options) => {
    const config = loadConfig(options.config);
    const client = new iris_client_1.IrisClient(config);
    verboseLog(`Executing code: ${code}`, options.verbose);
    verboseLog(`Target: ${client.getConnectionInfo()}`, options.verbose);
    try {
        const result = await client.executeObjectScript(code);
        if (result.success) {
            console.log('✅ Code executed successfully');
            if (result.result) {
                console.log('Result:', result.result);
            }
            if (result.output) {
                console.log('Output:', result.output);
            }
            if (result.executionTime) {
                console.log('Execution time:', result.executionTime, 'ms');
            }
        }
        else {
            console.log('❌ Code execution failed');
            console.error('Error:', result.error);
            process.exit(1);
        }
    }
    catch (error) {
        console.error('❌ Execution error:', error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
});
program
    .command('sql')
    .description('Execute SQL query')
    .argument('<query>', 'SQL query to execute')
    .option('-c, --config <path>', 'Configuration file path')
    .option('-v, --verbose', 'Verbose output')
    .action(async (query, options) => {
    const config = loadConfig(options.config);
    const client = new iris_client_1.IrisClient(config);
    verboseLog(`Executing SQL: ${query}`, options.verbose);
    verboseLog(`Target: ${client.getConnectionInfo()}`, options.verbose);
    try {
        const result = await client.executeSql(query);
        if (result.success) {
            console.log('✅ SQL executed successfully');
            if (result.resultSet && result.resultSet.length > 0) {
                console.log('Results:');
                result.resultSet.forEach((row, index) => {
                    console.log(`  Row ${index + 1}:`, JSON.stringify(row, null, 2));
                });
            }
            else {
                console.log('No results returned');
            }
            if (result.message) {
                console.log('Message:', result.message);
            }
        }
        else {
            console.log('❌ SQL execution failed');
            console.error('Error:', result.error);
            if (result.sqlCode) {
                console.error('SQL Code:', result.sqlCode);
            }
            process.exit(1);
        }
    }
    catch (error) {
        console.error('❌ SQL execution error:', error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
});
program
    .command('test-stored-proc')
    .description('Test the stored procedure functionality')
    .option('-c, --config <path>', 'Configuration file path')
    .option('-v, --verbose', 'Verbose output')
    .action(async (options) => {
    const config = loadConfig(options.config);
    const client = new iris_client_1.IrisClient(config);
    verboseLog(`Testing stored procedure`, options.verbose);
    verboseLog(`Target: ${client.getConnectionInfo()}`, options.verbose);
    try {
        console.log('Testing stored procedure functionality...');
        // Test simple ObjectScript execution
        const result = await client.executeObjectScript('Set x = 42');
        if (result.success) {
            console.log('✅ Stored procedure test successful');
            console.log('Result:', result.result);
        }
        else {
            console.log('❌ Stored procedure test failed');
            console.error('Error:', result.error);
            process.exit(1);
        }
    }
    catch (error) {
        console.error('❌ Test error:', error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
});
program.parse();
//# sourceMappingURL=index.js.map