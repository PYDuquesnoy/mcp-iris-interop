#!/usr/bin/env node

import { IrisClient } from './src/iris-client';
import { ConnectionConfig } from './src/types';
import fs from 'fs';
import path from 'path';

async function testStoredProcedures() {
  console.log('🧪 Testing Stored Procedures with IRIS Client');
  console.log('===========================================\n');

  // Load configuration
  const configPath = path.join(__dirname, '..', 'config.json');
  const config: ConnectionConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  
  const client = new IrisClient(config);
  
  // Connect to server
  console.log('Connecting to IRIS server...');
  const connected = await client.connect();
  if (!connected) {
    console.error('Failed to connect');
    return;
  }
  console.log('✅ Connected successfully\n');

  // Test different SQL syntaxes with built-in functions
  console.log('🔬 Testing different SQL syntaxes:\n');

  // Test 1: Simple SELECT with function
  console.log('1️⃣ Testing SELECT with function:');
  try {
    const result1 = await client.executeQuery(
      "SELECT $LENGTH(?) AS Length",
      ['Hello World'],
      config.namespace
    );
    console.log('   ✅ Success:', JSON.stringify(result1.result, null, 2));
  } catch (error) {
    console.log('   ❌ Failed:', error instanceof Error ? error.message : String(error));
  }

  // Test 2: SELECT with multiple functions
  console.log('\n2️⃣ Testing multiple functions:');
  try {
    const result2 = await client.executeQuery(
      "SELECT $LENGTH(?) AS Length, $UPPER(?) AS Upper",
      ['Hello', 'world'],
      config.namespace
    );
    console.log('   ✅ Success:', JSON.stringify(result2.result, null, 2));
  } catch (error) {
    console.log('   ❌ Failed:', error instanceof Error ? error.message : String(error));
  }

  // Test 3: Check if we can find any stored procedures
  console.log('\n3️⃣ Checking for existing stored procedures:');
  try {
    const result3 = await client.executeQuery(
      "SELECT TOP 5 SqlName FROM %Dictionary.MethodDefinition WHERE SqlProc = 1",
      [],
      config.namespace
    );
    console.log('   ✅ Success:', JSON.stringify(result3.result, null, 2));
  } catch (error) {
    console.log('   ❌ Failed:', error instanceof Error ? error.message : String(error));
  }

  // Test 4: Try calling a system stored procedure if any exist
  console.log('\n4️⃣ Testing CALL syntax with system SP:');
  try {
    const result4 = await client.executeQuery(
      "SELECT %SYSTEM_SQL.TOCHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD') AS Today",
      [],
      config.namespace
    );
    console.log('   ✅ Success:', JSON.stringify(result4.result, null, 2));
  } catch (error) {
    console.log('   ❌ Failed:', error instanceof Error ? error.message : String(error));
  }

  // Test 5: SELECT from dual/dummy table
  console.log('\n5️⃣ Testing SELECT without FROM:');
  try {
    const result5 = await client.executeQuery(
      "SELECT 1+1 AS Result, ? AS Input",
      ['Test Input'],
      config.namespace
    );
    console.log('   ✅ Success:', JSON.stringify(result5.result, null, 2));
  } catch (error) {
    console.log('   ❌ Failed:', error instanceof Error ? error.message : String(error));
  }

  console.log('\n📊 Testing complete!');
}

// Run the tests
testStoredProcedures().catch(error => {
  console.error('💥 Test crashed:', error instanceof Error ? error.message : String(error));
  process.exit(1);
});