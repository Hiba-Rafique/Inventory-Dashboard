import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/material_item.dart';
import '../state/inventory_store.dart';

class InventoryScreen extends StatefulWidget {
  final InventoryStore store;

  const InventoryScreen({super.key, required this.store});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  InventoryStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InventoryState>(
      valueListenable: store.state,
      builder: (context, s, _) {
        final scheme = Theme.of(context).colorScheme;

        Category? selectedCategory;
        final selectedId = s.selectedCategoryId;
        if (selectedId != null) {
          for (final c in s.categories) {
            if (c.id == selectedId) {
              selectedCategory = c;
              break;
            }
          }
        }

        final title = s.mode == MaterialsViewMode.all
            ? 'All Materials'
            : (selectedCategory?.name ?? 'By Category');

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            final categoriesPane = _CategoriesPane(
              categories: s.categories,
              categoryCounts: s.categoryCounts,
              allMaterialsCount: s.allMaterialsCount,
              selectedCategoryId: s.selectedCategoryId,
              onSelect: store.selectCategory,
              onAdd: () => _showAddCategoryDialog(context),
              onDelete: (id) => store.deleteCategory(id),
            );

            final body = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!wide)
                          IconButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        Text(
                          title.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF0284C7),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        // Sleek Search Bar
                        SizedBox(
                          width: 220,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search materials...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: s.loading ? null : () => _showAddMaterialDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (s.error != null)
                  Container(
                    width: double.infinity,
                    color: scheme.errorContainer,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      s.error!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                Expanded(
                  child: _MaterialsList(
                    loading: s.loading,
                    materials: s.materials,
                    categories: s.categories,
                    onEdit: (m) => _showEditMaterialDialog(context, m),
                    onDelete: (id) => store.deleteMaterial(id),
                  ),
                ),
              ],
            );

            if (wide) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC), // Slight slate-50 background for main area
                body: Row(
                  children: [
                    SizedBox(width: 280, child: categoriesPane), // Increased for better text fit
                    Expanded(child: body),
                  ],
                ),
              );
            }

            return Scaffold(
              drawer: Drawer(child: SafeArea(child: categoriesPane)),
              body: body,
            );
          },
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Category', style: Theme.of(context).textTheme.titleLarge),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    await store.addCategory(result);
  }

  Future<void> _showAddMaterialDialog(BuildContext context) async {
    final s = store.state.value;

    final result = await showDialog<_MaterialDraft>(
      context: context,
      builder: (context) {
        return _MaterialDialog(
          title: 'Add Material',
          categories: s.categories,
          initial: _MaterialDraft(
            name: '',
            brand: '',
            unit: 'pcs',
            price: 0,
            categoryId: s.selectedCategoryId,
          ),
        );
      },
    );

    if (result == null) return;

    await store.addMaterial(
      name: result.name,
      brand: result.brand,
      unit: result.unit,
      price: result.price,
      categoryId: result.categoryId,
    );
  }

  Future<void> _showEditMaterialDialog(BuildContext context, MaterialItem item) async {
    final s = store.state.value;

    final result = await showDialog<_MaterialDraft>(
      context: context,
      builder: (context) {
        return _MaterialDialog(
          title: 'Edit Material',
          categories: s.categories,
          initial: _MaterialDraft(
            id: item.id,
            name: item.name,
            brand: item.brand,
            unit: item.unit,
            price: item.price,
            categoryId: item.categoryId,
          ),
        );
      },
    );

    if (result == null) return;

    await store.updateMaterial(
      item.copyWith(
        name: result.name,
        brand: result.brand,
        unit: result.unit,
        price: result.price,
        categoryId: result.categoryId,
      ),
    );
  }
}

class _CategoriesPane extends StatelessWidget {
  final List<Category> categories;
  final Map<String, int> categoryCounts;
  final int allMaterialsCount;
  final String? selectedCategoryId;
  final void Function(String? id) onSelect;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;

  const _CategoriesPane({
    required this.categories,
    required this.categoryCounts,
    required this.allMaterialsCount,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Crisp white sidebar
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'CATEGORIES',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF0284C7),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5, // Unified
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, color: Color(0xFF0284C7), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final selected = selectedCategoryId == null;
                return _CategoryTile(
                  selected: selected,
                  title: 'All',
                  count: allMaterialsCount,
                  onTap: () => onSelect(null),
                );
              }

              final c = categories[index - 1];
              final selected = c.id == selectedCategoryId;
              final count = categoryCounts[c.id] ?? 0;

              return _CategoryTile(
                selected: selected,
                title: c.name,
                count: count,
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete(c.id);
                  },
                ),
                onTap: () => onSelect(c.id),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}

class _CategoryTile extends StatelessWidget {
  final bool selected;
  final String title;
  final int count;
  final VoidCallback onTap;
  final Widget? trailing;

  const _CategoryTile({
    required this.selected,
    required this.title,
    required this.count,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                  maxLines: 2, // Allow 2 lines for longer category names
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _Pill(
                text: count.toString(),
                background: Colors.transparent,
                foreground: const Color(0xFF0284C7),
              ),
            ],
          ),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _MaterialsList extends StatelessWidget {
  final bool loading;
  final List<MaterialItem> materials;
  final List<Category> categories;
  final void Function(MaterialItem item) onEdit;
  final void Function(String id) onDelete;

  const _MaterialsList({
    required this.loading,
    required this.materials,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && materials.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (materials.isEmpty) {
      return const Center(child: Text('No materials')); 
    }

    final currency = NumberFormat.currency(symbol: '\$');
    final catById = {for (final c in categories) c.id: c};

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        int columns = 1;
        if (constraints.maxWidth > 900) {
          columns = 4;
        } else if (constraints.maxWidth > 650) {
          columns = 3;
        } else if (constraints.maxWidth > 400) {
          columns = 2;
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 0, wide ? 32 : 16, wide ? 32 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 150,
          ),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final m = materials[index];
            final cat = m.categoryId == null ? null : catById[m.categoryId!];

            return _MaterialCard(
              m: m,
              cat: cat,
              currency: currency,
              onEdit: () => onEdit(m),
              onDelete: () => onDelete(m.id),
            );
          },
        );
      },
    );
  }
}

class _MaterialCard extends StatefulWidget {
  final MaterialItem m;
  final Category? cat;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.m,
    this.cat,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hovering ? -2.0 : 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // --r-lg
        border: Border.all(
          color: const Color(0xFFE2E8F0), // --color-border
          width: 1,
        ),
        boxShadow: _hovering
            ? const [
                BoxShadow(color: Color(0x120F172A), blurRadius: 8, offset: Offset(0, 4)),
              ]
            : const [
                BoxShadow(color: Color(0x0F0F172A), blurRadius: 2, offset: Offset(0, 1)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          hoverColor: const Color(0xFFF0F9FF),
          onTap: widget.onEdit,
          onHover: (val) => setState(() => _hovering = val),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.m.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, color: Color(0xFF94A3B8), size: 20),
                        hoverColor: const Color(0xFFFEE2E2),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (widget.m.brand.isNotEmpty) widget.m.brand,
                    if (widget.cat != null) widget.cat!.name,
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.currency.format(widget.m.price),
                      style: GoogleFonts.robotoMono(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0284C7),
                        fontSize: 16,
                      ),
                    ),
                    _Pill(
                      text: widget.m.unit,
                      background: const Color(0xFFE0F2FE),
                      foreground: const Color(0xFF0369A1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2), // --r-xs from doc
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontSize: 9, // Tighter font
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ClayPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isClay;
  final Color? background;
  final bool borderless;
  final double radius;

  const _ClayPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.isClay = false,
    this.background,
    this.borderless = false,
    this.radius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // Highly refined subtle shadows (flat for small, lifted for large)
    final shadowColor = isClay ? const Color(0xFFBAE6FD) : const Color(0x0A0F172A);
    final borderCol = isClay ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: background ?? (isClay ? const Color(0xFFF0F9FF) : Colors.white),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderCol, width: 1.5),
        boxShadow: [
          if (isClay)
            const BoxShadow(
              color: Color(0xFFBAE6FD),
              offset: Offset(0, 4),
              blurRadius: 0,
            )
          else ...[
            const BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 2),
            const BoxShadow(color: Color(0x050F172A), offset: Offset(0, 4), blurRadius: 8),
          ],
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MaterialDraft {
  final String? id;
  final String name;
  final String brand;
  final String unit;
  final double price;
  final String? categoryId;

  const _MaterialDraft({
    this.id,
    required this.name,
    required this.brand,
    required this.unit,
    required this.price,
    required this.categoryId,
  });
}

class _MaterialDialog extends StatefulWidget {
  final String title;
  final List<Category> categories;
  final _MaterialDraft initial;

  const _MaterialDialog({
    required this.title,
    required this.categories,
    required this.initial,
  });

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  late final TextEditingController nameController;
  late final TextEditingController brandController;
  late final TextEditingController priceController;

  late String unit;
  String? categoryId;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initial.name);
    brandController = TextEditingController(text: widget.initial.brand);
    priceController = TextEditingController(text: widget.initial.price.toString());
    unit = widget.initial.unit;
    categoryId = widget.initial.categoryId;
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: unit,
                items: const [
                  DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                  DropdownMenuItem(value: 'lft', child: Text('lft')),
                  DropdownMenuItem(value: 'sqft', child: Text('sqft')),
                  DropdownMenuItem(value: 'bag', child: Text('bag')),
                ],
                onChanged: (v) => setState(() => unit = v ?? 'pcs'),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: categoryId,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('No category')),
                  ...widget.categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => categoryId = v),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            final brand = brandController.text.trim();
            final price = double.tryParse(priceController.text.trim()) ?? 0;

            if (name.isEmpty) return;

            Navigator.pop(
              context,
              _MaterialDraft(
                id: widget.initial.id,
                name: name,
                brand: brand,
                unit: unit,
                price: price,
                categoryId: categoryId,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
