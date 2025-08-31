# Enhanced ML Service Testing Guide

This guide explains how to test your Enhanced ML Service to ensure it's working correctly with your Flask server.

## 🧪 Test Files Created

### 1. `simple_test_enhanced_ml.dart` (Recommended)
- **Simple test script** that can be run directly
- **No Flutter test framework** dependencies
- **Comprehensive testing** of all endpoints
- **Easy to run** and debug

### 2. `test_enhanced_ml_service.dart`
- **Full Flutter test framework** version
- **More comprehensive** model testing
- **Requires Flutter test** setup
- **Better for CI/CD** integration

### 3. `test_flask_api.py`
- **Python test script** for Flask server
- **Tests server-side** functionality
- **Good for debugging** Flask issues

## 🚀 How to Run Tests

### Option 1: Run Simple Dart Test (Recommended)

1. **Navigate to your project directory**
   ```bash
   cd "path/to/your/project"
   ```

2. **Run the simple test**
   ```bash
   dart run simple_test_enhanced_ml.dart
   ```

3. **Expected output:**
   ```
   🚀 Starting Simple Enhanced ML Service Tests...
   ============================================================
   
   🏥 Testing Health Check...
   📡 Health Check Status: 200
   ✅ Health Check PASSED
   
   🧪 Testing Basic Endpoint...
   ✅ Basic Endpoint PASSED
   
   🤖 Testing ML API Endpoint...
   ✅ ML API Endpoint PASSED
   
   🎯 Testing Different Request Scenarios...
   ✅ All scenarios passed
   
   ⚠️ Testing Error Handling...
   ✅ Error handling working correctly
   
   🎉 All tests passed! Your Enhanced ML Service is working correctly.
   ```

### Option 2: Run Python Flask Test

1. **Make sure you have Python and required packages**
   ```bash
   pip install requests
   ```

2. **Run the Python test**
   ```bash
   python test_flask_api.py
   ```

### Option 3: Run Flutter Test Framework

1. **Make sure you have Flutter test framework**
   ```bash
   flutter pub get
   ```

2. **Run the Flutter test**
   ```bash
   flutter test test_enhanced_ml_service.dart
   ```

## 📋 What the Tests Check

### 1. **Health Check** (`/health`)
- ✅ Flask server is running
- ✅ Supabase connection is working
- ✅ ML model and scaler are loaded
- ✅ All dependencies are available

### 2. **Basic Endpoint** (`/test`)
- ✅ Flask server responds to basic requests
- ✅ CORS is working correctly
- ✅ Basic routing is functional

### 3. **ML API Endpoint** (`/predict_best_parking`)
- ✅ Endpoint accepts POST requests
- ✅ Request validation works
- ✅ ML processing is functional
- ✅ Response format is correct
- ✅ Returns parking spots with scores

### 4. **Different Scenarios**
- ✅ Basic requests work
- ✅ Requests with CCTV filter work
- ✅ Premium requests work
- ✅ Different price ranges work

### 5. **Error Handling**
- ✅ Missing required fields are rejected
- ✅ Invalid coordinates are handled
- ✅ Empty requests are rejected
- ✅ Proper error status codes

## 🔧 Troubleshooting Common Issues

### Issue: "Connection refused" or "404 Not Found"
**Solution:**
1. Make sure your Flask server is running
2. Check if ngrok URL is current
3. Verify the port (8000) is correct
4. Check if ngrok tunnel is active

### Issue: "CORS error"
**Solution:**
1. Ensure Flask-CORS is properly configured
2. Check if ngrok headers are being sent
3. Verify the request headers

### Issue: "Model not loaded"
**Solution:**
1. Check if `parking_model.pkl` exists
2. Verify `parking_scaler.pkl` is present
3. Check file paths in Flask code

### Issue: "Supabase connection failed"
**Solution:**
1. Verify Supabase URL and key
2. Check internet connection
3. Verify Supabase service is running

## 📊 Interpreting Test Results

### ✅ **All Tests Passed (5/5)**
- Your service is working perfectly
- Ready for production use
- All endpoints are functional

### ✅ **Most Tests Passed (4/5)**
- Service is working well
- Minor issues that can be addressed
- Generally ready for use

### ⚠️ **Some Tests Failed (2-3/5)**
- Service has significant issues
- Need to investigate failures
- Check server logs for errors

### ❌ **Most Tests Failed (0-1/5)**
- Service is not working
- Check server configuration
- Verify all dependencies

## 🚨 If Tests Fail

1. **Check Flask server logs** for error messages
2. **Verify ngrok URL** is current and accessible
3. **Check if all required files** exist (models, etc.)
4. **Test endpoints manually** using Postman or curl
5. **Check network connectivity** and firewall settings

## 📱 Testing from Flutter App

After running these tests successfully:

1. **Test the Flutter service** by calling `getMLRecommendations()`
2. **Check console logs** for detailed debugging information
3. **Verify responses** are properly parsed
4. **Test error scenarios** by sending invalid requests

## 🔄 Continuous Testing

For ongoing development:

1. **Run tests before** each deployment
2. **Automate tests** in your CI/CD pipeline
3. **Monitor test results** for regressions
4. **Update tests** when adding new features

---

## 📞 Need Help?

If tests continue to fail:

1. **Check the detailed error messages** in test output
2. **Review Flask server logs** for server-side errors
3. **Verify your ngrok tunnel** is active and accessible
4. **Test endpoints manually** to isolate issues

The tests are designed to give you clear feedback on what's working and what needs attention!
