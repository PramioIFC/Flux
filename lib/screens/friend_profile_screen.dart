import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../providers/flux_provider.dart';
import 'playlist_detail_screen.dart';

class FriendProfileScreen extends StatelessWidget {
  final String friendId;
  final String username;

  const FriendProfileScreen({
    super.key,
    required this.friendId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluxApp.backgroundColor,
      appBar: AppBar(
        title: Text(username),
        backgroundColor: FluxApp.surfaceColor,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: Provider.of<FluxProvider>(context, listen: false).getFriendData(friendId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FluxApp.accentColor));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Não foi possível carregar o perfil.', style: TextStyle(color: FluxApp.secondaryTextColor)),
            );
          }

          final data = snapshot.data!;
          final isPublic = data['is_public'] ?? false;
          
          if (!isPublic) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: FluxApp.secondaryTextColor),
                  const SizedBox(height: 16),
                  Text(
                    'As playlists deste usuário são privadas.',
                    style: GoogleFonts.inter(color: FluxApp.secondaryTextColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final playlistsJson = data['playlists_json'] as Map<String, dynamic>? ?? {};
          final playlists = playlistsJson.map((key, value) {
            return MapEntry(
              key,
              (value as List).map((item) => Map<String, String>.from(item)).toList(),
            );
          });

          if (playlists.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma playlist encontrada.',
                style: GoogleFonts.inter(color: FluxApp.secondaryTextColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlistName = playlists.keys.elementAt(index);
              final tracks = playlists.values.elementAt(index);
              
              String? coverUrl;
              if (tracks.isNotEmpty && tracks.first['album_image_url'] != null) {
                coverUrl = tracks.first['album_image_url'];
              }

              return Card(
                color: FluxApp.cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: coverUrl != null && coverUrl.isNotEmpty
                          ? Image.network(coverUrl, fit: BoxFit.cover)
                          : Container(color: FluxApp.accentColor.withValues(alpha: 0.3), child: const Icon(Icons.music_note, color: FluxApp.accentColor)),
                    ),
                  ),
                  title: Text(playlistName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${tracks.length} músicas', style: const TextStyle(color: FluxApp.secondaryTextColor)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlistName: '$username - $playlistName',
                          tracks: tracks,
                          readOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
