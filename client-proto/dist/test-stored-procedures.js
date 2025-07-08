#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const iris_client_1 = require("./src/iris-client");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
async function testStoredProcedures() {
    console.log('🧪 Testing Stored Procedures with IRIS Client');
    console.log('===========================================\n');
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
    // First, upload and compile our test stored procedures
    console.log('📤 Uploading test stored procedures class...');
    const spClassPath = path_1.default.join(__dirname, '..', '..', 'iris-samples', 'Test.StoredProc.cls');
    const spContent = fs_1.default.readFileSync(spClassPath, 'utf8');
    try {
        const uploadResult = await client.uploadAndCompileClass('Test.StoredProc', spContent.split('\n'), config.namespace);
        console.log('✅ Class uploaded and compiled successfully\n');
    }
    catch (error) {
        console.error('Failed to upload class:', error);
        return;
    }
    // Test different SQL syntaxes
    console.log('🔬 Testing different SQL syntaxes for stored procedures:\n');
    // Test 1: CALL syntax
    console.log('1️⃣ Testing CALL syntax:');
    try {
        const result1 = await client.executeQuery("CALL Test.SimpleTest(?)", ['Hello World'], config.namespace);
        console.log('   Result:', JSON.stringify(result1.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ CALL syntax failed:', error instanceof Error ? error.message : String(error));
    }
    // Test 2: SELECT from stored procedure
    console.log('\n2️⃣ Testing SELECT FROM syntax:');
    try {
        const result2 = await client.executeQuery("SELECT Test.SimpleTest(?)", ['Hello World'], config.namespace);
        console.log('   Result:', JSON.stringify(result2.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ SELECT FROM syntax failed:', error instanceof Error ? error.message : String(error));
    }
    // Test 3: Direct function call in SELECT
    console.log('\n3️⃣ Testing function call in SELECT:');
    try {
        const result3 = await client.executeQuery("SELECT Test.SimpleTest('Hello World') AS Result", [], config.namespace);
        console.log('   Result:', JSON.stringify(result3.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ Function call syntax failed:', error instanceof Error ? error.message : String(error));
    }
    // Test 4: Query-based stored procedure
    console.log('\n4️⃣ Testing Query-based stored procedure:');
    try {
        const result4 = await client.executeQuery("CALL Test.SimpleQuery(?)", ['%Library'], config.namespace);
        console.log('   Result:', JSON.stringify(result4.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ Query SP failed:', error instanceof Error ? error.message : String(error));
    }
    // Test 5: Result set stored procedure
    console.log('\n5️⃣ Testing ResultSet stored procedure:');
    try {
        const result5 = await client.executeQuery("CALL Test.TestResultSet(?)", ['%Library'], config.namespace);
        console.log('   Result:', JSON.stringify(result5.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ ResultSet SP failed:', error instanceof Error ? error.message : String(error));
    }
    // Test 6: Try with curly braces (JDBC/ODBC style)
    console.log('\n6️⃣ Testing JDBC/ODBC style syntax:');
    try {
        const result6 = await client.executeQuery("{call Test.SimpleTest(?)}", ['Hello World'], config.namespace);
        console.log('   Result:', JSON.stringify(result6.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ JDBC/ODBC syntax failed:', error instanceof Error ? error.message : String(error));
    }
    // Test 7: Try with ? = call syntax
    console.log('\n7️⃣ Testing return value syntax:');
    try {
        const result7 = await client.executeQuery("{ ? = call Test.SimpleTest(?) }", ['Hello World'], config.namespace);
        console.log('   Result:', JSON.stringify(result7.result, null, 2));
    }
    catch (error) {
        console.log('   ❌ Return value syntax failed:', error instanceof Error ? error.message : String(error));
    }
    console.log('\n📊 Testing complete!');
}
// Run the tests
testStoredProcedures().catch(error => {
    console.error('💥 Test crashed:', error instanceof Error ? error.message : String(error));
    process.exit(1);
});
