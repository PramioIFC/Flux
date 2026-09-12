import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks listening history and generates personalized recommendations.
class ListeningHistoryService {

  /// Log a listening event to Supabase
  static Future<void> logListen(Map<String, String> track) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('listening_history').insert({
        'user_id': user.id,
        'track_name': track['track_name'] ?? '',
        'artist': track['artist'] ?? '',
        'album_image_url': track['album_image_url'] ?? '',
        'media_id': track['media_id'] ?? '',
        'audio_url': track['audio_url'] ?? '',
        'source_url': track['source_url'] ?? '',
        'license_name': track['license_name'] ?? '',
        'license_url': track['license_url'] ?? '',
        'listened_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("FLUX HISTORY: Error logging listen: $e");
    }
  }

  /// Get the user's top artists based on listening frequency
  static Future<List<Map<String, dynamic>>> getTopArtists({int limit = 20}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final response = await Supabase.instance.client
          .rpc('get_top_artists', params: {
        'uid': user.id,
        'lim': limit,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint("FLUX HISTORY: Error fetching top artists: $e");
      return [];
    }
  }

  /// Get the user's top tracks based on listening frequency
  static Future<List<Map<String, dynamic>>> getTopTracks({int limit = 50}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final response = await Supabase.instance.client
          .rpc('get_top_tracks', params: {
        'uid': user.id,
        'lim': limit,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint("FLUX HISTORY: Error fetching top tracks: $e");
      return [];
    }
  }

  /// Get what a friend is currently listening to (most recent listen within last 5 min)
  static Future<Map<String, dynamic>?> getFriendNowPlaying(String friendId) async {
    try {
      final response = await Supabase.instance.client
          .from('now_playing')
          .select()
          .eq('user_id', friendId)
          .maybeSingle();

      if (response == null) return null;

      final updatedAt = DateTime.tryParse(response['updated_at'] ?? '');
      if (updatedAt == null) return null;

      // Only return if updated within the last 5 minutes
      if (DateTime.now().toUtc().difference(updatedAt.toUtc()).inMinutes <= 5) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint("FLUX HISTORY: Error fetching friend now playing: $e");
      return null;
    }
  }

  /// Broadcast current listening status for real-time friend activity
  static Future<void> broadcastNowPlaying(Map<String, String> track) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('now_playing').upsert({
        'user_id': user.id,
        'track_name': track['track_name'] ?? '',
        'artist': track['artist'] ?? '',
        'album_image_url': track['album_image_url'] ?? '',
        'media_id': track['media_id'] ?? '',
        'audio_url': track['audio_url'] ?? '',
        'source_url': track['source_url'] ?? '',
        'license_name': track['license_name'] ?? '',
        'license_url': track['license_url'] ?? '',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint("FLUX HISTORY: Error broadcasting now playing: $e");
    }
  }
}
