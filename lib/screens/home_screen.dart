import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../providers/flux_provider.dart';
import '../services/demo_catalog_service.dart';
import 'playlist_detail_screen.dart';
import 'artist_screen.dart';

const artistColors = [
  Color(0xFF6366F1),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
  Color(0xFF10B981),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _trendingTracks = [];
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    final tracks = DemoCatalogService.search('');
    if (mounted) {
      setState(() {
        _trendingTracks = tracks;
        _isLoadingTrending = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia ☀️';
    if (hour < 18) return 'Boa tarde 🌤️';
    return 'Boa noite 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Consumer<FluxProvider>(
      builder: (context, provider, _) {
        final playlists = provider.playlists;
        final recentlyPlayed = provider.recentlyPlayed;
        final artists = provider.getAllArtistsSorted();

        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 100 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Greeting Header ──
              Text(
                _getGreeting(),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Suas Playlists ──
              _buildSectionTitle('Suas Playlists'),
              const SizedBox(height: 12),
              _buildPlaylistGrid(context, provider, playlists),
              const SizedBox(height: 24),
              const SizedBox(height: 12),

              // Only add spacing if artists section will also show
              if (artists.isNotEmpty) const SizedBox(height: 24),

              // ── 3. Seus Artistas Favoritos ──
              if (artists.isNotEmpty) ...[
                _buildSectionTitle('Seus Artistas Favoritos'),
                const SizedBox(height: 12),
                _buildArtistRow(context, provider, artists),
              ],

              const SizedBox(height: 24),

              // ── 4. Em Alta ──
              if (provider.showTrending) ...[
                _buildSectionTitle('Em Alta'),
                const SizedBox(height: 12),
                if (_isLoadingTrending)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: FluxApp.accentColor)),
                  )
                else if (_trendingTracks.isNotEmpty)
                  _buildRecentlyPlayed(context, provider, _trendingTracks)
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("Não foi possível carregar as tendências.", style: TextStyle(color: FluxApp.secondaryTextColor)),
                  ),
                const SizedBox(height: 24),
              ],

              // ── 5. Tocadas Recentemente ──
              _buildSectionTitle('Tocadas Recentemente'),
              const SizedBox(height: 12),
              _buildRecentlyPlayed(context, provider, recentlyPlayed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCoverImage(String url) {
    if (!url.startsWith('https://')) {
      return const _PlaylistPlaceholder();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _PlaylistPlaceholder(),
    );
  }

  // ── Playlists Quick Grid ──
  Widget _buildPlaylistGrid(
    BuildContext context,
    FluxProvider provider,
    Map<String, List<Map<String, String>>> playlists,
  ) {
    final entries = playlists.entries.toList();

    final hasContent = entries.any((e) => e.value.isNotEmpty);

    if (entries.isEmpty || !hasContent) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.playlist_add, size: 36, color: FluxApp.secondaryTextColor),
              const SizedBox(height: 8),
              Text(
                'Nenhuma playlist encontrada.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: FluxApp.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayEntries = entries.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayEntries.length,
      itemBuilder: (context, index) {
        final name = displayEntries[index].key;
        final tracks = displayEntries[index].value;
        final coverUrl = provider.getPlaylistCover(name);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(
                  playlistName: name,
                  tracks: tracks,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: FluxApp.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(
                  width: 55,
                  height: 55,
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? _buildCoverImage(coverUrl)
                      : const _PlaylistPlaceholder(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Artists Horizontal Scroll ──
  Widget _buildArtistRow(
    BuildContext context,
    FluxProvider provider,
    List<MapEntry<String, int>> artists,
  ) {
    final topArtists = artists.take(10).toList();

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topArtists.length,
        itemBuilder: (context, index) {
          final artistName = topArtists[index].key;
          final imageUrl = provider.getArtistImageUrl(artistName);
          final colorIndex = artistName.hashCode.abs() % artistColors.length;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistScreen(artistName: artistName),
                ),
              );
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  imageUrl != null && imageUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(imageUrl),
                        )
                      : CircleAvatar(
                          radius: 40,
                          backgroundColor: artistColors[colorIndex],
                          child: Text(
                            artistName.isNotEmpty
                                ? artistName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    artistName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: FluxApp.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Recently Played List ──
  Widget _buildRecentlyPlayed(
    BuildContext context,
    FluxProvider provider,
    List<Map<String, String>> recentlyPlayed,
  ) {
    if (recentlyPlayed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Nenhuma música tocada ainda.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: FluxApp.secondaryTextColor,
          ),
        ),
      );
    }

    final displayTracks = recentlyPlayed.take(10).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayTracks.length,
      itemBuilder: (context, index) {
        final track = displayTracks[index];
        final trackName = track['track_name'] ?? 'Sem título';
        final artist = track['artist'] ?? 'Artista desconhecido';
        final albumArt = track['album_image_url'];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: albumArt != null && albumArt.isNotEmpty
                  ? Image.network(
                      albumArt,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: FluxApp.cardColor,
                        child: const Icon(
                          Icons.music_note,
                          color: FluxApp.accentColor,
                        ),
                      ),
                    )
                  : Container(
                      color: FluxApp.cardColor,
                      child: const Icon(
                        Icons.music_note,
                        color: FluxApp.accentColor,
                      ),
                    ),
            ),
          ),
          title: Text(
            trackName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            artist,
            style: GoogleFonts.inter(
              color: FluxApp.secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              provider.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: provider.isFavorite(track) ? FluxApp.accentColor : FluxApp.secondaryTextColor,
            ),
            onPressed: () => provider.toggleFavorite(track),
          ),
          onTap: () {
            provider.playTrack(track, queue: recentlyPlayed);
          },
        );
      },
    );
  }
}

class _PlaylistPlaceholder extends StatelessWidget {
  const _PlaylistPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FluxApp.accentColor.withValues(alpha: 0.3),
      child: const Icon(Icons.music_note, color: FluxApp.accentColor),
    );
  }
}

