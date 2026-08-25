class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.path,
    required this.method,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String path;
  final String method;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'method': method,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };
}

