import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';


class SensitiveDataProcessor {
  SensitiveDataProcessor._();

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) {
      return '$local***@$domain';
    }
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@$domain';
  }

  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return phone;
    final visible = digits.substring(digits.length - 4);
    return '*** *** $visible';
  }

  static String maskString(String value, {int visibleChars = 4}) {
    if (value.length <= visibleChars) return value;
    return '${'*' * (value.length - visibleChars)}${value.substring(value.length - visibleChars)}';
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  static bool isValidMexicanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return true;
    if (digits.length == 12 || digits.length == 13) {
      return digits.startsWith('52') || digits.startsWith('1');
    }
    return false;
  }

  static Map<String, dynamic> sanitizeForLogging(Map<String, dynamic> data) {
    final sensitiveKeys = <String>{
      'password',
      'contraseña',
      'token',
      'jwt',
      'accessToken',
      'refreshToken',
      'secret',
      'apiKey',
      'sessionToken',
      'session_token',
      'authorization',
      'pin',
      'cvv',
      'cvc',
      'ccNumber',
      'cardNumber',
    };

    return data.map((key, value) {
      final keyLower = key.toLowerCase();
      if (sensitiveKeys.any((sk) => keyLower.contains(sk))) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  static String computeDataFingerprint(Map<String, dynamic> data) {
    final normalized = jsonEncode(data);
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  static void debugLogSanitized(
    String tag,
    Map<String, dynamic> data,
  ) {
    final sanitized = sanitizeForLogging(data);
    debugPrint('[$tag] $sanitized');
  }
}
