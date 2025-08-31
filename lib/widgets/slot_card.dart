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
    final theme = Theme.of(context);
    
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dimensions ?? 'Dimensions not available'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$${pricing?.toString() ?? 'N/A'}/hr',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
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
                    Icons.star_outlined,
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${rating?.toStringAsFixed(1) ?? 'N/A'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${reviewCount ?? 0} reviews)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                      'Shelter',
                      Icons.roofing_outlined,
                      theme.colorScheme.primary,
                    ),
                  if (hasCCTV == true)
                    _buildAmenityChip(
                      context,
                      'CCTV',
                      Icons.security_outlined,
                      theme.colorScheme.secondary,
                    ),
                  if (hasEVCharging == true)
                    _buildAmenityChip(
                      context,
                      'EV Charging',
                      Icons.electric_car_outlined,
                      theme.colorScheme.tertiary,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View Details',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


