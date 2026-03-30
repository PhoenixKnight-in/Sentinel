import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Offline-first queue.  Everything written here gets synced to
/// Firestore / IPFS when connectivity is restored.
class OfflineQueue {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  static Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'safeher_queue.db'),
      version: 1,
      onCreate: (db, _) async {
        // Incident table
        await db.execute('''
          CREATE TABLE incidents (
            id          TEXT PRIMARY KEY,
            type        TEXT NOT NULL,
            description TEXT,
            media_paths TEXT,          -- JSON array of local file paths
            lat         REAL,
            lng         REAL,
            created_at  TEXT NOT NULL,
            synced      INTEGER DEFAULT 0
          )
        ''');

        // Location breadcrumbs table
        await db.execute('''
          CREATE TABLE location_trail (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            lat         REAL NOT NULL,
            lng         REAL NOT NULL,
            accuracy    REAL,
            timestamp   TEXT NOT NULL,
            synced      INTEGER DEFAULT 0
          )
        ''');

        // Evidence files table
        await db.execute('''
          CREATE TABLE evidence (
            id          TEXT PRIMARY KEY,
            incident_id TEXT NOT NULL,
            local_path  TEXT NOT NULL,
            mime_type   TEXT,
            cid         TEXT,          -- IPFS CID after upload
            hash        TEXT,          -- SHA-256 for integrity
            synced      INTEGER DEFAULT 0,
            FOREIGN KEY (incident_id) REFERENCES incidents(id)
          )
        ''');
      },
    );
  }

  // ── Incidents ──────────────────────────────────────────────────
  static Future<void> enqueueIncident({
    required String id,
    required String type,
    String? description,
    List<String>? mediaPaths,
    double? lat,
    double? lng,
  }) async {
    final db = await _database;
    await db.insert(
      'incidents',
      {
        'id': id,
        'type': type,
        'description': description,
        'media_paths': mediaPaths?.join(','),
        'lat': lat,
        'lng': lng,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await _database;
    return db.query('incidents', where: 'synced = 0');
  }

  static Future<void> markSynced(String id) async {
    final db = await _database;
    await db.update(
      'incidents',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Location trail ─────────────────────────────────────────────
  static Future<void> appendLocation({
    required double lat,
    required double lng,
    double? accuracy,
  }) async {
    final db = await _database;
    await db.insert('location_trail', {
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    final db = await _database;
    return db.query('location_trail', where: 'synced = 0', limit: 200);
  }

  static Future<void> markLocationsSynced(List<int> ids) async {
    final db = await _database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.rawUpdate(
      'UPDATE location_trail SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  // ── Evidence ───────────────────────────────────────────────────
  static Future<void> enqueueEvidence({
    required String id,
    required String incidentId,
    required String localPath,
    String? mimeType,
    String? hash,
  }) async {
    final db = await _database;
    await db.insert('evidence', {
      'id': id,
      'incident_id': incidentId,
      'local_path': localPath,
      'mime_type': mimeType,
      'hash': hash,
      'synced': 0,
    });
  }

  static Future<void> updateEvidenceCid(String id, String cid) async {
    final db = await _database;
    await db.update(
      'evidence',
      {'cid': cid, 'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Stats ──────────────────────────────────────────────────────
  static Future<int> pendingCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM incidents WHERE synced = 0",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}