import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalStore {
  static Database? _db;

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('settings'),
      Hive.openBox('dashboard_cache'),
      Hive.openBox('sync_queue'),
      Hive.openBox('ai_cache'),
    ]);
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'lifeos_x.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_entities (
            id TEXT PRIMARY KEY,
            collection TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_state TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Box get settings => Hive.box('settings');
  static Box get dashboardCache => Hive.box('dashboard_cache');
  static Box get syncQueue => Hive.box('sync_queue');
  static Box get aiCache => Hive.box('ai_cache');
  static Database get database => _db!;
}

