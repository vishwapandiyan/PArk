import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class DestinationMapsPicker extends StatefulWidget {
  final double? initialDestinationLat;
  final double? initialDestinationLng;
  final Function(double lat, double lng, String address) onDestinationSelected;

  const DestinationMapsPicker({
    super.key,
    this.initialDestinationLat,
    this.initialDestinationLng,
    required this.onDestinationSelected,
  });

  @override
  State<DestinationMapsPicker> createState() => _DestinationMapsPickerState();
}

class _DestinationMapsPickerState extends State<DestinationMapsPicker>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  LatLng? _selectedDestination;
  String _destinationAddress = '';
  bool _mapReady = false;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  // Default location (Bangalore, India) - fallback if location services fail
  static const LatLng _defaultLocation = LatLng(12.9716, 77.5946);
  
  // Define map style
  static const String _mapStyle = '''
  [
    {
      "featureType": "all",
      "stylers": [
        {"visibility": "on"}
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set initial destination if provided
    if (widget.initialDestinationLat != null && widget.initialDestinationLng != null) {
      _selectedDestination = LatLng(widget.initialDestinationLat!, widget.initialDestinationLng!);
      _getAddressFromCoordinates(_selectedDestination!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _mapController != null) {
      _refreshMap();
    }
  }

  Future<void> _refreshMap() async {
    try {
      if (_mapController != null) {
        await _mapController!.setMapStyle(_mapStyle);
      }
    } catch (e) {
      print('Error refreshing map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Destination',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_selectedDestination != null)
            IconButton(
              onPressed: _confirmDestination,
              icon: const Icon(Icons.check_circle_outlined),
              tooltip: 'Confirm Destination',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Search input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        _searchLocation(value);
                      } else {
                        setState(() {
                          _searchResults = [];
                        });
                      }
                    },
                    onSubmitted: _searchLocation,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Instructions
                Row(
                  children: [
                    Icon(
                      _mapReady ? Icons.navigation : Icons.location_searching,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mapReady 
                            ? 'Search location or tap on map to pin destination' 
                            : 'Loading map...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Selected destination info
                if (_destinationAddress.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Destination:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _destinationAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDestination = null;
                              _destinationAddress = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Search results or Map
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildMapContainer(),
          ),
          
          // Bottom controls
          if (_selectedDestination != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmDestination,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Destination'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search results header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSearching ? Icons.search : Icons.location_on,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSearching 
                        ? 'Searching...' 
                        : 'Search Results (${_searchResults.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_isSearching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Search results list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.place,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    result['address'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${result['latitude'].toStringAsFixed(4)}, ${result['longitude'].toStringAsFixed(4)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  onTap: () => _selectSearchResult(result),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The actual Google Map
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _selectedDestination ?? _defaultLocation,
                zoom: _selectedDestination != null ? 16.0 : 12.0,
              ),
              onMapCreated: _onMapCreated,
              onTap: _onMapTapped,
              markers: _buildMarkers(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
            
            // Loading overlay
            if (!_mapReady)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Loading Map...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    // Destination marker
    if (_selectedDestination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _selectedDestination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress.isNotEmpty 
                ? _destinationAddress 
                : 'Your selected destination',
          ),
        ),
      );
    }
    
    return markers;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    try {
      await controller.setMapStyle(_mapStyle);
      
      if (mounted) {
        setState(() {
          _mapReady = true;
        });
      }
      
      print('✅ Destination Map created and styled successfully');
      
      // If we have a selected destination, focus on it
      if (_selectedDestination != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _selectedDestination!,
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error setting up destination map: $e');
      if (mounted) {
        setState(() {
          _mapReady = true;
        });
      }
    }
  }

  void _onMapTapped(LatLng location) {
    print('📍 Destination selected at: ${location.latitude}, ${location.longitude}');
    
    setState(() {
      _selectedDestination = location;
      _destinationAddress = '';
    });
    
    _getAddressFromCoordinates(location);
    
    HapticFeedback.lightImpact();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Location> locations = await locationFromAddress(query);
      
      List<Map<String, dynamic>> results = [];
      
      for (Location location in locations.take(5)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final address = [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.country,
            ].where((element) => element != null && element.isNotEmpty).join(', ');
            
            results.add({
              'address': address.isNotEmpty ? address : query,
              'latitude': location.latitude,
              'longitude': location.longitude,
            });
          }
        } catch (e) {
          // If reverse geocoding fails, use coordinates
          results.add({
            'address': '$query (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})',
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ Error searching location: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found: $query'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    final lat = result['latitude'] as double;
    final lng = result['longitude'] as double;
    final address = result['address'] as String;
    
    setState(() {
      _selectedDestination = LatLng(lat, lng);
      _destinationAddress = address;
      _searchController.text = address;
      _searchResults = [];
    });
    
    // Move map to selected location
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lng),
            zoom: 16.0,
          ),
        ),
      );
    }
    
    HapticFeedback.lightImpact();
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        
        setState(() {
          _destinationAddress = address.isNotEmpty ? address : 'Destination selected';
        });
        
        print('📍 Address found: $address');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _destinationAddress = 'Destination selected';
        });
      }
      print('❌ Error getting address: $e');
    }
  }



  void _confirmDestination() {
    if (_selectedDestination != null) {
      widget.onDestinationSelected(
        _selectedDestination!.latitude,
        _selectedDestination!.longitude,
        _destinationAddress.isNotEmpty ? _destinationAddress : 'Destination selected',
      );
      Navigator.of(context).pop();
    }
  }
}
