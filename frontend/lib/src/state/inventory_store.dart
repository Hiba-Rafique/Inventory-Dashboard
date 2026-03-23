import '../models/category.dart';
import '../models/material_item.dart';
import '../services/inventory_api.dart';
import 'package:flutter/foundation.dart' hide Category;

enum MaterialsViewMode { all, byCategory }

/// Holds a snapshot of all derived state the UI needs.
class InventoryState {
  final bool loading;
  final String? error;
  final List<Category> categories;
  final List<MaterialItem> materials;
  final Map<String, int> categoryCounts;
  final int allMaterialsCount;
  final String? selectedCategoryId;
  final MaterialsViewMode mode;

  const InventoryState({
    this.loading = false,
    this.error,
    this.categories = const [],
    this.materials = const [],
    this.categoryCounts = const {},
    this.allMaterialsCount = 0,
    this.selectedCategoryId,
    this.mode = MaterialsViewMode.all,
  });

  InventoryState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<Category>? categories,
    List<MaterialItem>? materials,
    Map<String, int>? categoryCounts,
    int? allMaterialsCount,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    MaterialsViewMode? mode,
  }) {
    return InventoryState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      categories: categories ?? this.categories,
      materials: materials ?? this.materials,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      allMaterialsCount: allMaterialsCount ?? this.allMaterialsCount,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      mode: mode ?? this.mode,
    );
  }
}

class InventoryStore {
  final InventoryApi api;
  final String companyId;

  InventoryStore({required this.api, required this.companyId});

  /// The single source of truth for the UI.
  final ValueNotifier<InventoryState> state =
      ValueNotifier(const InventoryState());

  // ── internal raw cache ──────────────────────────────────────────────
  List<MaterialItem> _materialsCache = const [];

  // ── public helpers for quick access ─────────────────────────────────
  InventoryState get _s => state.value;

  // ── derived list based on mode / selected category ──────────────────
  List<MaterialItem> _filtered(
    List<MaterialItem> all,
    MaterialsViewMode mode,
    String? selectedCategoryId,
  ) {
    if (mode == MaterialsViewMode.all) return all;
    return all.where((m) => m.categoryId == selectedCategoryId).toList();
  }

  Map<String, int> _buildCounts(List<MaterialItem> all) {
    final counts = <String, int>{};
    for (final m in all) {
      if (m.categoryId != null) {
        counts[m.categoryId!] = (counts[m.categoryId!] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ── actions ─────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await _run(() async {
      final cats =
          await api.listCategories(companyId: companyId, isActive: true);
      final mats =
          await api.listMaterials(companyId: companyId, isActive: true);
      _materialsCache = mats;

      state.value = _s.copyWith(
        categories: cats,
        materials: _filtered(mats, _s.mode, _s.selectedCategoryId),
        categoryCounts: _buildCounts(mats),
        allMaterialsCount: mats.length,
      );
    });
  }

  void setMode(MaterialsViewMode mode) {
    if (_s.mode == mode) return;
    state.value = _s.copyWith(
      mode: mode,
      materials: _filtered(_materialsCache, mode, _s.selectedCategoryId),
    );
  }

  void selectCategory(String? categoryId) {
    state.value = _s.copyWith(
      selectedCategoryId: categoryId,
      clearSelectedCategory: categoryId == null,
      materials: _filtered(_materialsCache, _s.mode, categoryId),
    );
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
      if (_s.selectedCategoryId == id) {
        state.value = _s.copyWith(clearSelectedCategory: true);
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

  // ── internal runner ─────────────────────────────────────────────────
  Future<void> _run(Future<void> Function() fn) async {
    state.value = _s.copyWith(loading: true, clearError: true);
    try {
      await fn();
    } catch (e) {
      state.value = _s.copyWith(error: e.toString());
    } finally {
      state.value = _s.copyWith(loading: false);
    }
  }

  void dispose() {
    state.dispose();
  }
}
