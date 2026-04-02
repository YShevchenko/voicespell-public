import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

/// Database helper for Voice Spell
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
    final path = join(dbPath, 'spellbook.db');

    return await openDatabase(
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
        incantation TEXT NOT NULL,
        action_type TEXT NOT NULL,
        action_params TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        is_premium INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cast_history (
        id TEXT PRIMARY KEY,
        spell_id TEXT,
        success INTEGER NOT NULL,
        timestamp TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('CREATE INDEX idx_spells_active ON spells(is_active)');
    await db.execute('CREATE INDEX idx_cast_history_timestamp ON cast_history(timestamp)');

    // Insert starter spells
    await _insertStarterSpells(db);

    // Set initial premium status to false
    await db.insert('user_settings', {'key': 'premium_unlocked', 'value': '0'});
  }

  Future<void> _insertStarterSpells(Database db) async {
    final spells = [
      // FREE SPELLS (5)
      {'name': 'Toggle Flashlight', 'incantation': 'Illumina', 'action_type': 'FLASHLIGHT_TOGGLE', 'is_premium': 0, 'sort_order': 0},
      {'name': 'Enable Dark Mode', 'incantation': 'Obscura', 'action_type': 'DARK_MODE', 'is_premium': 0, 'sort_order': 1},
      {'name': 'Start 5-Minute Timer', 'incantation': 'Tempus', 'action_type': 'TIMER_START', 'action_params': '{"duration": 300}', 'is_premium': 0, 'sort_order': 2},
      {'name': 'Open Camera', 'incantation': 'Captura', 'action_type': 'OPEN_APP', 'action_params': '{"app": "camera"}', 'is_premium': 0, 'sort_order': 3},
      {'name': 'Play Music', 'incantation': 'Melodia', 'action_type': 'OPEN_APP', 'action_params': '{"app": "music"}', 'is_premium': 0, 'sort_order': 4},

      // PREMIUM SPELLS (20)
      {'name': 'Start 10-Minute Timer', 'incantation': 'Tempus Decem', 'action_type': 'TIMER_START', 'action_params': '{"duration": 600}', 'is_premium': 1, 'sort_order': 5},
      {'name': 'Start 15-Minute Timer', 'incantation': 'Tempus Quindecim', 'action_type': 'TIMER_START', 'action_params': '{"duration": 900}', 'is_premium': 1, 'sort_order': 6},
      {'name': 'Start 30-Minute Timer', 'incantation': 'Tempus Triginta', 'action_type': 'TIMER_START', 'action_params': '{"duration": 1800}', 'is_premium': 1, 'sort_order': 7},
      {'name': 'Start 1-Hour Timer', 'incantation': 'Tempus Hora', 'action_type': 'TIMER_START', 'action_params': '{"duration": 3600}', 'is_premium': 1, 'sort_order': 8},
      {'name': 'Open Messages', 'incantation': 'Epistola', 'action_type': 'OPEN_APP', 'action_params': '{"app": "messages"}', 'is_premium': 1, 'sort_order': 9},
      {'name': 'Open Maps', 'incantation': 'Navigatio', 'action_type': 'OPEN_APP', 'action_params': '{"app": "maps"}', 'is_premium': 1, 'sort_order': 10},
      {'name': 'Open Phone', 'incantation': 'Voca', 'action_type': 'OPEN_APP', 'action_params': '{"app": "phone"}', 'is_premium': 1, 'sort_order': 11},
      {'name': 'Open Calendar', 'incantation': 'Kalendar', 'action_type': 'OPEN_APP', 'action_params': '{"app": "calendar"}', 'is_premium': 1, 'sort_order': 12},
      {'name': 'Open Notes', 'incantation': 'Scriptum', 'action_type': 'OPEN_APP', 'action_params': '{"app": "notes"}', 'is_premium': 1, 'sort_order': 13},
      {'name': 'Open Safari', 'incantation': 'Explorata', 'action_type': 'OPEN_APP', 'action_params': '{"app": "browser"}', 'is_premium': 1, 'sort_order': 14},
      {'name': 'Open Settings', 'incantation': 'Configurata', 'action_type': 'OPEN_APP', 'action_params': '{"app": "settings"}', 'is_premium': 1, 'sort_order': 15},
      {'name': 'Open Photos', 'incantation': 'Imagines', 'action_type': 'OPEN_APP', 'action_params': '{"app": "photos"}', 'is_premium': 1, 'sort_order': 16},
      {'name': 'Open Clock', 'incantation': 'Horologium', 'action_type': 'OPEN_APP', 'action_params': '{"app": "clock"}', 'is_premium': 1, 'sort_order': 17},
      {'name': 'Open Weather', 'incantation': 'Tempestas', 'action_type': 'OPEN_APP', 'action_params': '{"app": "weather"}', 'is_premium': 1, 'sort_order': 18},
      {'name': 'Open Contacts', 'incantation': 'Amici', 'action_type': 'OPEN_APP', 'action_params': '{"app": "contacts"}', 'is_premium': 1, 'sort_order': 19},
      {'name': 'Open Wallet', 'incantation': 'Pecunia', 'action_type': 'OPEN_APP', 'action_params': '{"app": "wallet"}', 'is_premium': 1, 'sort_order': 20},
      {'name': 'Open Files', 'incantation': 'Documenta', 'action_type': 'OPEN_APP', 'action_params': '{"app": "files"}', 'is_premium': 1, 'sort_order': 21},
      {'name': 'Open Mail', 'incantation': 'Littera', 'action_type': 'OPEN_APP', 'action_params': '{"app": "mail"}', 'is_premium': 1, 'sort_order': 22},
      {'name': 'Maximum Brightness', 'incantation': 'Lux Maxima', 'action_type': 'BRIGHTNESS_MAX', 'is_premium': 1, 'sort_order': 23},
      {'name': 'Minimum Brightness', 'incantation': 'Lux Minima', 'action_type': 'BRIGHTNESS_MIN', 'is_premium': 1, 'sort_order': 24},
    ];

    for (int i = 0; i < spells.length; i++) {
      await db.insert('spells', {
        'id': _uuid.v4(),
        'name': spells[i]['name'],
        'incantation': spells[i]['incantation'],
        'action_type': spells[i]['action_type'],
        'action_params': spells[i]['action_params'],
        'is_custom': 0,
        'is_premium': spells[i]['is_premium'],
        'is_active': 1,
        'sort_order': spells[i]['sort_order'],
      });
    }
  }
}
