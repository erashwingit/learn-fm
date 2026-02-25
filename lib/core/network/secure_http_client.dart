import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SecureHttpClient wraps Flutter's HTTP client with certificate pinning.
///
/// Certificate pinning ensures the app only communicates with servers
/// presenting certificates whose SHA-256 fingerprints match a known-good set,
/// preventing MITM attacks even on compromised networks.
///
/// Usage:
///   final client = await SecureHttpClient.create();
///   final response = await client.get(Uri.parse('https://xxx.supabase.co'));
///
/// Setup:
///   1. Export your server's leaf certificate:
///      openssl s_client -connect <host>:443 </dev/null 2>/dev/null \
///        | openssl x509 -outform DER > assets/certs/supabase.der
///   2. Add to pubspec.yaml assets section.
///   3. Compute SHA-256 fingerprint:
///      openssl dgst -sha256 -binary assets/certs/supabase.der \
///        | openssl base64
///   4. Paste fingerprint into [_pinnedFingerprints] below.
class SecureHttpClient {
  SecureHttpClient._();

  // ─── Pinned SHA-256 certificate fingerprints ────────────────────────────
  // Update these when certificates are rotated (typically every 1–2 years).
  // Maintain two entries during rotation: old + new.
  static const Set<String> _pinnedFingerprints = {
    // Supabase production certificate fingerprint (replace with real value)
    'REPLACE_WITH_SUPABASE_CERT_SHA256_BASE64',
    // Anthropic / Edge Function endpoint fingerprint (if calling directly)
    // 'REPLACE_WITH_ANTHROPIC_CERT_SHA256_BASE64',
  };

  // Path to bundled DER-encoded certificate in assets
  static const String _certAssetPath = 'assets/certs/supabase.der';

  // ─── Factory ─────────────────────────────────────────────────────────────
  /// Creates a pinned HTTP client. Call once at app startup and reuse.
  static Future<http.Client> create() async {
    final certBytes = await _loadCertificateBytes();

    final securityContext = SecurityContext(withTrustedRoots: false);
    securityContext.setTrustedCertificatesBytes(certBytes);

    final httpClient = HttpClient(context: securityContext)
      ..badCertificateCallback = _badCertificateCallback;

    return IOClient(httpClient);
  }

  // ─── Certificate loading ──────────────────────────────────────────────────
  static Future<Uint8List> _loadCertificateBytes() async {
    final byteData = await rootBundle.load(_certAssetPath);
    return byteData.buffer.asUint8List();
  }

  // ─── Pin validation callback ──────────────────────────────────────────────
  /// Called for every TLS handshake. Returns true to ALLOW, false to BLOCK.
  static bool _badCertificateCallback(
    X509Certificate cert,
    String host,
    int port,
  ) {
    // Compute SHA-256 of the DER-encoded certificate
    final fingerprint = _computeFingerprint(cert.der);

    if (_pinnedFingerprints.contains(fingerprint)) {
      // Cert matches our pin — allow
      return true;
    }

    // Certificate does not match any pin — block connection
    // Log in debug mode only (never log in production to avoid leaking info)
    assert(() {
      // ignore: avoid_print
      print('[SecureHttpClient] PIN MISMATCH for $host:$port — fingerprint: $fingerprint');
      return true;
    }());

    return false;
  }

  /// Computes the Base64-encoded SHA-256 digest of raw DER certificate bytes.
  static String _computeFingerprint(Uint8List derBytes) {
    final digest = sha256.convert(derBytes);
    // Encode as Base64 to match openssl output format
    return _base64Encode(Uint8List.fromList(digest.bytes));
  }

  static String _base64Encode(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result
        ..writeCharCode(chars.codeUnitAt((b0 >> 2) & 0x3F))
        ..writeCharCode(chars.codeUnitAt(((b0 << 4) | (b1 >> 4)) & 0x3F))
        ..writeCharCode(i + 1 < bytes.length
            ? chars.codeUnitAt(((b1 << 2) | (b2 >> 6)) & 0x3F)
            : 0x3D) // '='
        ..writeCharCode(i + 2 < bytes.length
            ? chars.codeUnitAt(b2 & 0x3F)
            : 0x3D); // '='
    }
    return result.toString();
  }
}

/// Extension to make [SecureHttpClient] easy to use with Supabase REST calls.
extension SecureHttpClientSupabase on http.Client {
  /// Convenience: POST to Supabase Edge Function with Authorization header.
  Future<http.Response> postEdgeFunction({
    required String url,
    required String accessToken,
    required Map<String, dynamic> body,
  }) {
    return post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'apikey': '', // filled by caller or via Supabase client
      },
      body: _jsonEncode(body),
    );
  }

  static String _jsonEncode(Map<String, dynamic> data) {
    // Inline minimal JSON encoder to avoid extra dependencies here
    final sb = StringBuffer('{');
    var first = true;
    data.forEach((k, v) {
      if (!first) sb.write(',');
      sb
        ..write('"')
        ..write(k.replaceAll('"', r'\"'))
        ..write('":')
        ..write(_encodeValue(v));
      first = false;
    });
    sb.write('}');
    return sb.toString();
  }

  static String _encodeValue(dynamic v) {
    if (v == null) return 'null';
    if (v is bool) return v.toString();
    if (v is num) return v.toString();
    if (v is String) return '"${v.replaceAll('"', r'\"')}"';
    if (v is List) return '[${v.map(_encodeValue).join(',')}]';
    if (v is Map) return _jsonEncode(v.cast<String, dynamic>());
    return '"${v.toString()}"';
  }
}
