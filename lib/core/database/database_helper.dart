import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/spell.dart';

/// SQLite database helper for VoiceSpell.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static Database? _database;
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'voicespell.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spells (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        trigger_phrase TEXT NOT NULL,
        action_type TEXT NOT NULL,
        intent_url TEXT,
        is_default INTEGER NOT NULL DEFAULT 1,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        is_premium_required INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_spells_trigger ON spells(trigger_phrase)');

    // Seed starter spells
    await _insertStarterSpells(db);

    // Default: premium not unlocked
    await db.insert('user_settings',
        {'key': 'premium_unlocked', 'value': '0'});
  }

  Future<void> _insertStarterSpells(Database db) async {
    final starters = [
      {
        'name': 'Toggle Flashlight',
        'trigger_phrase': 'illumina',
        'action_type': SpellAction.toggleFlashlight.name,
        'is_premium_required': 0,
      },
      {
        'name': 'Adjust Brightness',
        'trigger_phrase': 'obscura',
        'action_type': SpellAction.adjustBrightness.name,
        'is_premium_required': 0,
      },
      {
        'name': 'Start 5-Minute Timer',
        'trigger_phrase': 'tempus',
        'action_type': SpellAction.setTimer.name,
        'is_premium_required': 0,
      },
      {
        'name': 'Mute / Unmute Volume',
        'trigger_phrase': 'silencio',
        'action_type': SpellAction.muteUnmute.name,
        'is_premium_required': 0,
      },
      {
        'name': 'Flash Reveal (3 sec)',
        'trigger_phrase': 'revelio',
        'action_type': SpellAction.revelio.name,
        'is_premium_required': 0,
      },
    ];

    for (final spell in starters) {
      await db.insert('spells', {
        'id': _uuid.v4(),
        'name': spell['name'],
        'trigger_phrase': spell['trigger_phrase'],
        'action_type': spell['action_type'],
        'intent_url': null,
        'is_default': 1,
        'is_enabled': 1,
        'is_premium_required': spell['is_premium_required'],
      });
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<List<Spell>> getAllSpells() async {
    final db = await database;
    final rows = await db.query('spells', orderBy: 'name ASC');
    return rows.map(Spell.fromMap).toList();
  }

  Future<Spell?> findByTrigger(String phrase) async {
    final db = await database;
    final rows = await db.query(
      'spells',
      where: 'LOWER(trigger_phrase) = ? AND is_enabled = 1',
      whereArgs: [phrase.toLowerCase().trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Spell.fromMap(rows.first);
  }

  Future<String> insertSpell(Spell spell) async {
    final db = await database;
    final id = _uuid.v4();
    await db.insert('spells', spell.copyWith(id: id).toMap());
    return id;
  }

  Future<void> updateSpell(Spell spell) async {
    final db = await database;
    await db.update(
      'spells',
      spell.toMap(),
      where: 'id = ?',
      whereArgs: [spell.id],
    );
  }

  Future<void> deleteSpell(String id) async {
    final db = await database;
    await db.delete('spells', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleSpellEnabled(String id, bool enabled) async {
    final db = await database;
    await db.update(
      'spells',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countCustomSpells() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM spells WHERE is_default = 0');
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetToStarterSpellbook() async {
    final db = await database;
    // Delete all custom spells
    await db.delete('spells', where: 'is_default = 0');
    // Re-enable all default spells
    await db.update('spells', {'is_enabled': 1},
        where: 'is_default = 1');
  }
}
