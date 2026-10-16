import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/department_model.dart';
import '../models/pos_product_model.dart';

/// SQLite cache for cashier departments + branch catalog (products & services).
class CatalogLocalDatabase {
  CatalogLocalDatabase._();
  static final CatalogLocalDatabase instance = CatalogLocalDatabase._();

  static const _dbName = 'pos_catalog.db';
  static const _dbVersion = 1;
  static const _kindDepartments = 'departments';
  static const _kindProducts = 'products';

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      p.join(base, _dbName),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE catalog_cache (
            scope_key TEXT PRIMARY KEY,
            workshop_id TEXT NOT NULL,
            branch_id TEXT NOT NULL,
            kind TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_catalog_workshop ON catalog_cache(workshop_id, branch_id, kind)',
        );
      },
    );
    return _db!;
  }

  String _scopeKey({
    required String workshopId,
    required String branchId,
    required String kind,
  }) =>
      '${workshopId.trim()}|${branchId.trim()}|$kind';

  Future<void> saveDepartments({
    required String workshopId,
    required String branchId,
    required List<Department> departments,
  }) async {
    final db = await _database();
    await db.insert(
      'catalog_cache',
      {
        'scope_key': _scopeKey(
          workshopId: workshopId,
          branchId: branchId,
          kind: _kindDepartments,
        ),
        'workshop_id': workshopId,
        'branch_id': branchId,
        'kind': _kindDepartments,
        'payload': jsonEncode(departments.map((d) => d.toJson()).toList()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Department>> loadDepartments({
    required String workshopId,
    required String branchId,
  }) async {
    final db = await _database();
    final rows = await db.query(
      'catalog_cache',
      where: 'scope_key = ?',
      whereArgs: [
        _scopeKey(
          workshopId: workshopId,
          branchId: branchId,
          kind: _kindDepartments,
        ),
      ],
      limit: 1,
    );
    if (rows.isEmpty) return const [];
    final raw = rows.first['payload'] as String?;
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Department.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveProductsCatalog({
    required String workshopId,
    required String branchId,
    required ProductsResponse response,
  }) async {
    final db = await _database();
    await db.insert(
      'catalog_cache',
      {
        'scope_key': _scopeKey(
          workshopId: workshopId,
          branchId: branchId,
          kind: _kindProducts,
        ),
        'workshop_id': workshopId,
        'branch_id': branchId,
        'kind': _kindProducts,
        'payload': jsonEncode(response.toCatalogCacheJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProductsResponse?> loadProductsCatalog({
    required String workshopId,
    required String branchId,
  }) async {
    final db = await _database();
    final rows = await db.query(
      'catalog_cache',
      where: 'scope_key = ?',
      whereArgs: [
        _scopeKey(
          workshopId: workshopId,
          branchId: branchId,
          kind: _kindProducts,
        ),
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['payload'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return ProductsResponse.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<DateTime?> lastProductsSyncAt({
    required String workshopId,
    required String branchId,
  }) async {
    final db = await _database();
    final rows = await db.query(
      'catalog_cache',
      columns: ['updated_at'],
      where: 'scope_key = ?',
      whereArgs: [
        _scopeKey(
          workshopId: workshopId,
          branchId: branchId,
          kind: _kindProducts,
        ),
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['updated_at'] as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clearForWorkshop({
    required String workshopId,
    String branchId = '',
  }) async {
    final db = await _database();
    await db.delete(
      'catalog_cache',
      where: 'workshop_id = ? AND branch_id = ?',
      whereArgs: [workshopId, branchId],
    );
  }

  Future<void> clearAll() async {
    final db = await _database();
    await db.delete('catalog_cache');
  }
}

/// Flattened catalog for [PosViewModel].
class LocalCatalogSnapshot {
  final List<PosProduct> products;
  final List<ProductCategory> categories;

  const LocalCatalogSnapshot({
    required this.products,
    required this.categories,
  });

  static LocalCatalogSnapshot fromResponse(
    ProductsResponse response, {
    String? departmentId,
  }) {
    final products = <PosProduct>[];
    for (final cat in response.categories) {
      for (final sub in cat.subCategories) {
        for (final p in sub.products) {
          if ((p.categoryId == null || p.categoryId!.trim().isEmpty)) {
            p.categoryId = cat.id;
          }
          if ((p.categoryName == null || p.categoryName!.trim().isEmpty)) {
            p.categoryName = cat.name;
          }
          if ((p.subCategoryName == null || p.subCategoryName!.trim().isEmpty)) {
            p.subCategoryName = sub.name;
          }
        }
        products.addAll(sub.products);
      }
      for (final p in cat.productsWithoutSub) {
        if ((p.categoryId == null || p.categoryId!.trim().isEmpty)) {
          p.categoryId = cat.id;
        }
        if ((p.categoryName == null || p.categoryName!.trim().isEmpty)) {
          p.categoryName = cat.name;
        }
      }
      products.addAll(cat.productsWithoutSub);
    }
    products.addAll(response.uncategorizedProducts);

    final dept = departmentId?.trim();
    if (dept != null && dept.isNotEmpty) {
      final filtered = products
          .where((p) => (p.departmentId ?? '').trim() == dept)
          .toList();
      return LocalCatalogSnapshot(
        products: filtered,
        categories: response.categories,
      );
    }
    return LocalCatalogSnapshot(
      products: products,
      categories: response.categories,
    );
  }

  bool get isEmpty => products.isEmpty;
}
