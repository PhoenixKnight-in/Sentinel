import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// AES-256-CBC vault.
/// Encryption key is derived from user PIN and stored in the OS keychain
/// (Keystore on Android, Secure Enclave on iOS).
class SecureVault {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyAlias = 'safeher_vault_key';
  static const _saltAlias = 'safeher_vault_salt';

  // ── Key management ─────────────────────────────────────────────

  /// Creates and stores a vault key derived from [pin].
  static Future<void> initVault(String pin) async {
    // 16-byte random salt
    final salt = enc.Key.fromSecureRandom(16).bytes;
    final key = _deriveKey(pin, salt);

    await _storage.write(
        key: _keyAlias, value: base64Encode(key.bytes));
    await _storage.write(
        key: _saltAlias, value: base64Encode(salt));
  }

  /// Returns true if the vault has been initialised.
  static Future<bool> isInitialised() async {
    return await _storage.read(key: _keyAlias) != null;
  }

  /// Verifies a PIN against the stored derived key.
  static Future<bool> verifyPin(String pin) async {
    final saltB64 = await _storage.read(key: _saltAlias);
    if (saltB64 == null) return false;

    final salt = base64Decode(saltB64);
    final candidate = _deriveKey(pin, salt);

    final stored = await _storage.read(key: _keyAlias);
    return stored == base64Encode(candidate.bytes);
  }

  // ── Encryption helpers ─────────────────────────────────────────

  /// Encrypts [plaintext] and returns a base64 string (IV + ciphertext).
  static Future<String> encrypt(String plaintext) async {
    final key = await _loadKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Prepend IV so we can decrypt later
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64Encode(combined);
  }

  /// Decrypts a base64-encoded string produced by [encrypt].
  static Future<String> decrypt(String cipherB64) async {
    final key = await _loadKey();
    final combined = base64Decode(cipherB64);

    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherBytes = enc.Encrypted(
        Uint8List.fromList(combined.sublist(16)));

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt(cipherBytes, iv: iv);
  }

  // ── Secure KV store ───────────────────────────────────────────

  static Future<void> writeSecure(String key, String value) async {
    final encrypted = await encrypt(value);
    await _storage.write(key: 'vault_$key', value: encrypted);
  }

  static Future<String?> readSecure(String key) async {
    final raw = await _storage.read(key: 'vault_$key');
    if (raw == null) return null;
    return decrypt(raw);
  }

  static Future<void> deleteSecure(String key) async {
    await _storage.delete(key: 'vault_$key');
  }

  // ── Private ───────────────────────────────────────────────────

  static enc.Key _deriveKey(String pin, Uint8List salt) {
    // PBKDF2-like: HMAC-SHA256 iterated 10,000 ×
    List<int> derived = utf8.encode(pin);
    for (int i = 0; i < 10000; i++) {
      final hmac = Hmac(sha256, salt);
      derived = hmac.convert(derived).bytes;
    }
    // Trim / pad to 32 bytes for AES-256
    return enc.Key(Uint8List.fromList(derived.take(32).toList()));
  }

  static Future<enc.Key> _loadKey() async {
    final keyB64 = await _storage.read(key: _keyAlias);
    if (keyB64 == null) throw StateError('Vault not initialised');
    return enc.Key(base64Decode(keyB64));
  }
}