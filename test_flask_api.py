#!/usr/bin/env python3
"""
Test script for Flask ML API
Run this to verify your Flask server is working correctly
"""

import requests
import json

# Test your Flask server
BASE_URL = "https://484e2ff79fed.ngrok-free.app"

def test_health_check():
    """Test the health check endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Health Check Status: {response.status_code}")
        print(f"Health Check Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_basic_endpoint():
    """Test the basic test endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/test")
        print(f"Test Endpoint Status: {response.status_code}")
        print(f"Test Endpoint Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Test endpoint failed: {e}")
        return False

def test_ml_api():
    """Test the ML API endpoint"""
    test_data = {
        "area": "pondy",
        "latitude": 11.9323,
        "longitude": 79.7924,
        "wants_cctv": False,
        "wants_covered": False,
        "wants_ev": False,
        "wants_premium": False,
        "max_price": 1000
    }
    
    try:
        headers = {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true'
        }
        
        response = requests.post(
            f"{BASE_URL}/predict_best_parking",
            headers=headers,
            json=test_data
        )
        
        print(f"ML API Status: {response.status_code}")
        print(f"ML API Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Success! Found {len(data.get('best_spots', []))} spots")
            return True
        else:
            print(f"❌ Failed with status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"ML API test failed: {e}")
        return False

def main():
    print("🧪 Testing Flask ML API...")
    print("=" * 50)
    
    # Test 1: Health check
    print("\n1. Testing Health Check...")
    health_ok = test_health_check()
    
    # Test 2: Basic endpoint
    print("\n2. Testing Basic Endpoint...")
    basic_ok = test_basic_endpoint()
    
    # Test 3: ML API
    print("\n3. Testing ML API...")
    ml_ok = test_ml_api()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print(f"Health Check: {'✅ PASS' if health_ok else '❌ FAIL'}")
    print(f"Basic Endpoint: {'✅ PASS' if basic_ok else '❌ FAIL'}")
    print(f"ML API: {'✅ PASS' if ml_ok else '❌ FAIL'}")
    
    if all([health_ok, basic_ok, ml_ok]):
        print("\n🎉 All tests passed! Your Flask server is working correctly.")
    else:
        print("\n⚠️ Some tests failed. Check the output above for details.")

if __name__ == "__main__":
    main()
