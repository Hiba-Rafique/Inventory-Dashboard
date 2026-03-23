import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/material_item.dart';
import '../state/inventory_store.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryStore>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();
    final scheme = Theme.of(context).colorScheme;

    Category? selectedCategory;
    final selectedId = store.selectedCategoryId;
    if (selectedId != null) {
      for (final c in store.categories) {
        if (c.id == selectedId) {
          selectedCategory = c;
          break;
        }
      }
    }

    final title = store.mode == MaterialsViewMode.all
        ? 'All Materials'
        : (selectedCategory?.name ?? 'By Category');

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        final categoriesPane = _CategoriesPane(
          categories: store.categories,
          categoryCounts: store.categoryCounts,
          allMaterialsCount: store.allMaterialsCount,
          selectedCategoryId: store.selectedCategoryId,
          onSelect: store.selectCategory,
          onAdd: () => _showAddCategoryDialog(context),
          onDelete: (id) => store.deleteCategory(id),
        );

        final body = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: _ClayPanel(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                radius: 16.0,
                child: Row(
                  children: [
                    if (!wide)
                      IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 12),
                    SegmentedButton<MaterialsViewMode>(
                      segments: const [
                        ButtonSegment(value: MaterialsViewMode.all, label: Text('All')),
                        ButtonSegment(value: MaterialsViewMode.byCategory, label: Text('By Category')),
                      ],
                      selected: {store.mode},
                      onSelectionChanged: (s) {
                        if (s.isEmpty) return;
                        store.setMode(s.first);
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(const StadiumBorder()),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: store.loading ? null : () => _showAddMaterialDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Material'),
                    ),
                  ],
                ),
              ),
            ),
            if (store.error != null)
              Container(
                width: double.infinity,
                color: scheme.errorContainer,
                padding: const EdgeInsets.all(12),
                child: Text(
                  store.error!,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            Expanded(
              child: _MaterialsList(
                loading: store.loading,
                materials: store.materials,
                categories: store.categories,
                onEdit: (m) => _showEditMaterialDialog(context, m),
                onDelete: (id) => store.deleteMaterial(id),
              ),
            ),
          ],
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 280, child: categoriesPane),
                const VerticalDivider(width: 1),
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
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final store = context.read<InventoryStore>();
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
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
    final store = context.read<InventoryStore>();

    final result = await showDialog<_MaterialDraft>(
      context: context,
      builder: (context) {
        return _MaterialDialog(
          title: 'Add Material',
          categories: store.categories,
          initial: _MaterialDraft(
            name: '',
            brand: '',
            unit: 'pcs',
            price: 0,
            categoryId: store.selectedCategoryId,
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
    final store = context.read<InventoryStore>();

    final result = await showDialog<_MaterialDraft>(
      context: context,
      builder: (context) {
        return _MaterialDialog(
          title: 'Edit Material',
          categories: store.categories,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: _ClayPanel(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            radius: 16.0,
            child: Row(
              children: [
                Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ClayPanel(
        isClay: selected,
        borderless: selected,
        background: Colors.white,
        radius: 16.0,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? const Color(0xFF0369A1) : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFBAE6FD) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          trailing: trailing,
          selectedColor: scheme.primary,
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
        int columns = 1;
        if (constraints.maxWidth > 900) {
          columns = 4;
        } else if (constraints.maxWidth > 650) {
          columns = 3;
        } else if (constraints.maxWidth > 400) {
          columns = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 170, // fixed height for elegant cards
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
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _hovering ? -4.0 : 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _hovering ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
          width: _hovering ? 2 : 1,
        ),
        boxShadow: _hovering
            ? const [
                BoxShadow(color: Color(0x1A0F172A), blurRadius: 12, offset: Offset(0, 4)),
                BoxShadow(color: Color(0x0F0F172A), blurRadius: 32, offset: Offset(0, 8)),
              ]
            : const [
                BoxShadow(color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 4)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          hoverColor: const Color(0xFFF0F9FF),
          highlightColor: const Color(0xFFE0F2FE),
          splashColor: const Color(0xFFBAE6FD).withOpacity(0.4),
          onTap: widget.onEdit,
          onHover: (val) => setState(() => _hovering = val),
          child: Padding(
            padding: EdgeInsets.all(_hovering ? 19 : 20),
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
                          fontSize: 18,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
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
                    Text(widget.currency.format(widget.m.price), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0284C7),
                      fontSize: 22,
                    )),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
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
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isClay ? null : (background ?? Colors.white),
        gradient: isClay
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF9FF), Color(0xFFBAE6FD)],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: borderless ? null : (isClay ? null : Border.all(color: const Color(0xFFE2E8F0))),
        boxShadow: isClay
            ? const [
                BoxShadow(color: Color(0xFF93C5FD), offset: Offset(0, 6)),
              ]
            : const [
                BoxShadow(color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 4)),
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
      title: Text(widget.title),
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
