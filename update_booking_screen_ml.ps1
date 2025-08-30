# Read the booking screen file
$content = Get-Content 'lib/views/driver/booking_screen.dart' -Raw

# Add imports at the top
$oldImports = @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/slot_controller.dart';

import '../../models/car_model.dart';

import '../../services/car_service.dart';

import '../../widgets/destination_maps_picker.dart';
'@

$newImports = @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/slot_controller.dart';

import '../../models/car_model.dart';
import '../../models/ml_request_model.dart';

import '../../services/car_service.dart';
import '../../services/enhanced_ml_service.dart';

import '../../widgets/destination_maps_picker.dart';
'@

# Replace imports
$content = $content -replace [regex]::Escape($oldImports), $newImports

# Add max price variables after the existing state variables
$oldStateVars = @'
  // Preferences
  bool _needShelter = false;
  bool _needCCTV = false;
  bool _needEVCharging = false;
  bool _isLoading = false;
'@

$newStateVars = @'
  // Preferences
  bool _needShelter = false;
  bool _needCCTV = false;
  bool _needEVCharging = false;
  bool _isLoading = false;
  
  // Max price
  final _maxPriceCtrl = TextEditingController(text: '150');
  int _maxPrice = 150;
'@

# Replace state variables
$content = $content -replace [regex]::Escape($oldStateVars), $newStateVars

# Add dispose for max price controller
$oldDispose = @'
  @override
  void dispose() {
    super.dispose();
  }
'@

$newDispose = @'
  @override
  void dispose() {
    _maxPriceCtrl.dispose();
    super.dispose();
  }
'@

# Replace dispose method
$content = $content -replace [regex]::Escape($oldDispose), $newDispose

# Save the file
$content | Set-Content 'lib/views/driver/booking_screen.dart'

Write-Host "Updated booking screen with ML imports and max price field!"
