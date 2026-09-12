import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../providers/flux_provider.dart';
import '../services/listening_history_service.dart';

class FriendActivityScreen extends StatefulWidget {
  const FriendActivityScreen({super.key});

  @override
  State<FriendActivityScreen> createState() => _FriendActivityScreenState();
}

class _FriendActivityScreenState extends State<FriendActivityScreen> {
  List<Map<String, dynamic>> _friendActivities = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadActivities());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    final provider = Provider.of<FluxProvider>(context, listen: false);
    final friends = provider.friends;

    if (friends.isEmpty) {
      if (mounted) {
        setState(() {
          _friendActivities = [];
          _isLoading = false;
        });
      }
      return;
    }

    final activities = <Map<String, dynamic>>[];

    for (final friendId in friends) {
      try {
        final nowPlaying = await ListeningHistoryService.getFriendNowPlaying(friendId);
        if (nowPlaying != null) {
          // Get friend username
          final friendData = await provider.getFriendData(friendId);
          activities.add({
            ...nowPlaying,
            'username': friendData?['username'] ?? 'Unknown',
            'is_live': true,
          });
        }
      } catch (e) {
        debugPrint("Error loading activity for $friendId: $e");
      }
    }

    if (mounted) {
      setState(() {
        _friendActivities = activities;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluxApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FRIEND ACTIVITY',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: FluxApp.secondaryTextColor),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: FluxApp.accentColor),
            )
          : _friendActivities.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: FluxApp.accentColor,
                  onRefresh: _loadActivities,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _friendActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _friendActivities[index];
                      return _FriendActivityCard(activity: activity);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: FluxApp.secondaryTextColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No friends are listening right now',
            style: GoogleFonts.inter(
              color: FluxApp.secondaryTextColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When your friends are playing music,\nyou\'ll see their activity here',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: FluxApp.secondaryTextColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _FriendActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final username = activity['username'] ?? 'Unknown';
    final trackName = activity['track_name'] ?? '';
    final artist = activity['artist'] ?? '';
    final albumImage = activity['album_image_url'] ?? '';
    final isLive = activity['is_live'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FluxApp.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: FluxApp.accentColor.withValues(alpha: 0.2),
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    color: FluxApp.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              if (isLive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: FluxApp.cardColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isLive) ...[
                      Icon(Icons.graphic_eq_rounded, size: 14, color: const Color(0xFF4ADE80)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        '$trackName • $artist',
                        style: GoogleFonts.inter(
                          color: FluxApp.secondaryTextColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Album art
          if (albumImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Image.network(
                  albumImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: FluxApp.surfaceColor,
                    child: const Icon(Icons.music_note, size: 20, color: FluxApp.secondaryTextColor),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Listen along button
          GestureDetector(
            onTap: () {
              final provider = Provider.of<FluxProvider>(context, listen: false);
              final track = <String, String>{
                'track_name': trackName.toString(),
                'artist': artist.toString(),
                'album_image_url': albumImage.toString(),
                'media_id': (activity['media_id'] ?? '').toString(),
                'audio_url': (activity['audio_url'] ?? '').toString(),
                'source_url': (activity['source_url'] ?? '').toString(),
                'license_name': (activity['license_name'] ?? '').toString(),
                'license_url': (activity['license_url'] ?? '').toString(),
              };
              provider.playPlaylist([track]);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FluxApp.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: FluxApp.accentColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
