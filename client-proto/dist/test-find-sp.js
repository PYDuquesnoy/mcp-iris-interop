#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const iris_client_1 = require("./src/iris-client");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
async function findStoredProcedures() {
    var _a, _b;
    console.log('🔍 Finding Available Stored Procedures');
    console.log('=====================================\n');
    // Load configuration
    const configPath = path_1.default.join(__dirname, '..', 'config.json');
    const config = JSON.parse(fs_1.default.readFileSync(configPath, 'utf8'));
    const client = new iris_client_1.IrisClient(config);
    // Connect to server
    console.log('Connecting to IRIS server...');
    const connected = await client.connect();
    if (!connected) {
        console.error('Failed to connect');
        return;
    }
    console.log('✅ Connected successfully\n');
    // Find stored procedures
    console.log('📋 Searching for stored procedures in %Dictionary tables...\n');
    // Try different queries to find stored procedures
    const queries = [
        {
            name: 'Method definitions with SqlProc',
            sql: `SELECT TOP 10 parent AS ClassName, Name AS MethodName 
            FROM %Dictionary.MethodDefinition 
            WHERE SqlProc = 1 
            ORDER BY parent`
        },
        {
            name: 'Compiled methods with SqlProc',
            sql: `SELECT TOP 10 parent AS ClassName, Name AS MethodName, SqlName 
            FROM %Dictionary.CompiledMethod 
            WHERE SqlProc = 1 AND parent NOT %STARTSWITH '%' 
            ORDER BY parent`
        },
        {
            name: 'Queries with SqlProc',
            sql: `SELECT TOP 10 parent AS ClassName, Name AS QueryName, SqlName 
            FROM %Dictionary.QueryDefinition 
            WHERE SqlProc = 1 
            ORDER BY parent`
        },
        {
            name: 'Sample.Person methods',
            sql: `SELECT Name, SqlName, FormalSpec 
            FROM %Dictionary.MethodDefinition 
            WHERE parent = 'Sample.Person' AND SqlProc = 1`
        }
    ];
    for (const query of queries) {
        console.log(`\n🔹 ${query.name}:`);
        console.log(`SQL: ${query.sql}\n`);
        try {
            const result = await client.executeQuery(query.sql, [], config.namespace);
            if (((_a = result.result) === null || _a === void 0 ? void 0 : _a.content) && result.result.content.length > 0) {
                console.log('Results:');
                result.result.content.forEach((row, idx) => {
                    console.log(`  ${idx + 1}. ${JSON.stringify(row)}`);
                });
            }
            else {
                console.log('No results found.');
            }
        }
        catch (error) {
            console.log('❌ Error:', error instanceof Error ? error.message : String(error));
        }
    }
    // Now try to call a simple built-in function as stored procedure
    console.log('\n\n📋 Testing function calls:\n');
    const functionTests = [
        {
            name: 'LENGTH function',
            sql: "SELECT $LENGTH('Hello World') AS Result"
        },
        {
            name: 'UPPER function',
            sql: "SELECT $UPPER('hello') AS Result"
        },
        {
            name: 'NOW function',
            sql: "SELECT $NOW() AS CurrentTime"
        },
        {
            name: 'PIECE function',
            sql: "SELECT $PIECE('A,B,C', ',', 2) AS SecondPiece"
        }
    ];
    for (const test of functionTests) {
        console.log(`\n🔹 ${test.name}:`);
        console.log(`SQL: ${test.sql}`);
        try {
            const result = await client.executeQuery(test.sql, [], config.namespace);
            if (((_b = result.result) === null || _b === void 0 ? void 0 : _b.content) && result.result.content.length > 0) {
                console.log('Result:', result.result.content[0]);
            }
        }
        catch (error) {
            console.log('❌ Error:', error instanceof Error ? error.message : String(error));
        }
    }
    console.log('\n✅ Search complete!');
}
// Run the tests
findStoredProcedures().catch(error => {
    console.error('💥 Test crashed:', error instanceof Error ? error.message : String(error));
    process.exit(1);
});
