#!/usr/bin/env node

import { IrisClient } from './src/iris-client';
import { ConnectionConfig } from './src/types';
import fs from 'fs';
import path from 'path';

async function testStoredProcedures() {
  console.log('🧪 Detailed SQL Response Testing');
  console.log('================================\n');

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

  async function runQuery(name: string, sql: string, params: string[] = []) {
    console.log(`\n📋 ${name}`);
    console.log(`SQL: ${sql}`);
    console.log(`Params: ${JSON.stringify(params)}`);
    
    try {
      const result = await client.executeQuery(sql, params, config.namespace);
      console.log('Full response:');
      console.log(JSON.stringify(result, null, 2));
      return result;
    } catch (error) {
      console.log('❌ Error:', error instanceof Error ? error.message : String(error));
      return null;
    }
  }

  // Test various SQL queries
  await runQuery(
    'Simple SELECT',
    'SELECT 1 AS One, 2 AS Two'
  );

  await runQuery(
    'Function with parameter',
    'SELECT $LENGTH(?) AS StringLength',
    ['Testing 123']
  );

  await runQuery(
    'Multiple parameters',
    'SELECT ? AS First, ? AS Second, $LENGTH(?) AS Length',
    ['Hello', 'World', 'Test String']
  );

  await runQuery(
    'Query system tables',
    'SELECT TOP 3 ClassName, SqlName FROM %Dictionary.CompiledMethod WHERE SqlProc = 1 AND SqlName IS NOT NULL ORDER BY ClassName'
  );

  // Now let's test CALL syntax with a known system procedure
  await runQuery(
    'CALL syntax test',
    'CALL %Library.GlobalEdit_Exists(?)',
    ['^test']
  );

  // Test with different CALL variations
  await runQuery(
    'JDBC style CALL',
    '{call %Library.GlobalEdit_Exists(?)}',
    ['^test']
  );

  console.log('\n✅ Testing complete!');
}

// Run the tests
testStoredProcedures().catch(error => {
  console.error('💥 Test crashed:', error instanceof Error ? error.message : String(error));
  process.exit(1);
});