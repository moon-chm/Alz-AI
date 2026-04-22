import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SyncItem {
  final String endpoint;
  final String method;
  final Map<String, dynamic>? body;
  final String timestamp;

  SyncItem({
    required this.endpoint,
    required this.method,
    this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'method': method,
    'body': body,
    'timestamp': timestamp,
  };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
    endpoint: json['endpoint'],
    method: json['method'],
    body: json['body'],
    timestamp: json['timestamp'],
  );
}

class SyncQueue {
  static const String _key = 'sync_queue';
  final SharedPreferences _prefs;

  SyncQueue(this._prefs);

  Future<void> addItem(SyncItem item) async {
    final list = _getItems();
    list.add(item);
    await _saveItems(list);
  }

  List<SyncItem> _getItems() {
    final strings = _prefs.getStringList(_key) ?? [];
    return strings.map((s) => SyncItem.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _saveItems(List<SyncItem> items) async {
    final strings = items.map((i) => jsonEncode(i.toJson())).toList();
    await _prefs.setStringList(_key, strings);
  }

  Future<List<SyncItem>> getQueue() async {
    return _getItems();
  }

  Future<void> removeItem(String timestamp) async {
    final list = _getItems();
    list.removeWhere((i) => i.timestamp == timestamp);
    await _saveItems(list);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}
