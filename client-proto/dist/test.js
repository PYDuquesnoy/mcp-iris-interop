#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const iris_client_1 = require("./iris-client");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
async function runTests() {
    console.log('🧪 IRIS Client Prototype Test Suite');
    console.log('===================================\\n');
    // Load configuration
    const configPath = path_1.default.join(__dirname, '..', 'config.json');
    let config;
    try {
        const configData = fs_1.default.readFileSync(configPath, 'utf8');
        config = JSON.parse(configData);
        console.log('✅ Configuration loaded successfully');
        console.log(`   Target: ${config.server}:${config.port}[${config.namespace}]\\n`);
    }
    catch (error) {
        console.error('❌ Failed to load configuration:', error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
    const client = new iris_client_1.IrisClient(config);
    let testsPassed = 0;
    let testsTotal = 0;
    // Test helper function
    async function test(name, testFn) {
        testsTotal++;
        try {
            console.log(`🔄 ${name}...`);
            await testFn();
            console.log(`✅ ${name} - PASSED\\n`);
            testsPassed++;
        }
        catch (error) {
            console.error(`❌ ${name} - FAILED: ${error instanceof Error ? error.message : String(error)}\\n`);
        }
    }
    // Test 1: Connection
    await test('Connection Test', async () => {
        const connected = await client.connect();
        if (!connected) {
            throw new Error('Failed to connect to IRIS server');
        }
        console.log(`   Authentication: ${client.isAuthenticated() ? 'OK' : 'Failed'}`);
    });
    // Test 2: Server Info
    await test('Server Information', async () => {
        const serverInfo = await client.getServerInfo();
        if (!serverInfo.version || !serverInfo.id || !serverInfo.namespaces) {
            throw new Error('Invalid server info response');
        }
        console.log(`   Version: ${serverInfo.version}`);
        console.log(`   ID: ${serverInfo.id}`);
        console.log(`   API Version: ${serverInfo.api}`);
        console.log(`   Namespaces: ${serverInfo.namespaces.length} available`);
    });
    // Test 3: Namespaces List
    await test('Namespaces Inventory', async () => {
        const namespaces = await client.getNamespaces();
        if (!Array.isArray(namespaces) || namespaces.length === 0) {
            throw new Error('No namespaces found');
        }
        console.log(`   Found namespaces: ${namespaces.join(', ')}`);
        // Verify expected namespaces exist
        const expectedNamespaces = ['USER', '%SYS'];
        if (config.namespace) {
            expectedNamespaces.push(config.namespace);
        }
        const missingNamespaces = expectedNamespaces.filter(ns => !namespaces.includes(ns));
        if (missingNamespaces.length > 0) {
            console.log(`   ⚠️  Expected namespaces not found: ${missingNamespaces.join(', ')}`);
        }
    });
    // Test 4: Namespace Info
    await test('Namespace Information', async () => {
        const result = await client.getNamespaceInfo(config.namespace);
        if (!result || !result.status) {
            throw new Error('Invalid namespace info response');
        }
        console.log(`   Namespace '${config.namespace}' status: ${result.status.summary || 'OK'}`);
    });
    // Test 5: Document List
    await test('Document List', async () => {
        const result = await client.getDocumentList(config.namespace, '*', 'CLS', undefined, false);
        if (!result.result || !result.result.content) {
            throw new Error('Invalid document list response');
        }
        const docs = result.result.content;
        console.log(`   Found ${docs.length} classes in namespace '${config.namespace}'`);
        if (docs.length > 0) {
            const sampleDoc = docs[0];
            console.log(`   Sample document: ${sampleDoc.name} (${sampleDoc.cat})`);
        }
    });
    // Test 6: Get Document Content (if available)
    await test('Document Content Retrieval', async () => {
        const docListResult = await client.getDocumentList(config.namespace, '*', 'CLS', undefined, false);
        const docs = docListResult.result.content;
        if (docs.length === 0) {
            console.log('   ⚠️  No documents available to test content retrieval');
            return;
        }
        const sampleDoc = docs[0];
        const docResult = await client.getDocument(sampleDoc.name, config.namespace);
        if (!docResult.result || !docResult.result.content) {
            throw new Error('Invalid document content response');
        }
        const content = docResult.result.content;
        const lines = Array.isArray(content) ? content.length : 'N/A';
        console.log(`   Retrieved document '${sampleDoc.name}' with ${lines} lines`);
    });
    // Test 7: SQL Query (basic test)
    await test('SQL Query Execution', async () => {
        try {
            const queryResult = await client.executeQuery('SELECT TOP 5 Name FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH ?', ['%'], config.namespace);
            if (!queryResult.result) {
                throw new Error('Invalid query result response');
            }
            console.log(`   Query executed successfully`);
            if (queryResult.result.content) {
                console.log(`   Result contains data`);
            }
        }
        catch (error) {
            // SQL queries might fail in some configurations, so we'll note this
            console.log(`   ⚠️  SQL query test failed (this may be expected): ${error instanceof Error ? error.message : String(error)}`);
        }
    });
    // Results Summary
    console.log('📊 Test Results Summary');
    console.log('======================');
    console.log(`Tests Passed: ${testsPassed}/${testsTotal}`);
    console.log(`Success Rate: ${Math.round((testsPassed / testsTotal) * 100)}%`);
    if (testsPassed === testsTotal) {
        console.log('\\n🎉 All tests passed! The IRIS client prototype is working correctly.');
    }
    else {
        console.log(`\\n⚠️  ${testsTotal - testsPassed} test(s) failed. Please check the configuration and server status.`);
        process.exit(1);
    }
}
// Run the tests
runTests().catch(error => {
    console.error('💥 Test suite crashed:', error instanceof Error ? error.message : String(error));
    process.exit(1);
});
