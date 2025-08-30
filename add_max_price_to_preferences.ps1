# Read the booking screen file
$content = Get-Content 'lib/views/driver/booking_screen.dart' -Raw

# Find and replace the end of preferences card
$oldEndOfPreferences = @'
            _buildPreferenceSwitch(
              'EV Charging',
              'Electric vehicle charging station',
              Icons.electric_car,
              _needEVCharging,
              (value) => setState(() => _needEVCharging = value),
            ),
          ],
        ),
      ),
    );
  }
'@

$newEndOfPreferences = @'
            _buildPreferenceSwitch(
              'EV Charging',
              'Electric vehicle charging station',
              Icons.electric_car,
              _needEVCharging,
              (value) => setState(() => _needEVCharging = value),
            ),
            
            const SizedBox(height: 16),
            
            // Max Price Input
            Text(
              'Maximum Price (per hour):',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Max Price (₹)',
                hintText: 'Enter maximum price per hour',
                prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                final price = int.tryParse(value);
                if (price != null && price > 0) {
                  setState(() => _maxPrice = price);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter maximum price';
                }
                final price = int.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
'@

# Replace and save
$content = $content -replace [regex]::Escape($oldEndOfPreferences), $newEndOfPreferences
$content | Set-Content 'lib/views/driver/booking_screen.dart'

Write-Host "Added max price field to preferences card!"
