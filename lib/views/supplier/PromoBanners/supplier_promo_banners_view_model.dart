import 'package:flutter/material.dart';

class PromoBannerItem {
  final String id;
  final String targetBranches;
  final String validity;
  final String status;
  final int impressions;

  PromoBannerItem({
    required this.id,
    required this.targetBranches,
    required this.validity,
    required this.status,
    required this.impressions,
  });
}

class SupplierPromoBannersViewModel extends ChangeNotifier {
  List<PromoBannerItem> _banners = [];
  bool _loading = false;
  String _searchQuery = '';

  List<PromoBannerItem> get banners => _banners;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  set searchQuery(String v) {
    if (_searchQuery == v) return;
    _searchQuery = v;
    notifyListeners();
  }

  List<PromoBannerItem> get filteredBanners {
    if (_searchQuery.trim().isEmpty) return _banners;
    final q = _searchQuery.trim().toLowerCase();
    return _banners.where((b) {
      return b.targetBranches.toLowerCase().contains(q) ||
          b.validity.toLowerCase().contains(q) ||
          b.status.toLowerCase().contains(q) ||
          b.impressions.toString().contains(q);
    }).toList();
  }

  SupplierPromoBannersViewModel() {
    loadBanners();
  }

  void loadBanners() {
    _loading = true;
    notifyListeners();
    _banners = [
      PromoBannerItem(
        id: '1',
        targetBranches: 'Riyadh + Jeddah',
        validity: '01-28 Feb',
        status: 'Active',
        impressions: 12450,
      ),
    ];
    _loading = false;
    notifyListeners();
  }

  void deactivateBanner(String id) {
    final index = _banners.indexWhere((b) => b.id == id);
    if (index >= 0) {
      final b = _banners[index];
      _banners[index] = PromoBannerItem(
        id: b.id,
        targetBranches: b.targetBranches,
        validity: b.validity,
        status: 'Inactive',
        impressions: b.impressions,
      );
      notifyListeners();
    }
  }
}
