import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'super_admin_lockers_view_model.dart';

class SuperAdminLockersView extends StatelessWidget {
  const SuperAdminLockersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SuperAdminLockersViewModel()..refresh(),
      child: const _SuperAdminLockersContent(),
    );
  }
}

class _SuperAdminLockersContent extends StatefulWidget {
  const _SuperAdminLockersContent();

  @override
  State<_SuperAdminLockersContent> createState() => _SuperAdminLockersContentState();
}

class _SuperAdminLockersContentState extends State<_SuperAdminLockersContent> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuperAdminLockersViewModel>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primaryLight,
        elevation: 4,
        icon: const Icon(Icons.add_to_queue_rounded, color: AppColors.secondaryLight, size: 24),
        label: const Text('Deploy Terminal', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
      ),
      body: vm.isLoading && vm.filteredLockers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(context, vm, isDesktop),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildLockersGrid(context, vm, isDesktop),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Lockers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
            const SizedBox(height: 4),
            Text('Monitor and manage IoT smart locker terminals network-wide.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_to_queue_rounded, size: 18, color: AppColors.secondaryLight),
          label: const Text('Deploy Terminal', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, SuperAdminLockersViewModel vm, bool isDesktop) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: vm.setSearchQuery,
              style: const TextStyle(fontSize: 14, color: AppColors.secondaryLight),
              decoration: const InputDecoration(
                hintText: 'Search branches...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockersGrid(BuildContext context, SuperAdminLockersViewModel vm, bool isDesktop) {
    if (!isDesktop && MediaQuery.of(context).size.width < 600) {
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: vm.filteredLockers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildLockerCard(context, vm.filteredLockers[index], vm);
        },
      );
    }

    final crossAxisCount = isDesktop ? 3 : 2;
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: vm.filteredLockers.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final locker = vm.filteredLockers[index];
        return _buildLockerCard(context, locker, vm);
      },
    );
  }

  Widget _buildLockerCard(BuildContext context, Map<String, dynamic> locker, SuperAdminLockersViewModel vm) {
    final availabilityRatio = (locker['availableBoxes'] as int) / (locker['totalBoxes'] as int);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48, // Reduced from 52
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.terminal_rounded, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locker['location'] ?? 'Unknown Location', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight)),
                    const SizedBox(height: 2),
                    Text('ID: ${locker['id'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AVAILABILITY', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('${locker['availableBoxes'] ?? 0} / ${locker['totalBoxes'] ?? 0} available', style: const TextStyle(fontSize: 12, color: AppColors.secondaryLight, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: availabilityRatio,
              backgroundColor: Colors.grey.shade100,
               valueColor: AlwaysStoppedAnimation<Color>(availabilityRatio > 0.5 ? const Color(0xFF10B981) : AppColors.secondaryLight),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sync_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Sync: ${locker['lastSync'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
