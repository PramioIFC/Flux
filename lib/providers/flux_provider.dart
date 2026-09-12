import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/demo_catalog_service.dart';
import '../services/equalizer_service.dart';
import '../services/listening_history_service.dart';

enum PlaybackRepeatMode { off, all, one }

class FluxProvider extends ChangeNotifier {
  late final AudioPlayer player;
  AndroidEqualizer? androidEqualizer;
  EqualizerService? _eqService;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  Map<String, String>? currentTrack;
  List<Map<String, String>> currentQueue = [];
  Map<String, List<Map<String, String>>> playlists = {'Favoritas': []};
  List<Map<String, String>> _recentlyPlayed = [];
  final Map<String, bool> _playlistShuffleMode = {};
  final Map<String, String> _playlistCovers = {};
  final List<String> _pinnedPlaylists = [];

  String username = '';
  bool isPublic = false;
  List<String> friends = [];
  bool _showTrending = true;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;
  bool _isShuffled = false;
  Color dominantColor = const Color(0xFF14B8A6);

  FluxProvider() {
    if (!kIsWeb && Platform.isAndroid) {
      androidEqualizer = AndroidEqualizer();
      player = AudioPlayer(
        audioPipeline: AudioPipeline(androidAudioEffects: [androidEqualizer!]),
      );
    } else {
      player = AudioPlayer();
    }
    _registerPlayerListeners();
    _loadFromPrefs();
  }

  List<Map<String, String>> get demoCatalog =>
      DemoCatalogService.tracks.map(Map<String, String>.from).toList();
  List<Map<String, String>> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;
  bool get showTrending => _showTrending;
  String get audioQuality => 'source';
  PlaybackRepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;

  void attachEqualizerService(EqualizerService service) {
    if (_eqService == service) return;
    _eqService?.removeListener(_applyEqualizerSettings);
    _eqService = service..addListener(_applyEqualizerSettings);
    _applyEqualizerSettings();
  }

  Future<void> _applyEqualizerSettings() async {
    if (androidEqualizer == null || _eqService == null) return;
    try {
      final parameters = await androidEqualizer!.parameters;
      await androidEqualizer!.setEnabled(_eqService!.isEnabled);
      for (var i = 0;
          i < _eqService!.currentBands.length && i < parameters.bands.length;
          i++) {
        await parameters.bands[i].setGain(_eqService!.currentBands[i]);
      }
    } catch (error) {
      debugPrint('FLUX EQ: $error');
    }
  }

  void _registerPlayerListeners() {
    player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= currentQueue.length) return;
      final next = Map<String, String>.from(currentQueue[index]);
      if (currentTrack?['media_id'] == next['media_id']) return;
      currentTrack = next;
      _addToRecentlyPlayed(next);
      ListeningHistoryService.logListen(next);
      ListeningHistoryService.broadcastNowPlaying(next);
      notifyListeners();
    });
  }

  AudioSource _sourceFor(Map<String, String> track) {
    if (!DemoCatalogService.isAllowed(track)) {
      throw StateError('Faixa fora do catálogo autorizado.');
    }
    return AudioSource.uri(
      Uri.parse(track['audio_url']!),
      tag: MediaItem(
        id: track['media_id']!,
        title: track['track_name']!,
        artist: track['artist'],
        extras: {
          'source_url': track['source_url'],
          'license_name': track['license_name'],
        },
      ),
    );
  }

  Future<void> _setQueue(List<Map<String, String>> tracks, int index) async {
    final allowed = tracks.where(DemoCatalogService.isAllowed).map(Map<String, String>.from).toList();
    if (allowed.isEmpty) return;
    currentQueue = allowed;
    currentTrack = allowed[index.clamp(0, allowed.length - 1)];
    await player.setAudioSources(
      allowed.map(_sourceFor).toList(),
      initialIndex: index.clamp(0, allowed.length - 1),
    );
    await player.play();
    _addToRecentlyPlayed(currentTrack!);
    notifyListeners();
  }

  Future<void> playTrack(Map<String, String> track,
      {List<Map<String, String>>? queue}) async {
    final tracks = queue ?? [track];
    final index = tracks.indexWhere((item) => item['media_id'] == track['media_id']);
    await _setQueue(tracks, index < 0 ? 0 : index);
  }

  void playPlaylist(List<Map<String, String>> tracks, {bool shuffle = false}) {
    final queue = tracks.where(DemoCatalogService.isAllowed).map(Map<String, String>.from).toList();
    if (shuffle) queue.shuffle();
    _setQueue(queue, 0);
  }

  Future<void> skipNext() => player.seekToNext();
  Future<void> skipPrevious() => player.seekToPrevious();

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final item = currentQueue.removeAt(oldIndex);
    currentQueue.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= currentQueue.length) return;
    currentQueue.removeAt(index);
    notifyListeners();
  }

  Future<void> addToQueue(Map<String, String> track) async {
    if (!DemoCatalogService.isAllowed(track)) return;
    currentQueue.add(Map<String, String>.from(track));
    notifyListeners();
  }

  void toggleRepeatMode() {
    _repeatMode = PlaybackRepeatMode.values[(_repeatMode.index + 1) % 3];
    player.setLoopMode(switch (_repeatMode) {
      PlaybackRepeatMode.off => LoopMode.off,
      PlaybackRepeatMode.all => LoopMode.all,
      PlaybackRepeatMode.one => LoopMode.one,
    });
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    player.setShuffleModeEnabled(_isShuffled);
    notifyListeners();
  }

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerEndTime = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      player.stop();
      _sleepTimerEndTime = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerEndTime = null;
    notifyListeners();
  }

  bool isPlaylistShuffled(String name) => _playlistShuffleMode[name] ?? true;
  void togglePlaylistShuffle(String name) => setPlaylistShuffle(name, !isPlaylistShuffled(name));
  void setPlaylistShuffle(String name, bool value) {
    _playlistShuffleMode[name] = value;
    _saveAuxiliaryPrefs();
    notifyListeners();
  }

  bool isPinned(String name) => _pinnedPlaylists.contains(name);
  void togglePin(String name) {
    isPinned(name) ? _pinnedPlaylists.remove(name) : _pinnedPlaylists.add(name);
    _saveAuxiliaryPrefs();
    notifyListeners();
  }

  String? getPlaylistCover(String name) {
    if ((_playlistCovers[name] ?? '').isNotEmpty) return _playlistCovers[name];
    final tracks = playlists[name];
    return tracks != null && tracks.isNotEmpty ? tracks.first['album_image_url'] : null;
  }
  void setPlaylistCover(String name, String path) {
    _playlistCovers[name] = path;
    _saveAuxiliaryPrefs();
    notifyListeners();
  }
  void removePlaylistCover(String name) {
    _playlistCovers.remove(name);
    _saveAuxiliaryPrefs();
    notifyListeners();
  }

  void createPlaylist(String name) {
    final clean = name.trim();
    if (clean.isEmpty || playlists.containsKey(clean)) return;
    playlists[clean] = [];
    saveToPrefs();
    notifyListeners();
  }

  void importPlaylistsData(Map<String, List<Map<String, String>>> data) {
    for (final entry in data.entries) {
      final allowed = entry.value.where(DemoCatalogService.isAllowed).map(Map<String, String>.from).toList();
      playlists[entry.key] = allowed;
    }
    saveToPrefs();
    notifyListeners();
  }

  void addTrackToPlaylist(String name, Map<String, String> track) {
    if (!DemoCatalogService.isAllowed(track) || !playlists.containsKey(name)) return;
    if (!playlists[name]!.any((item) => item['media_id'] == track['media_id'])) {
      playlists[name]!.add(Map<String, String>.from(track));
      saveToPrefs();
      notifyListeners();
    }
  }
  void addToPlaylist(String name, Map<String, String> track) => addTrackToPlaylist(name, track);

  void removeFromPlaylist(String name, Map<String, String> track) {
    playlists[name]?.removeWhere((item) => item['media_id'] == track['media_id']);
    saveToPrefs();
    notifyListeners();
  }
  void deletePlaylist(String name) {
    playlists.remove(name);
    _playlistCovers.remove(name);
    _playlistShuffleMode.remove(name);
    _pinnedPlaylists.remove(name);
    saveToPrefs();
    _saveAuxiliaryPrefs();
    notifyListeners();
  }
  void renamePlaylist(String oldName, String newName) {
    final clean = newName.trim();
    if (clean.isEmpty || playlists.containsKey(clean) || !playlists.containsKey(oldName)) return;
    playlists[clean] = playlists.remove(oldName)!;
    saveToPrefs();
    notifyListeners();
  }

  bool isFavorite(Map<String, String> track) =>
      playlists['Favoritas']?.any((item) => item['media_id'] == track['media_id']) ?? false;
  void toggleFavorite(Map<String, String> track) {
    if (isFavorite(track)) {
      removeFromPlaylist('Favoritas', track);
    } else {
      addTrackToPlaylist('Favoritas', track);
    }
  }

  List<MapEntry<String, int>> getAllArtistsSorted() {
    final counts = <String, int>{};
    for (final list in playlists.values) {
      for (final track in list) {
        final artist = track['artist'] ?? 'Desconhecido';
        counts[artist] = (counts[artist] ?? 0) + 1;
      }
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }
  List<Map<String, String>> getTracksForArtist(String artist) {
    final seen = <String>{};
    return playlists.values
        .expand((list) => list)
        .where((track) => track['artist'] == artist && seen.add(track['media_id']!))
        .map(Map<String, String>.from)
        .toList();
  }
  String? getArtistImageUrl(String artist) {
    final tracks = getTracksForArtist(artist);
    return tracks.isEmpty ? null : tracks.first['album_image_url'];
  }

  void _addToRecentlyPlayed(Map<String, String> track) {
    _recentlyPlayed.removeWhere((item) => item['media_id'] == track['media_id']);
    _recentlyPlayed.insert(0, Map<String, String>.from(track));
    if (_recentlyPlayed.length > 20) _recentlyPlayed.removeLast();
    _saveAuxiliaryPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('flux_demo_playlists');
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final row = await Supabase.instance.client.from('user_data')
            .select('playlists_json, username, is_public, friends')
            .eq('user_id', user.id).maybeSingle();
        if (row != null) {
          saved = jsonEncode(row['playlists_json']);
          username = row['username']?.toString() ?? '';
          isPublic = row['is_public'] == true;
          friends = (row['friends'] as List?)?.map((e) => e.toString()).toList() ?? [];
        }
      } catch (error) {
        debugPrint('FLUX SYNC: $error');
      }
    }
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        playlists = decoded.map((name, value) => MapEntry(
          name,
          (value as List)
              .map((item) => Map<String, String>.from(item as Map))
              .where(DemoCatalogService.isAllowed)
              .toList(),
        ));
      } catch (error) {
        debugPrint('FLUX STORAGE: $error');
      }
    }
    playlists.putIfAbsent('Favoritas', () => []);
    _showTrending = prefs.getBool('flux_show_trending') ?? true;
    _readAuxiliaryPrefs(prefs);
    notifyListeners();
  }

  void _readAuxiliaryPrefs(SharedPreferences prefs) {
    try {
      _recentlyPlayed = (jsonDecode(prefs.getString('flux_demo_recent') ?? '[]') as List)
          .map((item) => Map<String, String>.from(item as Map))
          .where(DemoCatalogService.isAllowed).toList();
      _playlistCovers.addAll(Map<String, String>.from(
          jsonDecode(prefs.getString('flux_playlist_covers') ?? '{}') as Map));
      _pinnedPlaylists.addAll((jsonDecode(prefs.getString('flux_pinned_playlists') ?? '[]') as List)
          .map((item) => item.toString()));
    } catch (error) {
      debugPrint('FLUX PREFS: $error');
    }
  }

  Future<void> _saveAuxiliaryPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flux_demo_recent', jsonEncode(_recentlyPlayed));
    await prefs.setString('flux_playlist_covers', jsonEncode(_playlistCovers));
    await prefs.setString('flux_pinned_playlists', jsonEncode(_pinnedPlaylists));
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flux_demo_playlists', jsonEncode(playlists));
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('user_data').upsert({
        'user_id': user.id,
        'playlists_json': playlists,
        'username': username,
        'is_public': isPublic,
        'friends': friends,
      }, onConflict: 'user_id');
    } catch (error) {
      debugPrint('FLUX SYNC: $error');
    }
  }

  Future<void> setAudioQuality(String _) async {}
  Future<void> toggleShowTrending(bool value) async {
    _showTrending = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flux_show_trending', value);
    notifyListeners();
  }
  Future<void> updateUsername(String value) async {
    username = value;
    await saveToPrefs();
    notifyListeners();
  }
  Future<void> toggleIsPublic(bool value) async {
    isPublic = value;
    await saveToPrefs();
    notifyListeners();
  }
  Future<void> toggleFriend(String id) async {
    friends.contains(id) ? friends.remove(id) : friends.add(id);
    await saveToPrefs();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await Supabase.instance.client.rpc('search_users', params: {'query_text': query});
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (_) { return []; }
  }
  Future<Map<String, dynamic>?> getFriendData(String id) async {
    try {
      final response = await Supabase.instance.client.rpc('get_friend_profile', params: {'friend_uid': id});
      return response == null ? null : Map<String, dynamic>.from(response);
    } catch (_) { return null; }
  }
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    if (friends.isEmpty) return [];
    try {
      final response = await Supabase.instance.client.rpc('get_friends_list', params: {'friend_ids': friends});
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (_) { return []; }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _eqService?.removeListener(_applyEqualizerSettings);
    player.dispose();
    super.dispose();
  }
}
