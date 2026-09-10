import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/worker_discovery_repository.dart';

class ServiceDiscoveryScreen extends ConsumerStatefulWidget {
  final String serviceCategory;
  const ServiceDiscoveryScreen({super.key, required this.serviceCategory});

  @override
  ConsumerState<ServiceDiscoveryScreen> createState() => _ServiceDiscoveryScreenState();
}

class _ServiceDiscoveryScreenState extends ConsumerState<ServiceDiscoveryScreen> {
  // Mock state for verified workers nearby
  bool _isLoading = true;
  List<DiscoveredWorker> _workers = <DiscoveredWorker>[];

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      final IWorkerDiscoveryRepository repo = ref.read(workerDiscoveryRepositoryProvider);
      // Using mock coordinates for now, usually would come from location service
      final List<DiscoveredWorker> workers = await repo.findNearbyWorkers(
        latitude: 19.1136, 
        longitude: 72.8697, 
        skill: widget.serviceCategory,
      );
      if (mounted) {
        setState(() {
          _workers = workers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find ${widget.serviceCategory}'),
      ),
      body: Column(
        children: [
          // Location Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceLight,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Location', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Andheri East, Mumbai', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Change'),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _workers.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _workers.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _buildWorkerCard(_workers[index]);
                        },
                      )
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(DiscoveredWorker worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: AppColors.success, size: 16),
                        ],
                      ),
                      Text('${worker.skills.isNotEmpty ? worker.skills.first : 'Worker'} • ${worker.formattedDistance} away', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      if (worker.reviewCount > 0)
                        Row(
                          children: <Widget>[
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(' ${worker.ratingAvg.toStringAsFixed(1)} (${worker.reviewCount} jobs)', style: const TextStyle(fontSize: 13)),
                          ],
                        )
                      else
                        const Text('No reviews yet', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                SizedBox(width: 4),
                Text('Available today', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Navigate to worker profile / booking selection
                },
                child: const Text('Book Now'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No verified workers found nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your location or selecting a different service.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Change Location'),
            )
          ],
        ),
      ),
    );
  }
}
