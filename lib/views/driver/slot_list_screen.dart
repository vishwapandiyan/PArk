import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/slot_controller.dart';
import '../../models/booking_request_model.dart';
import '../../services/ml_service.dart';
import '../../widgets/slot_card.dart';
import '../../widgets/loading_indicator.dart';

class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  List<Map<String, dynamic>> _rankedSlots = [];
  bool _isLoadingML = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final controller = context.read<SlotController>();
    await controller.loadSlots();
  }

  Future<void> _getMLRecommendations() async {
    setState(() => _isLoadingML = true);

    try {
      final slots = context.read<SlotController>().state.slots;
      if (slots.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No parking slots available')),
        );
        return;
      }

      // Convert slots to JSON format for ML service
      final availableSlots = slots.map((slot) => {
        'id': slot.id,
        'address': slot.address,
        'latitude': slot.latitude,
        'longitude': slot.longitude,
        'dimensions': slot.dimensions,
        'pricing': slot.pricing,
        'has_shelter': slot.hasShelter,
        'has_cctv': slot.hasCCTV,
        'has_ev_charging': slot.hasEVCharging,
        'rating': slot.rating,
        'review_count': slot.reviewCount,
      }).toList();

      // Create a sample request for ML ranking
      final request = BookingRequestModel(
        destination: 'Downtown',
        departure: 'Evening',
        carDimensions: '4.8m x 1.8m x 1.4m',
        availableSlots: availableSlots,
        needShelter: true,
        needCCTV: true,
        needEVCharging: false,
      );

      final rankedSlots = await MLService.getRankedSlots(request);
      
      if (!mounted) return;
      
      setState(() {
        _rankedSlots = rankedSlots;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 ML recommendations loaded!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading ML recommendations: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingML = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Parking Slots'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoadingML ? null : _getMLRecommendations,
            icon: _isLoadingML
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.psychology),
            tooltip: 'Get AI Recommendations',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: BlocBuilder<SlotController, SlotState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: LoadingIndicator(size: 48),
              );
            }

            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading slots',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadSlots,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.slots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_parking_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No parking slots available',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for available parking spots',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final slotsToShow = _rankedSlots.isNotEmpty ? _rankedSlots : state.slots;

            return Column(
              children: [
                // Header with ML status
                if (_rankedSlots.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: Colors.green[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI-Powered Recommendations',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Showing ${_rankedSlots.length} optimized parking options',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Slots list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: slotsToShow.length,
                    itemBuilder: (context, index) {
                      final slot = slotsToShow[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SlotCard(
                          slot: slot,
                          onTap: () {
                            // Navigate to slot detail
                            Navigator.of(context).pushNamed(
                              '/slot_detail',
                              arguments: slot,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


