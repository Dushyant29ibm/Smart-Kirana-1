class AppSettings {
  const AppSettings({
    required this.storeName,
    required this.defaultLowStockThreshold,
  });

  final String storeName;
  final double defaultLowStockThreshold;

  Map<String, dynamic> toMap() => {
        'storeName': storeName,
        'defaultLowStockThreshold': defaultLowStockThreshold,
      };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) => AppSettings(
        storeName: map['storeName'] as String? ?? 'KiranaSmart Store',
        defaultLowStockThreshold:
            (map['defaultLowStockThreshold'] as num?)?.toDouble() ?? 5,
      );
}
