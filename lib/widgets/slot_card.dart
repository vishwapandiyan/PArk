import 'package:flutter/material.dart';
import '../models/parking_slot_model.dart';
import '../services/enhanced_ml_service.dart';

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
    
    // Handle EnhancedParkingSlot, ParkingSlotModel, and Map<String, dynamic>
    String? address;
    dynamic pricing;
    String? dimensions;
    double? rating;
    int? reviewCount;
    bool? hasShelter;
    bool? hasCCTV;
    bool? hasEVCharging;
    double? mlScore;
    bool hasDynamicPricing = false;
    
    if (slot is EnhancedParkingSlot) {
      // EnhancedParkingSlot with ML data
      final enhancedSlot = slot as EnhancedParkingSlot;
      address = enhancedSlot.placeName;
      pricing = enhancedSlot.getCurrentPrice('hourly');
      dimensions = '${enhancedSlot.length}m × ${enhancedSlot.width}m × ${enhancedSlot.height}m';
      rating = 4.5; // Default rating
      reviewCount = 0; // Default review count
      hasShelter = enhancedSlot.hasShelter;
      hasCCTV = enhancedSlot.hasCctv;
      hasEVCharging = enhancedSlot.hasEvCharging;
      mlScore = enhancedSlot.mlScore;
      hasDynamicPricing = enhancedSlot.hasDynamicPricing;
    } else if (slot is ParkingSlotModel) {
      // Original ParkingSlotModel
      address = slot.address;
      pricing = slot.pricing;
      dimensions = slot.dimensions;
      rating = slot.rating;
      reviewCount = slot.reviewCount;
      hasShelter = slot.hasShelter;
      hasCCTV = slot.hasCCTV;
      hasEVCharging = slot.hasEVCharging;
    } else {
      // Map<String, dynamic> fallback
      address = slot['address'];
      pricing = slot['pricing'];
      dimensions = slot['dimensions'];
      rating = slot['rating'];
      reviewCount = slot['review_count'];
      hasShelter = slot['has_shelter'];
      hasCCTV = slot['has_cctv'];
      hasEVCharging = slot['has_ev_charging'];
    }

    return Card(
      elevation: 3,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dimensions ?? 'Dimensions not available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        // Show ML Score if available
                        if (mlScore != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 16,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ML Score: ${mlScore.toStringAsFixed(3)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (hasDynamicPricing) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'DYNAMIC',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasDynamicPricing ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${pricing?.toString() ?? 'N/A'}/hr',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
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


