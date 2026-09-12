import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/flux_provider.dart';
import '../services/demo_catalog_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, String>> _results = DemoCatalogService.search('');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) => setState(() => _results = DemoCatalogService.search(query));

  void _showPlaylistOptions(Map<String, String> track) {
    final provider = context.read<FluxProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FluxApp.cardColor,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Salvar em playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...provider.playlists.keys.map((name) => ListTile(
              leading: const Icon(Icons.playlist_add, color: FluxApp.accentColor),
              title: Text(name),
              onTap: () {
                provider.addTrackToPlaylist(name, track);
                Navigator.pop(sheetContext);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Buscar no catálogo demo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty ? null : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _controller.clear(); _search(''); },
              ),
              filled: true,
              fillColor: FluxApp.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? const Center(child: Text('Nenhuma faixa licenciada encontrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final track = _results[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: FluxApp.cardColor,
                        child: Icon(Icons.music_note, color: FluxApp.accentColor),
                      ),
                      title: Text(track['track_name']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${track['artist']} • ${track['license_name']}'),
                      onTap: () => context.read<FluxProvider>().playTrack(track, queue: _results),
                      trailing: Consumer<FluxProvider>(builder: (_, provider, __) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(provider.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
                              color: provider.isFavorite(track) ? FluxApp.accentColor : FluxApp.secondaryTextColor),
                            onPressed: () => provider.toggleFavorite(track),
                          ),
                          IconButton(icon: const Icon(Icons.playlist_add), onPressed: () => _showPlaylistOptions(track)),
                        ],
                      )),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
