import 'package:cryptography/cryptography.dart';
import 'dart:typed_data';
import 'dart:convert'; // <-- TO DODAJ!
import 'package:flutter_secure_storage/flutter_secure_storage.dart';




class CloudCryptoService {
  static final _algo = AesGcm.with256bits();

  static Future<Map<String, dynamic>> encryptData(Uint8List plainBytes, List<int> keyBytes) async {
    final nonce = _algo.newNonce();
    final secretKey = SecretKey(keyBytes);
    final secretBox = await _algo.encrypt(plainBytes, secretKey: secretKey, nonce: nonce);

    return {
      "nonce": base64Encode(nonce),
      "cipherText": base64Encode(secretBox.cipherText),
      "mac": base64Encode(secretBox.mac.bytes),
    };
  }

  static Future<Uint8List> decryptData(
    String cipherTextBase64,
    String nonceBase64,
    String macBase64,
    List<int> keyBytes,
  ) async {
    final secretKey = SecretKey(keyBytes);
    final cipherText = base64Decode(cipherTextBase64);
    final nonce = base64Decode(nonceBase64);
    final mac = Mac(base64Decode(macBase64));
    final box = SecretBox(cipherText, nonce: nonce, mac: mac);

    final clearBytes = await _algo.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(clearBytes);
  }
}




class SecureCloudKeyService {
  static const _cloudKeyKey = 'cloud_encryption_key';
  final _storage = const FlutterSecureStorage();

  // Generowanie nowego klucza (32 bajty = 256-bit AES)
  Future<List<int>> generateAndSaveKey() async {
    final algo = AesGcm.with256bits();
    final newKey = await algo.newSecretKey();
    final keyBytes = await newKey.extractBytes();
    // Zapisz jako base64
    await _storage.write(key: _cloudKeyKey, value: base64Encode(keyBytes));
    return keyBytes;
  }
  /// DODAJ TO! --->
  Future<String> generateAndSaveKeyReturnBase64() async {
    final algo = AesGcm.with256bits();
    final newKey = await algo.newSecretKey();
    final keyBytes = await newKey.extractBytes();
    final keyBase64 = base64Encode(keyBytes);
    await _storage.write(key: _cloudKeyKey, value: keyBase64);
    return keyBase64;
  }

  // Pobierz klucz z secure storage
  Future<List<int>?> getKey() async {
    final base64key = await _storage.read(key: _cloudKeyKey);
    if (base64key == null) return null;
    return base64Decode(base64key);
  }

  // Usuń klucz (np. przy resetowaniu)
  Future<void> clearKey() async {
    await _storage.delete(key: _cloudKeyKey);
  }
}
