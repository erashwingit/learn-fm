import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Upload result returned to the caller.
class UploadResult {
  final bool success;
  final String? publicUrl;
  final String? storagePath;
  final String? error;

  const UploadResult({
    required this.success,
    this.publicUrl,
    this.storagePath,
    this.error,
  });
}

/// Handles all Supabase Storage uploads with real byte-level progress tracking.
///
/// Progress is streamed via [onProgress] callback: 0.0 → 1.0.
///
/// Bucket layout:
///   course-videos/{domain}/{uuid}_{filename}
///   course-pdfs/{domain}/{uuid}_{filename}
class UploadService {
  UploadService._();

  static final SupabaseClient _db = Supabase.instance.client;

  // ─── Public upload entry point ────────────────────────────────────────────
  /// Uploads [file] to the appropriate Supabase Storage bucket.
  ///
  /// [contentType] must be 'video' or 'pdf'.
  /// [domain]      is the FM domain title (used as sub-folder).
  /// [onProgress]  receives values 0.0–1.0 as bytes are sent.
  static Future<UploadResult> upload({
    required File file,
    required String contentType, // 'video' | 'pdf'
    required String domain,
    required void Function(double progress) onProgress,
  }) async {
    assert(contentType == 'video' || contentType == 'pdf');

    final bucket =
        contentType == 'video' ? 'course-videos' : 'course-pdfs';
    final mime =
        contentType == 'video' ? 'video/mp4' : 'application/pdf';

    // Unique path prevents filename collisions
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeDomain =
        domain.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final fileName = file.path.split('/').last;
    final storagePath = '$safeDomain/${timestamp}_$fileName';

    try {
      final bytes = await file.readAsBytes();

      // ── Real progress via streaming HTTP upload ───────────────────────────
      final session = _db.auth.currentSession;
      if (session == null) {
        return const UploadResult(
          success: false,
          error: 'Not authenticated. Please sign in again.',
        );
      }

      final supabaseUrl = _db.supabaseUrl;
      final uploadUrl = Uri.parse(
          '$supabaseUrl/storage/v1/object/$bucket/$storagePath');

      final request = http.Request('POST', uploadUrl)
        ..headers.addAll({
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': mime,
          'x-upsert': 'false',
        })
        ..bodyBytes = bytes;

      // Send with streaming progress
      final streamedResponse = await _sendWithProgress(
        request,
        bytes.length,
        onProgress,
      );

      if (streamedResponse.statusCode != 200 &&
          streamedResponse.statusCode != 201) {
        final body = await streamedResponse.stream.bytesToString();
        return UploadResult(
          success: false,
          error: 'Upload failed (${streamedResponse.statusCode}): $body',
        );
      }

      // ── Get public URL ────────────────────────────────────────────────────
      final publicUrl =
          _db.storage.from(bucket).getPublicUrl(storagePath);

      onProgress(1.0); // ensure 100% on completion
      return UploadResult(
        success: true,
        publicUrl: publicUrl,
        storagePath: storagePath,
      );
    } on SocketException {
      return const UploadResult(
        success: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return UploadResult(
        success: false,
        error: 'Upload error: ${e.toString()}',
      );
    }
  }

  // ─── Streaming send with progress ─────────────────────────────────────────
  static Future<http.StreamedResponse> _sendWithProgress(
    http.Request request,
    int totalBytes,
    void Function(double) onProgress,
  ) async {
    // Convert the request body into a chunked stream so we can track bytes sent.
    const chunkSize = 65536; // 64 KB chunks
    final chunks = <List<int>>[];
    final body = request.bodyBytes;
    for (var i = 0; i < body.length; i += chunkSize) {
      chunks.add(body.sublist(
          i, (i + chunkSize).clamp(0, body.length)));
    }

    int bytesSent = 0;
    final streamCtrl = StreamController<List<int>>();

    // Feed chunks asynchronously so progress fires between them
    Future.microtask(() async {
      for (final chunk in chunks) {
        streamCtrl.add(chunk);
        bytesSent += chunk.length;
        onProgress(
            (bytesSent / totalBytes).clamp(0.0, 0.99));
        // Yield to the event loop so UI can repaint
        await Future.delayed(Duration.zero);
      }
      await streamCtrl.close();
    });

    final streamedRequest = http.StreamedRequest(
        request.method, request.url)
      ..headers.addAll(request.headers)
      ..contentLength = totalBytes;

    streamCtrl.stream.listen(
      streamedRequest.sink.add,
      onDone: streamedRequest.sink.close,
    );

    return http.Client().send(streamedRequest);
  }

  // ─── Delete file from storage ─────────────────────────────────────────────
  static Future<bool> deleteFile({
    required String bucket,
    required String storagePath,
  }) async {
    try {
      await _db.storage.from(bucket).remove([storagePath]);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Admin check ─────────────────────────────────────────────────────────
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      final res = await _db
          .from('profiles')
          .select('is_admin')
          .eq('id', uid)
          .maybeSingle();

      return res?['is_admin'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Validate file before upload ─────────────────────────────────────────
  static String? validateFile(File file, String contentType) {
    final sizeBytes = file.lengthSync();
    final ext = file.path.split('.').last.toLowerCase();

    if (contentType == 'video') {
      if (!['mp4', 'mov', 'avi', 'webm'].contains(ext)) {
        return 'Only MP4, MOV, AVI, or WebM videos are supported.';
      }
      if (sizeBytes > 500 * 1024 * 1024) {
        return 'Video must be under 500 MB. This file is ${(sizeBytes / 1024 / 1024).round()} MB.';
      }
    } else {
      if (ext != 'pdf') {
        return 'Only PDF files are supported.';
      }
      if (sizeBytes > 50 * 1024 * 1024) {
        return 'PDF must be under 50 MB. This file is ${(sizeBytes / 1024 / 1024).round()} MB.';
      }
    }
    return null; // valid
  }
}
