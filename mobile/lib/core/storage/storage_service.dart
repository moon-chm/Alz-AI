import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_service.g.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService(this._storage);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'role';
  static const String _patientIdKey = 'patient_id';
  static const String _languageKey = 'language';
  static const String _levelKey = 'level';
  static const String _fullNameKey = 'full_name';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveAuthData({
    required String userId,
    required String role,
    String? patientId,
    String? language,
    int? level,
    String? fullName,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _roleKey, value: role);
    if (patientId != null) await _storage.write(key: _patientIdKey, value: patientId);
    if (language != null) await _storage.write(key: _languageKey, value: language);
    if (level != null) await _storage.write(key: _levelKey, value: level.toString());
    if (fullName != null) await _storage.write(key: _fullNameKey, value: fullName);
  }

  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<String?> getRole() => _storage.read(key: _roleKey);
  Future<String?> getPatientId() => _storage.read(key: _patientIdKey);
  Future<String?> getLanguage() => _storage.read(key: _languageKey);
  Future<String?> getFullName() => _storage.read(key: _fullNameKey);
  Future<int?> getLevel() async {
    final levelStr = await _storage.read(key: _levelKey);
    return levelStr != null ? int.tryParse(levelStr) : null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

@riverpod
StorageService storageService(Ref ref) {
  return StorageService(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ));
}
