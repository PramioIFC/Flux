import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flux_provider.dart';
import '../main.dart';

class ArtistScreen extends StatelessWidget {
  final String artistName;

  const ArtistScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context) {
    return Consumer<FluxProvider>(
      builder: (context, provider, child) {
        final artistTracks = provider.getTracksForArtist(artistName);
        final artistImageUrl = provider.getArtistImageUrl(artistName);

        return Scaffold(
          backgroundColor: FluxApp.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // --- Hero SliverAppBar ---
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: FluxApp.backgroundColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image or gradient fallback
                      if (artistImageUrl != null && artistImageUrl.isNotEmpty)
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Image.network(
                            artistImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    FluxApp.accentColor.withValues(alpha: 0.6),
                                    FluxApp.backgroundColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                FluxApp.accentColor.withValues(alpha: 0.6),
                                FluxApp.backgroundColor,
                              ],
                            ),
                          ),
                        ),

                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              FluxApp.backgroundColor.withValues(alpha: 0.85),
                              FluxApp.backgroundColor,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),

                      // Artist info
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artistName,
                              style: TextStyle(
                                color: FluxApp.primaryTextColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${artistTracks.length} ${artistTracks.length == 1 ? 'música' : 'músicas'}',
                              style: TextStyle(
                                color: FluxApp.secondaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Action buttons ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Tocar Tudo',
                          filled: true,
                          onTap: () {
                            if (artistTracks.isNotEmpty) {
                              provider.playPlaylist(artistTracks);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.shuffle_rounded,
                          label: 'Aleatório',
                          filled: false,
                          onTap: () {
                            if (artistTracks.isNotEmpty) {
                              provider.playPlaylist(artistTracks, shuffle: true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Track list ---
              if (artistTracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 48,
                          color: FluxApp.secondaryTextColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma música encontrada',
                          style: TextStyle(
                            color: FluxApp.secondaryTextColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = artistTracks[index];
                      final isLast = index == artistTracks.length - 1;

                      return Column(
                        children: [
                          _TrackTile(
                            track: track,
                            index: index,
                            onTap: () {
                              provider.playTrack(track, queue: artistTracks);
                            },
                            onAddToPlaylist: () {
                              _showAddToPlaylistDialog(
                                context,
                                provider,
                                track,
                              );
                            },
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.only(left: 76),
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.06),
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    },
                    childCount: artistTracks.length,
                  ),
                ),

              // Bottom padding for mini player
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    FluxProvider provider,
    Map<String, String> track,
  ) {
    final playlistNames = provider.playlists.keys.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: FluxApp.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.playlist_add_rounded,
                      color: FluxApp.accentColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Adicionar à playlist',
                      style: TextStyle(
                        color: FluxApp.primaryTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              if (playlistNames.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma playlist criada ainda',
                    style: TextStyle(
                      color: FluxApp.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlistNames.length,
                    itemBuilder: (_, i) {
                      final name = playlistNames[i];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: FluxApp.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.queue_music_rounded,
                            color: FluxApp.accentColor,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: FluxApp.primaryTextColor,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${provider.playlists[name]?.length ?? 0} músicas',
                          style: TextStyle(
                            color: FluxApp.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          provider.addTrackToPlaylist(name, track);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Adicionada a "$name"',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: FluxApp.accentColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Action Button (Tocar Tudo / Aleatório)
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? FluxApp.accentColor : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(
                    color: FluxApp.accentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled ? Colors.white : FluxApp.accentColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : FluxApp.accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Track list tile
// ---------------------------------------------------------------------------
class _TrackTile extends StatelessWidget {
  final Map<String, String> track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAddToPlaylist;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.onTap,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = track['album_image_url'] ?? '';
    final trackName = track['track_name'] ?? 'Sem título';
    final artist = track['artist'] ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderArt(),
                      )
                    : _placeholderArt(),
              ),
            ),
            const SizedBox(width: 14),

            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackName,
                    style: TextStyle(
                      color: FluxApp.primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    artist,
                    style: TextStyle(
                      color: FluxApp.secondaryTextColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Heart button
            Consumer<FluxProvider>(
              builder: (context, provider, child) {
                final isFav = provider.isFavorite(track);
                return SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? FluxApp.accentColor : FluxApp.secondaryTextColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    onPressed: () => provider.toggleFavorite(track),
                  ),
                );
              },
            ),

            // Menu button
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: FluxApp.secondaryTextColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                splashRadius: 20,
                onPressed: onAddToPlaylist,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      color: FluxApp.cardColor,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: FluxApp.secondaryTextColor.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }
}
