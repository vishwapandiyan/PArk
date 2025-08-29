import 'package:flutter/material.dart';
import '../models/parking_slot_model.dart';

class SlotCard extends StatelessWidget {
  final dynamic slot;
  final VoidCallback onTap;

  const SlotCard({
    super.key,
    required this.slot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Handle both ParkingSlotModel and Map<String, dynamic>
    final address = slot is ParkingSlotModel ? slot.address : slot['address'];
    final pricing = slot is ParkingSlotModel ? slot.pricing : slot['pricing'];
    final dimensions = slot is ParkingSlotModel ? slot.dimensions : slot['dimensions'];
    final rating = slot is ParkingSlotModel ? slot.rating : slot['rating'];
    final reviewCount = slot is ParkingSlotModel ? slot.reviewCount : slot['review_count'];
    final hasShelter = slot is ParkingSlotModel ? slot.hasShelter : slot['has_shelter'];
    final hasCCTV = slot is ParkingSlotModel ? slot.hasCCTV : slot['has_cctv'];
    final hasEVCharging = slot is ParkingSlotModel ? slot.hasEVCharging : slot['has_ev_charging'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with address and price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address ?? 'Address not available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📏 ${dimensions ?? 'Dimensions not available'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$${pricing?.toString() ?? 'N/A'}/hr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Rating and reviews
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${rating?.toStringAsFixed(1) ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${reviewCount ?? 0} reviews)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amenities
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasShelter == true)
                    _buildAmenityChip(
                      context,
                      '🏠 Shelter',
                      Colors.blue[100]!,
                      Colors.blue[700]!,
                    ),
                  if (hasCCTV == true)
                    _buildAmenityChip(
                      context,
                      '📹 CCTV',
                      Colors.green[100]!,
                      Colors.green[700]!,
                    ),
                  if (hasEVCharging == true)
                    _buildAmenityChip(
                      context,
                      '🔌 EV Charging',
                      Colors.orange[100]!,
                      Colors.orange[700]!,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}


