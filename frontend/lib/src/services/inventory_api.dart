import 'dart:convert';

import '../models/category.dart';
import '../models/material_item.dart';
import 'api_client.dart';

class InventoryApi {
  final ApiClient client;

  const InventoryApi(this.client);

  Never _fail(int status, String body) {
    throw Exception('HTTP $status: $body');
  }

  Future<List<Category>> listCategories({required String companyId, bool? isActive}) async {
    final q = <String, String>{'companyId': companyId};
    if (isActive != null) q['isActive'] = isActive ? 'true' : 'false';

    final res = await client.get('/api/categories', query: q);
    if (res.statusCode != 200) _fail(res.statusCode, res.body);

    final list = (jsonDecode(res.body) as List).cast<dynamic>();
    return list.map((e) => Category.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<Category> createCategory({required String companyId, required String name}) async {
    final res = await client.post('/api/categories', body: {
      'companyId': companyId,
      'name': name,
      'isActive': true,
    });

    if (res.statusCode != 201) _fail(res.statusCode, res.body);
    return Category.fromJson((jsonDecode(res.body) as Map).cast<String, dynamic>());
  }

  Future<void> deleteCategory({required String id, required String companyId, bool hard = false}) async {
    final res = await client.delete('/api/categories/$id', query: {
      'companyId': companyId,
      if (hard) 'hard': 'true',
    });

    if (res.statusCode != 204) _fail(res.statusCode, res.body);
  }

  Future<List<MaterialItem>> listMaterials({
    required String companyId,
    String? categoryId,
    bool? isActive,
  }) async {
    final q = <String, String>{'companyId': companyId};
    if (categoryId != null && categoryId.isNotEmpty) q['categoryId'] = categoryId;
    if (isActive != null) q['isActive'] = isActive ? 'true' : 'false';

    final res = await client.get('/api/materials', query: q);
    if (res.statusCode != 200) _fail(res.statusCode, res.body);

    final list = (jsonDecode(res.body) as List).cast<dynamic>();
    return list.map((e) => MaterialItem.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<MaterialItem> createMaterial({
    required String companyId,
    required String name,
    required String unit,
    String brand = '',
    double price = 0,
    String? categoryId,
  }) async {
    final res = await client.post('/api/materials', body: {
      'companyId': companyId,
      'name': name,
      'brand': brand,
      'price': price,
      'unit': unit,
      'categoryId': categoryId,
      'isActive': true,
    });

    if (res.statusCode != 201) _fail(res.statusCode, res.body);
    return MaterialItem.fromJson((jsonDecode(res.body) as Map).cast<String, dynamic>());
  }

  Future<MaterialItem> updateMaterial({
    required String id,
    required String companyId,
    String? name,
    String? brand,
    double? price,
    String? unit,
    String? categoryId,
    bool? isActive,
  }) async {
    final res = await client.put('/api/materials/$id', body: {
      'companyId': companyId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (unit != null) 'unit': unit,
      if (categoryId != null) 'categoryId': categoryId,
      if (isActive != null) 'isActive': isActive,
    });

    if (res.statusCode != 200) _fail(res.statusCode, res.body);
    return MaterialItem.fromJson((jsonDecode(res.body) as Map).cast<String, dynamic>());
  }

  Future<void> deleteMaterial({required String id, required String companyId, bool hard = false}) async {
    final res = await client.delete('/api/materials/$id', query: {
      'companyId': companyId,
      if (hard) 'hard': 'true',
    });

    if (res.statusCode != 204) _fail(res.statusCode, res.body);
  }
}
