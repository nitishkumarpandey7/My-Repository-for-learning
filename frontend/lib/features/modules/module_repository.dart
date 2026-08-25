import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/life_module.dart';
import '../../core/storage/local_store.dart';
import '../../core/sync/sync_queue.dart';

final moduleRepositoryProvider = Provider<ModuleRepository>((ref) {
  return ModuleRepository(ref.watch(syncQueueProvider));
});

class ModuleRepository {
  ModuleRepository(this._syncQueue);

  final SyncQueue _syncQueue;
  final _uuid = const Uuid();

  String collectionFor(LifeModule module) => module.route.split('/').last;

  String endpointFor(LifeModule module) {
    switch (module.title) {
      case 'Habits':
        return '/habits';
      case 'Recovery':
        return '/bad-habits';
      case 'Finance':
        return '/expenses';
      case 'Study':
        return '/study/subjects';
      case 'Tasks':
        return '/tasks';
      case 'Fitness':
        return '/exercise-routines';
      case 'Games':
        return '/challenges';
      case 'Analytics':
        return '/analytics/logs';
      default:
        return '/tasks';
    }
  }

  Future<List<Map<String, dynamic>>> list(LifeModule module) async {
    final rows = await LocalStore.database.query(
      'local_entities',
      where: 'collection = ?',
      whereArgs: [collectionFor(module)],
      orderBy: 'updated_at DESC',
    );
    return rows.map((row) {
      final payload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return {
        'id': row['id'],
        'syncState': row['sync_state'],
        ...payload,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> create({
    required LifeModule module,
    required String title,
    required String notes,
    required double amount,
  }) async {
    final now = DateTime.now();
    final item = _payloadFor(module,
        title: title, notes: notes, amount: amount, now: now);
    final localId = _uuid.v4();
    final localPayload = {
      ...item,
      'title': title,
      'notes': notes,
      'amount': amount,
      'completed': false,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    await LocalStore.database.insert('local_entities', {
      'id': localId,
      'collection': collectionFor(module),
      'payload': jsonEncode(localPayload),
      'updated_at': now.toIso8601String(),
      'sync_state': 'queued',
    });
    await _syncQueue.enqueue(
      endpointFor(module),
      item,
      localId: localId,
      collection: collectionFor(module),
    );
    unawaited(_syncQueue.flush());
    return {'id': localId, 'syncState': 'queued', ...localPayload};
  }

  Future<void> createMany(
    LifeModule module,
    List<({String title, String notes, double amount})> items,
  ) async {
    for (final item in items) {
      await create(
        module: module,
        title: item.title,
        notes: item.notes,
        amount: item.amount,
      );
    }
  }

  Future<List<Map<String, dynamic>>> listReminders(LifeModule module) async {
    final rows = await LocalStore.database.query(
      'local_entities',
      where: 'collection = ?',
      whereArgs: ['reminders:${collectionFor(module)}'],
      orderBy: 'updated_at DESC',
    );
    return rows.map((row) {
      final payload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return {
        'id': row['id'],
        'syncState': row['sync_state'],
        ...payload,
      };
    }).toList();
  }

  Future<void> createReminder({
    required LifeModule module,
    required String title,
    required DateTime remindAt,
  }) async {
    final now = DateTime.now();
    final collection = 'reminders:${collectionFor(module)}';
    final localId = _uuid.v4();
    final payload = {
      'title': title,
      'body': '${module.title} reminder',
      'remind_at': remindAt.toIso8601String(),
      'channel': 'push',
      'status': 'scheduled',
      'linked_type': module.title.toLowerCase(),
      'linked_id': null,
    };
    final localPayload = {
      ...payload,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    await LocalStore.database.insert('local_entities', {
      'id': localId,
      'collection': collection,
      'payload': jsonEncode(localPayload),
      'updated_at': now.toIso8601String(),
      'sync_state': 'queued',
    });
    await _syncQueue.enqueue(
      '/reminders',
      payload,
      localId: localId,
      collection: collection,
    );
    unawaited(_syncQueue.flush());
  }

  Future<void> toggleComplete(
      LifeModule module, Map<String, dynamic> item) async {
    final updated = {
      ...item,
      'completed': !(item['completed'] == true),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    updated.remove('id');
    updated.remove('syncState');
    await LocalStore.database.update(
      'local_entities',
      {
        'payload': jsonEncode(updated),
        'updated_at': updated['updatedAt'] as String,
        'sync_state': 'queued',
      },
      where: 'id = ? AND collection = ?',
      whereArgs: [item['id'], collectionFor(module)],
    );
  }

  Future<void> delete(LifeModule module, String id) async {
    await LocalStore.database.delete(
      'local_entities',
      where: 'id = ? AND collection = ?',
      whereArgs: [id, collectionFor(module)],
    );
  }

  Future<int> pendingSyncCount() async => _syncQueue.pendingCount;

  Future<({int total, int completed, int queued, int failed})> stats(
    LifeModule module,
  ) async {
    final items = await list(module);
    return (
      total: items.length,
      completed: items.where((item) => item['completed'] == true).length,
      queued: items.where((item) => item['syncState'] == 'queued').length,
      failed: items.where((item) => item['syncState'] == 'failed').length,
    );
  }

  Map<String, dynamic> _payloadFor(
    LifeModule module, {
    required String title,
    required String notes,
    required double amount,
    required DateTime now,
  }) {
    switch (module.title) {
      case 'Habits':
        return {
          'title': title,
          'description': notes,
          'category': 'custom',
          'difficulty': 'medium',
          'target_value': amount <= 0 ? 1 : amount,
          'unit': 'times',
          'frequency': 'daily',
          'is_active': true,
        };
      case 'Recovery':
        return {
          'title': title,
          'description': notes,
          'severity': 'medium',
          'replacement_habit': 'Pause, breathe, and do a 2-minute reset',
          'is_active': true,
        };
      case 'Finance':
        return {
          'category': title,
          'amount': amount <= 0 ? 1 : amount,
          'currency': 'INR',
          'spent_at': now.toIso8601String(),
          'notes': notes,
          'is_recurring': false,
        };
      case 'Study':
        return {
          'name': title,
          'program': 'Custom',
          'semester': 'Custom',
          'target_hours': amount <= 0 ? 1 : amount,
          'notes': notes,
        };
      case 'Fitness':
        return {
          'title': title,
          'description': notes,
          'difficulty': 'medium',
          'estimated_minutes': amount <= 0 ? 30 : amount.round(),
          'calories_estimate': 0,
        };
      case 'Games':
        return {
          'title': title,
          'description': notes,
          'domain': 'life',
          'difficulty': 'medium',
          'starts_at': now.toIso8601String(),
          'ends_at': now.add(const Duration(days: 1)).toIso8601String(),
          'xp_reward': amount <= 0 ? 100 : amount.round(),
          'coin_reward': 25,
          'status': 'active',
        };
      case 'Analytics':
        return {
          'metric_key': title.toLowerCase().replaceAll(' ', '_'),
          'metric_value': amount <= 0 ? 1 : amount,
          'metric_date': now.toIso8601String().substring(0, 10),
          'domain': 'life',
          'metadata': {'notes': notes},
        };
      default:
        return {
          'title': title,
          'description': notes,
          'priority': 'medium',
          'status': 'todo',
          'category': module.title.toLowerCase(),
        };
    }
  }
}
