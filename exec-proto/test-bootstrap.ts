#!/usr/bin/env node

import { IrisClient } from '../client-proto/src/iris-client';
import { ConnectionConfig } from '../client-proto/src/types';
import fs from 'fs';
import path from 'path';

async function testBootstrap() {
  console.log('🚀 Testing Bootstrap Stored Procedure');
  console.log('====================================\n');

  // Load configuration
  const configPath = path.join(__dirname, '..', 'client-proto', 'config.json');
  const config: ConnectionConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  
  const client = new IrisClient(config);
  
  // Connect to server
  console.log('📡 Connecting to IRIS server...');
  const connected = await client.connect();
  if (!connected) {
    console.error('Failed to connect');
    return;
  }
  console.log('✅ Connected successfully\n');

  // Step 1: Upload Bootstrap.Installer class
  console.log('📤 Uploading Bootstrap.Installer class...');
  const bootstrapPath = path.join(__dirname, 'Bootstrap.Installer.cls');
  const bootstrapContent = fs.readFileSync(bootstrapPath, 'utf8');
  
  try {
    await client.uploadAndCompileClass('Bootstrap.Installer', bootstrapContent.split('\n'), config.namespace);
    console.log('✅ Bootstrap class uploaded and compiled\n');
  } catch (error) {
    console.error('❌ Failed to upload bootstrap class:', error);
    return;
  }

  // Step 2: Test simple function
  console.log('🧪 Testing simple function via SELECT...');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Installer_TestFunction(?) AS Result",
      ['Hello Bootstrap!'],
      config.namespace
    );
    
    if (result.result?.content?.[0]) {
      console.log('✅ Test function works:', result.result.content[0].Result);
    }
  } catch (error) {
    console.error('❌ Test function failed:', error);
  }

  // Step 3: Test ExecuteCode function
  console.log('\n🧪 Testing ExecuteCode function...');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Installer_ExecuteCode(?) AS Success",
      ['SET x=123'],
      config.namespace
    );
    
    console.log('Result:', JSON.stringify(result.result, null, 2));
  } catch (error) {
    console.error('❌ ExecuteCode failed:', error);
  }

  // Step 4: Install REST API
  console.log('\n🚀 Installing REST API via stored procedure...');
  try {
    const result = await client.executeQuery(
      "SELECT Bootstrap.Installer_InstallRestAPI(?) AS Status",
      [config.namespace],
      config.namespace
    );
    
    if (result.result?.content?.[0]) {
      console.log('✅ Installation result:', result.result.content[0].Status);
    }
  } catch (error) {
    console.error('❌ REST API installation failed:', error);
  }

  // Step 5: Test the new REST API
  console.log('\n🧪 Testing newly installed REST API...');
  try {
    const axios = require('axios');
    const auth = Buffer.from(`${config.username}:${config.password}`).toString('base64');
    
    const response = await axios.get(`http://${config.server}:${config.port}/side/mcp-interop/list`, {
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json'
      },
      validateStatus: () => true
    });
    
    console.log('REST API Response:', response.status, response.data);
    if (response.status === 200) {
      console.log('✅ REST API is working!');
    } else {
      console.log('❌ REST API returned status:', response.status);
    }
  } catch (error) {
    console.error('❌ Failed to test REST API:', error);
  }

  console.log('\n✅ Bootstrap test complete!');
}

// Run the test
testBootstrap().catch(error => {
  console.error('💥 Test crashed:', error);
  process.exit(1);
});