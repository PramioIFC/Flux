import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/flux_provider.dart';
import '../widgets/mini_player_bar.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  final List<Map<String, String>> tracks;
  final bool readOnly;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.tracks,
    this.readOnly = false,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final _searchController = TextEditingController();
  late List<Map<String, String>> _visible;

  @override
  void initState() {
    super.initState();
    _visible = List.of(widget.tracks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() => _visible = widget.tracks.where((track) =>
      q.isEmpty || track['track_name']!.toLowerCase().contains(q) ||
      track['artist']!.toLowerCase().contains(q)).toList());
  }

  void _options(Map<String, String> track, FluxProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FluxApp.cardColor,
      builder: (sheetContext) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: FluxApp.accentColor),
            title: Text(track['license_name'] ?? 'Licença da faixa'),
            subtitle: const Text('A origem e a licença estão registradas no catálogo do projeto.'),
          ),
          ListTile(
            leading: Icon(provider.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
              color: FluxApp.accentColor),
            title: Text(provider.isFavorite(track) ? 'Remover das favoritas' : 'Adicionar às favoritas'),
            onTap: () { provider.toggleFavorite(track); Navigator.pop(sheetContext); },
          ),
          if (!widget.readOnly)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              title: const Text('Remover desta playlist'),
              onTap: () {
                provider.removeFromPlaylist(widget.playlistName, track);
                setState(() { widget.tracks.remove(track); _visible.remove(track); });
                Navigator.pop(sheetContext);
              },
            ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FluxProvider>(builder: (context, provider, _) => Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        actions: [
          if (!widget.readOnly) IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              provider.deletePlaylist(widget.playlistName);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: _visible.isEmpty ? null : () => provider.playPlaylist(_visible),
                icon: const Icon(Icons.play_arrow), label: const Text('Tocar'),
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(
                onPressed: _visible.isEmpty ? null : () => provider.playPlaylist(_visible, shuffle: true),
                icon: const Icon(Icons.shuffle), label: const Text('Aleatório'),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filtrar playlist...'),
            ),
          ]),
        ),
        Expanded(child: _visible.isEmpty
          ? const Center(child: Text('Nenhuma faixa licenciada nesta playlist.'))
          : ListView.builder(
              itemCount: _visible.length,
              itemBuilder: (context, index) {
                final track = _visible[index];
                final active = provider.currentTrack?['media_id'] == track['media_id'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: FluxApp.cardColor,
                    child: Icon(Icons.music_note, color: active ? FluxApp.accentColor : FluxApp.secondaryTextColor),
                  ),
                  title: Text(track['track_name']!, style: TextStyle(color: active ? FluxApp.accentColor : Colors.white)),
                  subtitle: Text('${track['artist']} • ${track['license_name']}'),
                  onTap: () => provider.playTrack(track, queue: _visible),
                  trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _options(track, provider)),
                );
              },
            )),
        const SafeArea(top: false, child: MiniPlayerBar()),
      ]),
    ));
  }
}
