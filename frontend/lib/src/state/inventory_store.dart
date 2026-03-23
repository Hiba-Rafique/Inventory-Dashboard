import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../models/material_item.dart';
import '../services/inventory_api.dart';

enum MaterialsViewMode { all, byCategory }

class InventoryStore extends ChangeNotifier {
  final InventoryApi api;
  final String companyId;

  InventoryStore({required this.api, required this.companyId});

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Category> _categories = const [];
  List<Category> get categories => _categories;

  List<MaterialItem>? _materialsCache;

  int get allMaterialsCount {
    if (_materialsCache == null && !_loading) {
      Future.microtask(refresh);
    }
    return (_materialsCache ?? const []).length;
  }

  List<MaterialItem> get materials {
    if (_materialsCache == null && !_loading) {
      Future.microtask(refresh);
    }
    final list = _materialsCache ?? const [];
    if (_mode == MaterialsViewMode.all) return list;
    return list.where((m) => m.categoryId == _selectedCategoryId).toList();
  }

  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final m in (_materialsCache ?? const [])) {
      if (m.categoryId != null) {
        counts[m.categoryId!] = (counts[m.categoryId!] ?? 0) + 1;
      }
    }
    return counts;
  }

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  MaterialsViewMode _mode = MaterialsViewMode.all;
  MaterialsViewMode get mode => _mode;

  Future<void> refresh() async {
    await _run(() async {
      final cats = await api.listCategories(companyId: companyId, isActive: true);
      _categories = cats;

      final mats = await api.listMaterials(
        companyId: companyId,
        isActive: true,
      );
      _materialsCache = mats;
    });
  }

  void setMode(MaterialsViewMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _run(() async {
      await api.createCategory(companyId: companyId, name: name);
      await refresh();
    });
  }

  Future<void> deleteCategory(String id) async {
    await _run(() async {
      await api.deleteCategory(id: id, companyId: companyId);
      if (_selectedCategoryId == id) {
        _selectedCategoryId = null;
      }
      await refresh();
    });
  }

  Future<void> addMaterial({
    required String name,
    required String unit,
    required double price,
    required String brand,
    String? categoryId,
  }) async {
    await _run(() async {
      await api.createMaterial(
        companyId: companyId,
        name: name,
        unit: unit,
        brand: brand,
        price: price,
        categoryId: categoryId,
      );
      await refresh();
    });
  }

  Future<void> updateMaterial(MaterialItem item) async {
    await _run(() async {
      await api.updateMaterial(
        id: item.id,
        companyId: companyId,
        name: item.name,
        brand: item.brand,
        price: item.price,
        unit: item.unit,
        categoryId: item.categoryId,
        isActive: item.isActive,
      );
      await refresh();
    });
  }

  Future<void> deleteMaterial(String id) async {
    await _run(() async {
      await api.deleteMaterial(id: id, companyId: companyId);
      await refresh();
    });
  }

  Future<void> _run(Future<void> Function() fn) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await fn();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
