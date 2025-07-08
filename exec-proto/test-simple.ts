#!/usr/bin/env node

import { IrisClient } from '../client-proto/src/iris-client';
import { ConnectionConfig } from '../client-proto/src/types';
import fs from 'fs';
import path from 'path';

async function testSimpleBootstrap() {
  console.log('🚀 Testing Simple Bootstrap');
  console.log('==========================\n');

  // Load configuration
  const configPath = path.join(__dirname, '..', 'client-proto', 'config.json');
  const config: ConnectionConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  
  const client = new IrisClient(config);
  
  // Connect
  console.log('📡 Connecting...');
  if (!await client.connect()) {
    console.error('Failed to connect');
    return;
  }
  console.log('✅ Connected\n');

  // Step 1: Upload Bootstrap.Simple class
  console.log('📤 Uploading Bootstrap.Simple class...');
  const bootstrapPath = path.join(__dirname, 'Bootstrap.Simple.cls');
  const content = fs.readFileSync(bootstrapPath, 'utf8');
  
  try {
    await client.uploadAndCompileClass('Bootstrap.Simple', content.split('\n'), config.namespace);
    console.log('✅ Class uploaded\n');
  } catch (error) {
    console.error('❌ Upload failed:', error);
    return;
  }

  // Step 2: Test simple function
  console.log('🧪 Test 1: Simple function');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Simple_Test(?) AS Result",
      ['Hello World'],
      config.namespace
    );
    console.log('Result:', result.result?.content?.[0]);
  } catch (error) {
    console.error('Error:', error);
  }

  // Step 3: Test code execution
  console.log('\n🧪 Test 2: Execute code');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Simple_Exec(?) AS Result",
      ['SET x=123'],
      config.namespace
    );
    console.log('Result:', result.result?.content?.[0]);
  } catch (error) {
    console.error('Error:', error);
  }

  // Step 4: Create REST class
  console.log('\n🧪 Test 3: Create REST class');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Simple_CreateRestClass() AS Result",
      [],
      config.namespace
    );
    console.log('Result:', result.result?.content?.[0]);
  } catch (error) {
    console.error('Error:', error);
  }

  // Step 5: Deploy web app
  console.log('\n🧪 Test 4: Deploy web application');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Simple_DeployWebApp() AS Result",
      [],
      config.namespace
    );
    console.log('Result:', result.result?.content?.[0]);
  } catch (error) {
    console.error('Error:', error);
  }

  // Step 6: Test the REST API
  console.log('\n🧪 Test 5: Call REST API');
  try {
    const axios = require('axios');
    const https = require('https');
    
    const auth = Buffer.from(`${config.username}:${config.password}`).toString('base64');
    const url = `http${config.https ? 's' : ''}://${config.server}:${config.port}/side/mcp-interop/test`;
    
    console.log('Calling:', url);
    
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json'
      },
      httpsAgent: new https.Agent({  
        rejectUnauthorized: false
      }),
      validateStatus: () => true,
      timeout: 5000
    });
    
    console.log('Status:', response.status);
    console.log('Data:', response.data);
  } catch (error: any) {
    console.error('REST API test error:', error.message);
  }

  console.log('\n✅ Complete!');
}

// Run
testSimpleBootstrap().catch(error => {
  console.error('💥 Crashed:', error);
  process.exit(1);
});