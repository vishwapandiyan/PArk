import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class StorageService {
  static SupabaseClient get _client => AppSupabase.client;

  static Future<String> uploadFile({
    required File file,
    required String bucket,
    required String path,
  }) async {
    final storage = _client.storage.from(bucket);
    await storage.upload(path, file);
    final publicUrl = storage.getPublicUrl(path);
    return publicUrl;
  }
}


