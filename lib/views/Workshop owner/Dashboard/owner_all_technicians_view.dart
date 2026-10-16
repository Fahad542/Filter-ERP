import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../services/session_service.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';

// ── ViewModel ─────────────────────────────────────────────────────────────────

class OwnerAllTechniciansViewModel extends ChangeNotifier
    with TranslatableMixin {
  final OwnerRepository _repository = OwnerRepository();
  final SessionService _sessionService = SessionService();
  final String? branchId;
  final SettingsViewModel? settingsViewModel;

  OwnerAllTechniciansViewModel({this.branchId, this.settingsViewModel}) {
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
    _load();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Raw API data — always English, never mutated with translations.
  List<ActiveTechnicianItem> _all = [];

  /// Translated overlay keyed by technician id.
  final Map<String, ActiveTechnicianItem> _translatedCache = {};

  String _query = '';
  String get query => _query;

  List<ActiveTechnicianItem> get _displayAll =>
      _all.map((t) => _translatedCache[t.id] ?? t).toList();

  List<ActiveTechnicianItem> get technicians {
    final all = _displayAll;
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((t) =>
    t.name.toLowerCase().contains(q) ||
        t.branchName.toLowerCase().contains(q) ||
        t.mobile.contains(q) ||
        t.departments.any((d) => d.name.toLowerCase().contains(q)),
    ).toList();
  }

  int get totalCount   => _all.length;
  int get onlineCount  => _all.where((t) => t.isOnline).length;
  int get offlineCount => _all.where((t) => !t.isOnline).length;

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  Future<void> retranslate() async {
    await _applyTranslations();
    notifyListeners();
  }

  Future<void> _applyTranslations() async {
    final translated = await Future.wait(_all.map(_translateTechnician));
    _translatedCache
      ..clear()
      ..addEntries(translated.map((t) => MapEntry(t.id, t)));
  }

  Future<ActiveTechnicianItem> _translateTechnician(
      ActiveTechnicianItem tech) async {
    final translatedDepts = await Future.wait(tech.departments.map(
      (d) async => d.copyWith(translatedName: await t(d.name)),
    ));
    return tech.copyWith(
      translatedName: await tPerson(tech.name),
      translatedBranchName: await tBranch(tech.branchName),
      departments: translatedDepts,
    );
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _sessionService.getToken(role: 'owner');
      if (token == null) {
        _error = 'Session expired. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _repository.getActiveTechnicians(
        token,
        branchId: branchId,
      );

      if (response.success) {
        _all = response.technicians;
        await _applyTranslations();
      } else {
        _error = 'Failed to load technicians.';
      }
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      debugPrint('[OwnerAllTechniciansVM] error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    super.dispose();
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class OwnerAllTechniciansView extends StatelessWidget {
  final String? branchId;
  const OwnerAllTechniciansView({super.key, this.branchId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => OwnerAllTechniciansViewModel(
        branchId: branchId,
        settingsViewModel: ctx.read<SettingsViewModel>(),
      ),
      child: Consumer<OwnerAllTechniciansViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: OwnerAppBar(
            title: 'Technicians',
            showBackButton: true,
            showNotification: false,
          ),
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            color: AppColors.primaryLight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── KPI row ────────────────────────────────────────
                      _TechnicianKPIRow(vm: vm),
                      const SizedBox(height: 20),

                      // ── Search ─────────────────────────────────────────
                      CustomSearchBar(
                        onChanged: vm.setQuery,
                        hintText: 'Search name, branch, department…',
                      ),
                      const SizedBox(height: 14),

                      // ── List ───────────────────────────────────────────
                      _TechnicianList(vm: vm),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _TechnicianKPIRow extends StatelessWidget {
  final OwnerAllTechniciansViewModel vm;
  const _TechnicianKPIRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final loading = vm.isLoading;
    return ReusableKpiGrid(
      metrics: [
        ReusableKpiMetric(
          title: 'Total',
          value: loading ? '—' : '${vm.totalCount}',
          icon: Icons.engineering_rounded,
        ),
        ReusableKpiMetric(
          title: 'Online',
          value: loading ? '—' : '${vm.onlineCount}',
          icon: Icons.wifi_rounded,
        ),
        ReusableKpiMetric(
          title: 'Offline',
          value: loading ? '—' : '${vm.offlineCount}',
          icon: Icons.wifi_off_rounded,
        ),
      ],
      childAspectRatio: 1.75,
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────────

class _TechnicianList extends StatelessWidget {
  final OwnerAllTechniciansViewModel vm;
  const _TechnicianList({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const OwnerListPageShimmer(
        itemCount: 5,
        padding: EdgeInsets.zero,
      );
    }
    if (vm.error != null) return _ErrorState(vm: vm);
    if (vm.technicians.isEmpty) {
      return _EmptyState(isFiltered: vm.query.isNotEmpty);
    }

    return Column(
      children: [
        for (int i = 0; i < vm.technicians.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TechnicianCard(technician: vm.technicians[i]),
          ),
      ],
    );
  }
}

// ── Technician card ───────────────────────────────────────────────────────────

class _TechnicianCard extends StatelessWidget {
  final ActiveTechnicianItem technician;
  const _TechnicianCard({required this.technician});

  @override
  Widget build(BuildContext context) {
    final t = technician;
    final isOnline = t.isOnline;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ────────────────────────────────────────────────
            _Avatar(initials: t.initials, isOnline: isOnline),
            const SizedBox(width: 12),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          t.displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2340),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(isOnline: isOnline),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Info grid (2 columns) ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _InfoRow(
                          icon: Icons.store_rounded,
                          text: t.displayBranchName.isNotEmpty
                              ? t.displayBranchName
                              : '—',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoRow(
                          icon: Icons.phone_rounded,
                          text: t.mobile.isNotEmpty ? t.mobile : '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoRow(
                          icon: Icons.percent_rounded,
                          text:
                          '${t.commissionPercent.toStringAsFixed(t.commissionPercent % 1 == 0 ? 0 : 2)}% Commission',
                        ),
                      ),
                    ],
                  ),

                  // ── Departments ───────────────────────────────────
                  if (t.departments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: t.departments
                          .map((d) => _DeptChip(name: d.displayName))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final bool isOnline;
  const _Avatar({required this.initials, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF27AE60)
                  : Colors.grey.shade400,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isOnline;
  const _StatusBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFFE8F8EF)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOnline ? const Color(0xFF27AE60) : Colors.grey.shade500,
        ),
      ),
    );
  }
}

// ── Department chip ───────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  final String name;
  const _DeptChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_rounded,
            size: 10,
            color: AppColors.primaryLight.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isFiltered
                ? Icons.search_off_rounded
                : Icons.engineering_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered
                ? 'No technicians match your search'
                : 'No active technicians found',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final OwnerAllTechniciansViewModel vm;
  const _ErrorState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: Colors.red.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            vm.error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: vm.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.secondaryLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}