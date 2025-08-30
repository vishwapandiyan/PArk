# Read the booking screen file
$content = Get-Content 'lib/views/driver/booking_screen.dart' -Raw

# Find and replace the entire _findParkingSpaces method
$oldMethod = @'
  void _findParkingSpaces() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_destinationLat == null || _destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCarModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your car model'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get available slots from controller
      final slots = context.read<SlotController>().state.slots;
      if (slots.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No parking slots available')),
        );
        return;
      }

      // Filter slots based on user preferences
      final filteredSlots = slots.where((slot) {
        bool meetsPreferences = true;
        
        if (_needShelter && (slot.hasShelter != true)) {
          meetsPreferences = false;
        }
        if (_needCCTV && (slot.hasCCTV != true)) {
          meetsPreferences = false;
        }
        if (_needEVCharging && (slot.hasEVCharging != true)) {
          meetsPreferences = false;
        }
        
        return meetsPreferences;
      }).toList();

      if (!mounted) return;

      if (filteredSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No parking spaces match your preferences. Try adjusting your requirements.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Navigate to slot list screen with filtered results
      Navigator.of(context).pushNamed(
        '/slot_list',
        arguments: {
          'slots': filteredSlots,
          'destination': _destinationAddress,
          'destinationLat': _destinationLat,
          'destinationLng': _destinationLng,
          'carModel': _selectedCarModel!.displayName,
          'preferences': {
            'shelter': _needShelter,
            'cctv': _needCCTV,
            'evCharging': _needEVCharging,
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
'@

$newMethod = @'
  Future<void> _findParkingSpaces() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_destinationLat == null || _destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCarModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your car model'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Extract area from destination address
      final area = MLParkingRequest.extractAreaFromAddress(_destinationAddress);
      
      // Parse car dimensions for compatibility checking
      final carDimensions = MLParkingRequest.parseCarDimensions(_selectedCarModel!.dimensions);
      
      // Determine if premium is wanted based on current logic
      final wantsPremium = _needShelter && (_needCCTV || _needEVCharging);
      
      // Get ML-enhanced parking recommendations
      final enhancedSlots = await EnhancedMLService.getEnhancedSlots(
        area: area,
        latitude: _destinationLat!,
        longitude: _destinationLng!,
        wantsCctv: _needCCTV,
        wantsCovered: _needShelter,
        wantsEv: _needEVCharging,
        wantsPremium: wantsPremium,
        maxPrice: _maxPrice,
        carDimensions: carDimensions,
        carModelId: _selectedCarModel!.id,
      );

      if (!mounted) return;

      if (enhancedSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No compatible parking spaces found. Try adjusting your preferences or car model.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Navigate to enhanced slot list screen with ML results
      Navigator.of(context).pushNamed(
        '/slot_list',
        arguments: {
          'enhancedSlots': enhancedSlots,
          'destination': _destinationAddress,
          'destinationLat': _destinationLat,
          'destinationLng': _destinationLng,
          'carModel': _selectedCarModel!.displayName,
          'maxPrice': _maxPrice,
          'preferences': {
            'shelter': _needShelter,
            'cctv': _needCCTV,
            'evCharging': _needEVCharging,
            'premium': wantsPremium,
          },
          'usesML': true,
        },
      );
    } catch (e) {
      if (!mounted) return;
      print('Error in ML parking search: $e');
      
      // Show user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to find parking spaces. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _findParkingSpaces(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
'@

# Replace and save
$content = $content -replace [regex]::Escape($oldMethod), $newMethod
$content | Set-Content 'lib/views/driver/booking_screen.dart'

Write-Host "Replaced _findParkingSpaces method with ML integration!"
