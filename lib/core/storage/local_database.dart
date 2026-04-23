import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'xillafit_local.db');
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE catalog_categories (
            id TEXT PRIMARY KEY,
            category_name TEXT NOT NULL,
            description TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE catalog_items (
            id TEXT PRIMARY KEY,
            category_id TEXT NOT NULL,
            clothing_name TEXT NOT NULL,
            description TEXT,
            preview_image_url TEXT,
            model_file_url TEXT,
            availability_status TEXT,
            created_at TEXT,
            price REAL,
            avg_rating REAL,
            review_count INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE cart_items (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            server_cart_id TEXT,
            product_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            product_image TEXT,
            product_price REAL,
            product_category TEXT,
            quantity INTEGER NOT NULL,
            size TEXT,
            fabric TEXT,
            custom_name TEXT,
            custom_number TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE order_summaries (
            user_id TEXT NOT NULL,
            order_id TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            payload_json TEXT NOT NULL,
            synced_at TEXT,
            PRIMARY KEY (user_id, order_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE order_details (
            user_id TEXT NOT NULL,
            order_id TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            synced_at TEXT,
            PRIMARY KEY (user_id, order_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE notification_items (
            user_id TEXT NOT NULL,
            notification_id TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            message TEXT NOT NULL,
            notification_type TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0,
            order_id TEXT,
            created_at TEXT,
            synced_at TEXT,
            PRIMARY KEY (user_id, notification_id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE order_summaries (
              user_id TEXT NOT NULL,
              order_id TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              payload_json TEXT NOT NULL,
              synced_at TEXT,
              PRIMARY KEY (user_id, order_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE order_details (
              user_id TEXT NOT NULL,
              order_id TEXT NOT NULL,
              payload_json TEXT NOT NULL,
              synced_at TEXT,
            PRIMARY KEY (user_id, order_id)
          )
        ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE notification_items (
              user_id TEXT NOT NULL,
              notification_id TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              message TEXT NOT NULL,
              notification_type TEXT NOT NULL,
              is_read INTEGER NOT NULL DEFAULT 0,
              order_id TEXT,
              created_at TEXT,
              synced_at TEXT,
              PRIMARY KEY (user_id, notification_id)
            )
          ''');
        }
      },
    );

    _database = db;
    return db;
  }

  Future<void> replaceCatalogCategories(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('catalog_categories');
      for (final row in rows) {
        await txn.insert('catalog_categories', _normalizeCategoryRow(row));
      }
    });
  }

  Future<void> replaceCatalogItems(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('catalog_items');
      for (final row in rows) {
        await txn.insert('catalog_items', _normalizeItemRow(row));
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadCatalogCategories() async {
    final db = await database;
    final rows = await db.query('catalog_categories', orderBy: 'category_name ASC');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> loadCatalogItems() async {
    final db = await database;
    final rows = await db.query('catalog_items', orderBy: 'created_at DESC');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<Map<String, dynamic>?> loadCatalogItemById(String id) async {
    final db = await database;
    final rows = await db.query(
      'catalog_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> replaceCartItems(
    String userId,
    List<Map<String, dynamic>> rows, {
    bool dirty = false,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      for (final row in rows) {
        await txn.insert('cart_items', {
          ...row,
          'user_id': userId,
        });
      }
      await _setMeta(txn, _cartDirtyKey(userId), dirty ? '1' : '0');
    });
  }

  Future<List<Map<String, dynamic>>> loadCartItems(String userId) async {
    final db = await database;
    final rows = await db.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'local_id ASC',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<void> upsertCartItem(
    String userId,
    Map<String, dynamic> row, {
    String? existingLocalId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      if ((existingLocalId ?? '').startsWith('local:')) {
        await txn.update(
          'cart_items',
          {
            ...row,
            'user_id': userId,
          },
          where: 'local_id = ? AND user_id = ?',
          whereArgs: [int.tryParse(existingLocalId!.substring(6)), userId],
        );
      } else if ((row['server_cart_id']?.toString() ?? '').isNotEmpty) {
        final updated = await txn.update(
          'cart_items',
          {
            ...row,
            'user_id': userId,
          },
          where: 'server_cart_id = ? AND user_id = ?',
          whereArgs: [row['server_cart_id'], userId],
        );
        if (updated == 0) {
          await txn.insert('cart_items', {
            ...row,
            'user_id': userId,
          });
        }
      } else {
        await txn.insert('cart_items', {
          ...row,
          'user_id': userId,
        });
      }

      await _setMeta(txn, _cartDirtyKey(userId), '1');
    });
  }

  Future<void> deleteCartItem(String userId, String cartId) async {
    final db = await database;
    await db.transaction((txn) async {
      if (cartId.startsWith('local:')) {
        final localId = int.tryParse(cartId.substring(6));
        await txn.delete(
          'cart_items',
          where: 'local_id = ? AND user_id = ?',
          whereArgs: [localId, userId],
        );
      } else {
        await txn.delete(
          'cart_items',
          where: 'server_cart_id = ? AND user_id = ?',
          whereArgs: [cartId, userId],
        );
      }
      await _setMeta(txn, _cartDirtyKey(userId), '1');
    });
  }

  Future<void> clearCart(String userId, {bool dirty = true}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      await _setMeta(txn, _cartDirtyKey(userId), dirty ? '1' : '0');
    });
  }

  Future<bool> isCartDirty(String userId) async {
    final db = await database;
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_cartDirtyKey(userId)],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['value']?.toString() == '1';
  }

  Future<void> replaceOrderSummaries(
    String userId,
    List<Map<String, dynamic>> rows, {
    String? syncedAt,
  }) async {
    final db = await database;
    final timestamp = syncedAt ?? DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('order_summaries', where: 'user_id = ?', whereArgs: [userId]);
      for (var i = 0; i < rows.length; i++) {
        await txn.insert('order_summaries', {
          'user_id': userId,
          'order_id': rows[i]['id']?.toString() ?? '',
          'sort_order': i,
          'payload_json': rows[i]['payload_json']?.toString() ?? '',
          'synced_at': timestamp,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadOrderSummaries(String userId) async {
    final db = await database;
    final rows = await db.query(
      'order_summaries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sort_order ASC',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<void> saveOrderDetail(
    String userId,
    String orderId,
    String payloadJson, {
    String? syncedAt,
  }) async {
    final db = await database;
    await db.insert(
      'order_details',
      {
        'user_id': userId,
        'order_id': orderId,
        'payload_json': payloadJson,
        'synced_at': syncedAt ?? DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadOrderDetail(String userId, String orderId) async {
    final db = await database;
    final rows = await db.query(
      'order_details',
      where: 'user_id = ? AND order_id = ?',
      whereArgs: [userId, orderId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> replaceNotificationItems(
    String userId,
    List<Map<String, dynamic>> rows, {
    String? syncedAt,
  }) async {
    final db = await database;
    final timestamp = syncedAt ?? DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('notification_items', where: 'user_id = ?', whereArgs: [userId]);
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        await txn.insert('notification_items', {
          'user_id': userId,
          'notification_id': row['id']?.toString() ?? '',
          'sort_order': i,
          'message': row['message']?.toString() ?? '',
          'notification_type': row['notification_type']?.toString() ?? 'general',
          'is_read': row['is_read'] == true ? 1 : 0,
          'order_id': row['order_id']?.toString(),
          'created_at': row['created_at']?.toString(),
          'synced_at': timestamp,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadNotificationItems(String userId) async {
    final db = await database;
    final rows = await db.query(
      'notification_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sort_order ASC',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<void> markNotificationRead(String userId, String notificationId) async {
    final db = await database;
    await db.update(
      'notification_items',
      {'is_read': 1},
      where: 'user_id = ? AND notification_id = ?',
      whereArgs: [userId, notificationId],
    );
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final db = await database;
    await db.update(
      'notification_items',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
  }

  String _cartDirtyKey(String userId) => 'cart_dirty:$userId';

  Future<void> _setMeta(Transaction txn, String key, String value) async {
    await txn.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> _normalizeCategoryRow(Map<String, dynamic> row) {
    return {
      'id': row['id']?.toString() ?? '',
      'category_name': row['category_name']?.toString() ?? '',
      'description': row['description']?.toString(),
      'created_at': row['created_at']?.toString(),
    };
  }

  Map<String, dynamic> _normalizeItemRow(Map<String, dynamic> row) {
    final rawPrice = row['price'] ?? row['base_price'];
    final rawReviewCount = row['review_count'];

    return {
      'id': row['id']?.toString() ?? '',
      'category_id': row['category_id']?.toString() ?? '',
      'clothing_name': row['clothing_name']?.toString() ?? '',
      'description': row['description']?.toString(),
      'preview_image_url': row['preview_image_url']?.toString(),
      'model_file_url': row['model_file_url']?.toString(),
      'availability_status': row['availability_status']?.toString(),
      'created_at': row['created_at']?.toString(),
      'price': rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice'),
      'avg_rating': row['avg_rating'] is num
          ? (row['avg_rating'] as num).toDouble()
          : double.tryParse('${row['avg_rating']}'),
      'review_count': rawReviewCount is num
          ? rawReviewCount.toInt()
          : int.tryParse('$rawReviewCount') ?? 0,
    };
  }
}
