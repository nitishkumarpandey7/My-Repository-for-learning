import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../network/api_client.dart';
import '../storage/local_store.dart';

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueue(ref.watch(apiClientProvider));
});

class SyncQueue {
  SyncQueue(this._api);

  final ApiClient _api;
  final _uuid = const Uuid();

  int get pendingCount => LocalStore.syncQueue.length;

  Future<void> enqueue(
    String path,
    Map<String, dynamic> payload, {
    String method = 'POST',
    String? localId,
    String? collection,
  }) async {
    final id = _uuid.v4();
    await LocalStore.syncQueue.put(id, {
      'id': id,
      'path': path,
      'method': method,
      'payload': payload,
      'localId': localId,
      'collection': collection,
      'createdAt': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  Future<SyncResult> flush() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return SyncResult(
        attempted: 0,
        synced: 0,
        failed: pendingCount,
        message: 'No internet connection',
      );
    }

    var attempted = 0;
    var synced = 0;
    var failed = 0;
    for (final key in LocalStore.syncQueue.keys.toList()) {
      final item = Map<String, dynamic>.from(LocalStore.syncQueue.get(key) as Map);
      attempted++;
      try {
        final path = item['path'] as String;
        final payload = Map<String, dynamic>.from(item['payload'] as Map);
        if (item['method'] == 'PATCH') {
          await _api.patchJson(path, payload);
        } else {
          await _api.postJson(path, payload);
        }
        final localId = item['localId'] as String?;
        final collection = item['collection'] as String?;
        if (localId != null && collection != null) {
          await LocalStore.database.update(
            'local_entities',
            {'sync_state': 'synced'},
            where: 'id = ? AND collection = ?',
            whereArgs: [localId, collection],
          );
        }
        await LocalStore.syncQueue.delete(key);
      } catch (_) {
        item['attempts'] = (item['attempts'] as int? ?? 0) + 1;
        await LocalStore.syncQueue.put(key, item);
        final localId = item['localId'] as String?;
        final collection = item['collection'] as String?;
        if (localId != null && collection != null) {
          await LocalStore.database.update(
            'local_entities',
            {'sync_state': 'failed'},
            where: 'id = ? AND collection = ?',
            whereArgs: [localId, collection],
          );
        }
        failed++;
        continue;
      }
      synced++;
    }
    return SyncResult(
      attempted: attempted,
      synced: synced,
      failed: failed,
      message: failed == 0 ? 'Synced $synced item(s)' : 'Synced $synced, failed $failed',
    );
  }
}

class SyncResult {
  const SyncResult({
    required this.attempted,
    required this.synced,
    required this.failed,
    required this.message,
  });

  final int attempted;
  final int synced;
  final int failed;
  final String message;
}
