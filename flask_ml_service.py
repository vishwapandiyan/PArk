import pandas as pd
from flask import Flask, request, jsonify
from supabase import create_client, Client
import joblib
from datetime import datetime
import requests
import json
import pytz
import math
from flask_cors import CORS
from pyngrok import ngrok
import numpy as np

# -----------------------------
# Load model & scaler
# -----------------------------
model = joblib.load("parking_model.pkl")
scaler = joblib.load("parking_scaler.pkl")

# -----------------------------
# Supabase connection
# -----------------------------
url = "https://snuvppospaekzqsrtqfe.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNudXZwcG9zcGFla3pxc3J0cWZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjQ3OTU3MywiZXhwIjoyMDcyMDU1NTczfQ.halCPtunl7IHzGjs0N_krgymW5hIST6PeEEzrJ6j3Ds"
supabase: Client = create_client(url, key)

# -----------------------------
# Dynamic Pricing Helpers
# -----------------------------
base_prices = {'hourly': 100, 'monthly': 3000, 'yearly': 30000}
GOOGLE_MAPS_API_KEY = "AIzaSyBWNj5IcMMzFd4uu7ZzLQ_45cFe_1_PIDs"
weather_api_key = "a3a0835f9438ade86ef8cf4cba3b6a21"

def get_time_factors():
    now = datetime.now()
    factors = {}
    if 8 <= now.hour <= 11 or 17 <= now.hour <= 20:
        factors['peak_hour'] = 1.2
    if now.weekday() >= 5:
        factors['weekend'] = 1.1
    return factors

def get_weather_factor(lat, lon, api_key):
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}"
        response = requests.get(url).json()
        if 'weather' not in response:
            return {}
        weather = response['weather'][0]['main'].lower()
        if 'rain' in weather:
            return {'rain': 1.1}
        elif 'snow' in weather:
            return {'snow': 1.2}
        return {}
    except:
        return {}

def get_demand_factor(is_available):
    return {'low_availability': 1.3 if is_available == 0 else 1.0}

def get_traffic_factor(lat, lon):
    try:
        dest_lat, dest_lon = lat + 0.01, lon + 0.01
        url = "https://maps.googleapis.com/maps/api/directions/json"
        params = {
            'origin': f"{lat},{lon}",
            'destination': f"{dest_lat},{dest_lon}",
            'key': GOOGLE_MAPS_API_KEY,
            'departure_time': 'now',
            'traffic_model': 'best_guess'
        }
        response = requests.get(url, params=params).json()
        if response.get('status') == 'OK':
            leg = response['routes'][0]['legs'][0]
            normal_time = leg.get('duration', {}).get('value', 0)
            traffic_time = leg.get('duration_in_traffic', {}).get('value', 0)
            impact = ((traffic_time - normal_time) / normal_time) if normal_time > 0 else 0
            if impact > 0.5:
                return {'traffic': 1.2}
            elif impact > 0.2:
                return {'traffic': 1.1}
            elif impact > 0.05:
                return {'traffic': 1.05}
        return {'traffic': 1.0}
    except:
        return {'traffic': 1.0}

def calculate_dynamic_price(base_price, factors, mode='hourly'):
    price = base_price[mode]
    for mult in factors.values():
        price *= mult
    return round(price)

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points using Haversine formula"""
    try:
        # Validate input coordinates
        if not all(isinstance(x, (int, float)) for x in [lat1, lon1, lat2, lon2]):
            return float('inf')
        
        R = 6371  # Earth's radius in kilometers
        
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
        
        # Ensure 'a' is within valid range for asin
        a = max(0, min(1, a))
        
        c = 2 * math.asin(math.sqrt(a))
        
        return R * c
    except Exception as e:
        print(f"Error calculating distance: {e}")
        return float('inf')

def convert_numpy_types(obj):
    """Convert numpy types to Python native types for JSON serialization"""
    if isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, dict):
        return {key: convert_numpy_types(value) for key, value in obj.items()}
    elif isinstance(obj, list):
        return [convert_numpy_types(item) for item in obj]
    return obj

def update_dynamic_prices(area):
    # Fetch parking spots from single table
    spots = supabase.table("parking_spaces").select("*").execute().data
    df = pd.DataFrame(spots)

    # Filter by area (using place_name instead of area)
    filtered_df = df[df['place_name'].str.lower() == area.lower()]

    dynamic_prices = []
    for _, row in filtered_df.iterrows():
        lat, lon = row['latitude'], row['longitude']
        is_available = 1  # Assuming all spots are available for now

        factors = {}
        factors.update(get_time_factors())
        factors.update(get_weather_factor(lat, lon, weather_api_key))
        factors.update(get_demand_factor(is_available))
        factors.update(get_traffic_factor(lat, lon))

        dynamic_prices.append({
            "spot_id": row['id'] if 'id' in row else row.get('spot_id', len(dynamic_prices) + 1),
            "price_hourly": calculate_dynamic_price(base_prices, factors, 'hourly'),
            "price_monthly": calculate_dynamic_price(base_prices, factors, 'monthly'),
            "price_yearly": calculate_dynamic_price(base_prices, factors, 'yearly')
        })

    print(f"✅ Calculated dynamic prices for {len(dynamic_prices)} spots in {area}")
    return dynamic_prices

def find_nearest_spot(filtered_df, user_lat, user_lon, max_distance_km=10):
    """
    This function finds the nearest available parking spot within the max_distance_km range.
    """
    # Calculate distance to user for each spot
    filtered_df['distance_to_user'] = filtered_df.apply(
        lambda row: calculate_distance(user_lat, user_lon, row['latitude'], row['longitude']), axis=1
    )
    
    # Filter spots within the max_distance_km range
    nearby_spots = filtered_df[filtered_df['distance_to_user'] <= max_distance_km]
    
    if not nearby_spots.empty:
        # Sort the spots by distance to the user and return the closest one
        nearest_spot = nearby_spots.sort_values('distance_to_user').iloc[0]
        return nearest_spot
    else:
        return None

def get_best_parking(user_input):
    # Fetch data from single table
    spots = supabase.table("parking_spaces").select("*").execute().data
    df = pd.DataFrame(spots)

    # Calculate dynamic prices for this area
    dynamic_prices = update_dynamic_prices(user_input['area'])
    
    # Filter by area (using place_name)
    user_lat = user_input.get('latitude', 0)
    # Handle both 'longitude' and 'longitutde' (typo in input)
    user_lon = user_input.get('longitude', user_input.get('longitutde', 0))
    max_radius_km = user_input.get('max_radius_km', 10)

    # Step 1: start with all spots
    filtered = df.copy()

    # Step 2: filter by area if given
    if 'area' in user_input and user_input['area']:
        filtered = filtered[filtered['place_name'].str.lower() == user_input['area'].lower()]

    # Step 3: calculate distance for all remaining spots
    filtered['distance_to_user'] = filtered.apply(
        lambda row: calculate_distance(user_lat, user_lon, row['latitude'], row['longitude']), axis=1
    )

    # Step 4: filter by distance (only if area not given, or optional)
    if 'area' not in user_input or not user_input['area']:
        filtered = filtered[filtered['distance_to_user'] <= max_radius_km]

    # Map new column names to old ones for compatibility
    filtered = filtered.copy()
    filtered['lat'] = filtered['latitude']
    filtered['lon'] = filtered['longitude']
    filtered['cctv'] = filtered['has_cctv']
    filtered['covered'] = filtered['has_shelter']
    filtered['ev'] = filtered['has_ev_charging']
    filtered['peak_area'] = filtered['is_premium']  # Map premium to peak_area
    filtered['price_per_hour'] = filtered['price_per_unit']
    
    # Calculate distance to user
    user_lat = user_input.get('latitude', 0)
    user_lon = user_input.get('longitude', 0)
    filtered['distance_to_user'] = filtered.apply(
        lambda row: calculate_distance(user_lat, user_lon, row['latitude'], row['longitude']), axis=1
    )

    # Fill missing columns with defaults
    default_values = {
        'length_m': 5.0,
        'width_m': 2.5,
        'traffic_eta': filtered['distance_to_user'] * 2,  # Rough estimate
        'rating': 4.0,
        'is_available': True,
        'available_hours': 24.0,
        'price_per_day': filtered['price_per_hour'] * 24,
        'price_per_month': filtered['price_per_hour'] * 24 * 30,
        'area': filtered['place_name']  # Map place_name to area
    }
    
    for col, default_val in default_values.items():
        if col not in filtered.columns:
            filtered[col] = default_val

    # Apply user filters
    if user_input.get('wants_cctv', False): 
        filtered = filtered[filtered['cctv'] == True]
    if user_input.get('wants_covered', False): 
        filtered = filtered[filtered['covered'] == True]
    if user_input.get('wants_ev', False): 
        filtered = filtered[filtered['ev'] == True]
    if user_input.get('wants_premium', False): 
        filtered = filtered[filtered['peak_area'] == True]

    # Price filter
    max_price = user_input.get('max_price', float('inf'))
    filtered = filtered[filtered['price_per_hour'] <= max_price]

    # Availability filter (assuming all are available)
    filtered = filtered[filtered['is_available'] == True]

    # Handle failed spot IDs
    if user_input.get('failed_spot_ids'):
        spot_id_col = 'id' if 'id' in filtered.columns else 'spot_id'
        if spot_id_col in filtered.columns:
            filtered = filtered[~filtered[spot_id_col].isin(user_input['failed_spot_ids'])]

    # If no spots match the criteria, find the nearest spot
    if filtered.empty:
        print("No spots found matching the criteria. Searching for the nearest spot...")
        nearest_spot = find_nearest_spot(df, user_lat, user_lon, max_distance_km=10)
        if nearest_spot is not None:
            # Convert to proper format for Flutter
            return [{
                "id": str(nearest_spot['id']) if 'id' in nearest_spot else str(nearest_spot.get('spot_id', 'N/A')),
                "owner_id": str(nearest_spot.get('owner_id', 'unknown')),
                "slot_number": str(nearest_spot.get('slot_number', nearest_spot.get('id', 'N/A'))),
                "price_hourly": calculate_dynamic_price(base_prices, get_time_factors(), 'hourly'),
                "price_monthly": calculate_dynamic_price(base_prices, get_time_factors(), 'monthly'),
                "price_yearly": calculate_dynamic_price(base_prices, get_time_factors(), 'yearly'),
                "score": 0.8,  # Default score for nearest spot
                "distance_to_user": float(nearest_spot['distance_to_user']),
                "latitude": float(nearest_spot['latitude']),
                "longitude": float(nearest_spot['longitude']),
                "place_name": str(nearest_spot['place_name'])
            }]
        else:
            return []

    # Continue with normal processing if spots match the user's criteria
    # Predict & rank using the same feature columns as original model
    feature_columns = [
        'lat','lon','cctv','covered','length_m','width_m',
        'price_per_hour','price_per_day','price_per_month',
        'distance_to_user','traffic_eta','rating',
        'is_available','available_hours','ev','peak_area'
    ]
    
    # Ensure all feature columns exist
    for col in feature_columns:
        if col not in filtered.columns:
            if col in ['cctv','covered','ev','peak_area','is_available']:
                filtered[col] = False
            else:
                filtered[col] = 0.0

    try:
        X = scaler.transform(filtered[feature_columns])
        filtered['score'] = model.predict(X)
    except Exception as e:
        print(f"Model prediction error: {e}")
        # Fallback scoring based on distance and price
        filtered['score'] = 1 / (filtered['distance_to_user'] + 1) - filtered['price_per_hour'] / 1000

    ranked_spots = filtered.sort_values('score', ascending=False).reset_index(drop=True)
    
    # Convert to proper format for Flutter with correct field names
    result = []
    for _, row in ranked_spots.iterrows():
        spot_data = {
            "id": str(row['id']) if 'id' in row else str(row.get('spot_id', 'N/A')),
            "owner_id": str(row.get('owner_id', 'unknown')),
            "slot_number": str(row.get('slot_number', row.get('id', 'N/A'))),
            "price_hourly": int(row['price_per_hour']) if pd.notna(row['price_per_hour']) else 100,
            "price_monthly": int(row['price_per_hour'] * 24 * 30) if pd.notna(row['price_per_hour']) else 3000,
            "price_yearly": int(row['price_per_hour'] * 24 * 365) if pd.notna(row['price_per_hour']) else 30000,
            "score": float(row['score']) if pd.notna(row['score']) else 0.5,
            "distance_to_user": float(row['distance_to_user']) if pd.notna(row['distance_to_user']) else 0.0,
            "latitude": float(row['latitude']) if pd.notna(row['latitude']) else 0.0,
            "longitude": float(row['longitude']) if pd.notna(row['longitude']) else 0.0,
            "place_name": str(row['place_name']) if pd.notna(row['place_name']) else 'Unknown'
        }
        result.append(spot_data)
    
    # Convert numpy types to native Python types for JSON serialization
    result = convert_numpy_types(result)
    
    return result

# -----------------------------
# Flask API
# -----------------------------
app = Flask(__name__)
CORS(app)

@app.route("/test", methods=["GET"])
def test():
    """Basic test endpoint to verify server is running"""
    return jsonify({"status": "success", "message": "Flask ML Service is running!"})

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint to verify all components are working"""
    try:
        # Test Supabase connection
        test_query = supabase.table("parking_spaces").select("id").limit(1).execute()
        supabase_status = "connected" if test_query.data is not None else "failed"
        
        # Test model loading
        model_status = "loaded" if model is not None else "failed"
        scaler_status = "loaded" if scaler is not None else "failed"
        
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "components": {
                "supabase": supabase_status,
                "model": model_status,
                "scaler": scaler_status
            }
        })
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route("/predict_best_parking", methods=["POST"])
def predict_best_parking():
    try:
        user_input = request.json
        print(f"Received request: {user_input}")
        
        # Validate required fields
        if not user_input:
            return jsonify({"error": "No input data provided", "best_spots": []}), 400
        
        required_fields = ['area', 'latitude']
        for field in required_fields:
            if field not in user_input:
                return jsonify({"error": f"Missing required field: {field}", "best_spots": []}), 400
        
        # Validate coordinate types
        try:
            lat = float(user_input['latitude'])
            lon = float(user_input.get('longitude', user_input.get('longitutde', 0)))
            if not (-90 <= lat <= 90) or not (-180 <= lon <= 180):
                return jsonify({"error": "Invalid coordinates", "best_spots": []}), 400
        except (ValueError, TypeError):
            return jsonify({"error": "Invalid coordinate format", "best_spots": []}), 400
        
        ranked_spots = get_best_parking(user_input)
        print(f"Returning {len(ranked_spots)} spots")
        
        response_data = {"best_spots": ranked_spots}
        return jsonify(response_data)
        
    except Exception as e:
        print(f"Error processing request: {e}")
        return jsonify({"error": str(e), "best_spots": []}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)