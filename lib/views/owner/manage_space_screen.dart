import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../models/parking_space_model.dart';
import '../../services/parking_space_service.dart';

class ManageSpaceScreen extends StatefulWidget {
  const ManageSpaceScreen({super.key});

  @override
  State<ManageSpaceScreen> createState() => _ManageSpaceScreenState();
}

class _ManageSpaceScreenState extends State<ManageSpaceScreen> {
  List<ParkingSpace> _spaces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authState = context.read<AuthController>().state;
      if (authState.profile?.id != null) {
        final spaces = await ParkingSpaceService.getOwnerParkingSpaces(authState.profile!.id);
        setState(() {
          _spaces = spaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Spaces',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/add_space'),
            icon: const Icon(Icons.add_outlined),
            tooltip: 'Add New Space',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _spaces.isEmpty
                  ? _buildEmptyState()
                  : _buildSpacesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/add_space'),
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load parking spaces',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadSpaces,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_parking_outlined,
              size: 96,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Parking Spaces Yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first parking space to start\nearning from your property',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/add_space'),
              icon: const Icon(Icons.add_outlined),
              label: const Text('Add Parking Space'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpacesList() {
    return RefreshIndicator(
      onRefresh: _loadSpaces,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _spaces.length,
        itemBuilder: (context, index) {
          return _buildSpaceCard(_spaces[index]);
        },
      ),
    );
  }

  Widget _buildSpaceCard(ParkingSpace space) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Space Image (placeholder for now)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.primary,
                ],
              ),
            ),
            child: space.placeImageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      space.placeImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    ),
                  )
                : _buildPlaceholderImage(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            space.placeName,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Slot: ${space.slotNumber}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(space).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(space)),
                      ),
                      child: Text(
                        space.statusText,
                        style: TextStyle(
                          color: _getStatusColor(space),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        space.address,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Dimensions
                Row(
                  children: [
                    Icon(Icons.straighten_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${space.length}m × ${space.width}m × ${space.height}m',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewSpaceDetails(space),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _togglePause(space),
                        icon: Icon(space.isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined),
                        label: Text(space.isPaused ? 'Resume' : 'Pause'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_parking_outlined,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  void _viewSpaceDetails(ParkingSpace space) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpaceDetailsScreen(space: space),
      ),
    );
  }

  Future<void> _togglePause(ParkingSpace space) async {
    try {
      await ParkingSpaceService.togglePauseSpace(space.id, !space.isPaused);
      await _loadSpaces(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(space.isPaused ? 'Space resumed successfully!' : 'Space paused successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update space: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(ParkingSpace space) {
    final theme = Theme.of(context);
    if (space.isPaused) return theme.colorScheme.tertiary;
    if (!space.isActive) return theme.colorScheme.error;
    return theme.colorScheme.secondary;
  }
}

class SpaceDetailsScreen extends StatelessWidget {
  final ParkingSpace space;

  const SpaceDetailsScreen({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(space.placeName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Space Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary,
                  ],
                ),
              ),
              child: space.placeImageUrl != null
                  ? Image.network(
                      space.placeImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                    )
                  : _buildPlaceholderImage(context),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          space.placeName,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(space).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(space)),
                        ),
                        child: Text(
                          space.statusText,
                          style: TextStyle(
                            color: _getStatusColor(space),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Slot Number: ${space.slotNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location section
                  _buildSection(
                    context,
                    'Location',
                    Icons.location_on_outlined,
                    [
                      Text(
                        space.address,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates: ${space.latitude.toStringAsFixed(6)}, ${space.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dimensions section
                  _buildSection(
                    context,
                    'Dimensions',
                    Icons.straighten_outlined,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Length',
                              '${space.length}m',
                              theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Width',
                              '${space.width}m',
                              theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Height',
                              '${space.height}m',
                              theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Facilities section
                  _buildSection(
                    context,
                    'Available Facilities',
                    Icons.check_circle_outlined,
                    [
                      if (space.hasEvCharging || space.hasShelter || space.hasCctv)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (space.hasShelter)
                              _buildFacilityChip(context, 'Shelter', Icons.roofing_outlined, theme.colorScheme.primary),
                            if (space.hasCctv)
                              _buildFacilityChip(context, 'CCTV', Icons.security_outlined, theme.colorScheme.secondary),
                            if (space.hasEvCharging)
                              _buildFacilityChip(context, 'EV Charging', Icons.electric_car_outlined, theme.colorScheme.tertiary),
                          ],
                        )
                      else
                        Text(
                          'Basic parking (no additional facilities)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pricing section
                  _buildSection(
                    context,
                    'Pricing',
                    Icons.attach_money_outlined,
                    [
                      Text(
                        'Price per ${space.rentalMode}: \$${space.pricePerUnit}',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (space.isPremium) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.tertiary),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _togglePause(context, space),
                          icon: Icon(space.isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined),
                          label: Text(space.isPaused ? 'Resume' : 'Pause'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_parking_outlined,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityChip(BuildContext context, String label, IconData icon, Color color) {
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
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
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

  Color _getStatusColor(ParkingSpace space) {
    if (space.isPaused) return Colors.orange;
    if (!space.isActive) return Colors.red;
    return Colors.green;
  }

  Future<void> _togglePause(BuildContext context, ParkingSpace space) async {
    try {
      await ParkingSpaceService.togglePauseSpace(space.id, !space.isPaused);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Go back to the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(space.isPaused ? 'Space resumed successfully!' : 'Space paused successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update space: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}