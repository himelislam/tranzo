#!/usr/bin/env node

/**
 * Integration test script for Tranzo application
 * Tests backend API endpoints and frontend-backend communication
 */

const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');

const BACKEND_URL = 'http://localhost:3001';
const FRONTEND_URL = 'http://localhost:3002';

async function testBackendHealth() {
    console.log('🔍 Testing backend health...');
    try {
        const response = await axios.get(`${BACKEND_URL}/languages`);
        console.log('✅ Backend is running and responding');
        console.log(`📋 Available languages: ${response.data.length} languages`);
        return true;
    } catch (error) {
        console.error('❌ Backend health check failed:', error.message);
        return false;
    }
}

async function testFileUpload() {
    console.log('\n📤 Testing file upload...');
    try {
        // Create a test file
        const testContent = 'Hello, this is a test file for translation.';
        const testFilePath = './test-upload.txt';
        fs.writeFileSync(testFilePath, testContent);

        // Create form data
        const form = new FormData();
        form.append('file', fs.createReadStream(testFilePath));
        form.append('targetLanguage', 'es'); // Spanish

        const response = await axios.post(`${BACKEND_URL}/upload`, form, {
            headers: {
                ...form.getHeaders(),
            },
        });

        console.log('✅ File upload successful');
        console.log(`📄 File ID: ${response.data.fileId}`);
        
        // Clean up test file
        fs.unlinkSync(testFilePath);
        
        return response.data.fileId;
    } catch (error) {
        console.error('❌ File upload failed:', error.message);
        return null;
    }
}

async function testStatusCheck(fileId) {
    console.log('\n📊 Testing status check...');
    try {
        const response = await axios.get(`${BACKEND_URL}/status/${fileId}`);
        console.log('✅ Status check successful');
        console.log(`📈 Status: ${response.data.status}`);
        console.log(`⏱️  Progress: ${response.data.progress}%`);
        return response.data;
    } catch (error) {
        console.error('❌ Status check failed:', error.message);
        return null;
    }
}

async function testFrontendAccess() {
    console.log('\n🌐 Testing frontend access...');
    try {
        const response = await axios.get(FRONTEND_URL);
        console.log('✅ Frontend is accessible');
        console.log(`📊 Response status: ${response.status}`);
        return true;
    } catch (error) {
        console.error('❌ Frontend access failed:', error.message);
        return false;
    }
}

async function runIntegrationTests() {
    console.log('🚀 Starting Tranzo Integration Tests\n');
    
    const results = {
        backendHealth: false,
        frontendAccess: false,
        fileUpload: false,
        statusCheck: false
    };

    // Test backend health
    results.backendHealth = await testBackendHealth();
    
    // Test frontend access
    results.frontendAccess = await testFrontendAccess();
    
    // Test file upload (only if backend is healthy)
    if (results.backendHealth) {
        const fileId = await testFileUpload();
        results.fileUpload = !!fileId;
        
        // Test status check (only if upload succeeded)
        if (fileId) {
            const status = await testStatusCheck(fileId);
            results.statusCheck = !!status;
        }
    }

    // Print summary
    console.log('\n📋 Test Results Summary:');
    console.log('========================');
    console.log(`Backend Health: ${results.backendHealth ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`Frontend Access: ${results.frontendAccess ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`File Upload: ${results.fileUpload ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`Status Check: ${results.statusCheck ? '✅ PASS' : '❌ FAIL'}`);
    
    const passedTests = Object.values(results).filter(Boolean).length;
    const totalTests = Object.keys(results).length;
    
    console.log(`\n🎯 Overall: ${passedTests}/${totalTests} tests passed`);
    
    if (passedTests === totalTests) {
        console.log('🎉 All tests passed! Integration is working correctly.');
    } else {
        console.log('⚠️  Some tests failed. Check the logs above for details.');
    }
}

// Run tests if this script is executed directly
if (require.main === module) {
    runIntegrationTests().catch(console.error);
}

module.exports = { runIntegrationTests };
