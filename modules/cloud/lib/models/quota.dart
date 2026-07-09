
class StorageQuota {
  final int quotaBytes;
  final int usedBytes;

  StorageQuota({required this.quotaBytes, required this.usedBytes});

  factory StorageQuota.fromJson(Map<String, dynamic> json) => StorageQuota(
        quotaBytes: json['quota_bytes'] ?? 0,
        usedBytes: json['used_bytes'] ?? 0,
      );
}
