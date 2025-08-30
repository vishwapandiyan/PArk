// Add this to state variables (line 37):
  final _maxPriceCtrl = TextEditingController(text: '150'); // Default max price
  int _maxPrice = 150;

// Add this to dispose method:
  _maxPriceCtrl.dispose();

// Add this new method for preferences card with max price:
  Widget _buildPreferencesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '⚙️ Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Select your preferred amenities:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPreferenceCheckbox(
              title: 'Shelter',
              subtitle: 'Covered parking space',
              icon: Icons.roofing,
              value: _needShelter,
              onChanged: (value) => setState(() => _needShelter = value ?? false),
            ),
            _buildPreferenceCheckbox(
              title: 'CCTV Surveillance',
              subtitle: '24/7 security monitoring',
              icon: Icons.security,
              value: _needCCTV,
              onChanged: (value) => setState(() => _needCCTV = value ?? false),
            ),
            _buildPreferenceCheckbox(
              title: 'EV Charging',
              subtitle: 'Electric vehicle charging station',
              icon: Icons.electric_car,
              value: _needEVCharging,
              onChanged: (value) => setState(() => _needEVCharging = value ?? false),
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
