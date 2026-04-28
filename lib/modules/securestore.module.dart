import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static Future<String?> get(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> set(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<T?> getJSON<T>(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return jsonDecode(value) as T;
  }

  static Future<void> setJSON<T>(String key, T value) async {
    await set(key, jsonEncode(value));
  }
}