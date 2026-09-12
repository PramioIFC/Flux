import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../main.dart';
import '../providers/flux_provider.dart';
import '../services/demo_catalog_service.dart';
import 'playlist_detail_screen.dart';
import 'dart:io' if (dart.library.html) 'dart_io_stub.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  String _sortMode = 'A-Z'; // 'A-Z', 'Z-A'

  Map<String, String>? _normalizeImportedTrack(dynamic rawTrack) {
    if (rawTrack is! Map) return null;

    Map<dynamic, dynamic> track = rawTrack;
    final nestedTrack = rawTrack['track'];
    if (nestedTrack is Map) track = nestedTrack;

    String normalizedKey(dynamic key) => key
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    dynamic findValue(List<String> aliases) {
      final wanted = aliases.map(normalizedKey).toSet();
      for (final entry in track.entries) {
        if (wanted.contains(normalizedKey(entry.key))) return entry.value;
      }
      return null;
    }

    String textValue(dynamic value) {
      if (value == null) return '';
      if (value is List) {
        return value
            .map((item) => item is Map ? item['name'] : item)
            .where((item) => item != null && item.toString().trim().isNotEmpty)
            .map((item) => item.toString().trim())
            .join(', ');
      }
      return value.toString().trim();
    }

    final title = textValue(
      findValue([
        'track_name', 'trackName', 'name', 'title', 'song',
        // Portuguese Spotify exports
        'Nome da faixa',
      ]),
    );
    if (title.isEmpty) return null;

    final artist = textValue(
      findValue([
        'artist', 'artists', 'artist_name', 'artistName',
        // Portuguese Spotify exports
        'Nome(s) do artista', 'Nome do artista',
        // English Spotify exports
        'Artist Name(s)', 'Artist Name',
      ]),
    );
    var image = textValue(
      findValue([
        'album_image_url',
        'albumImageUrl',
        'image_url',
        'image',
        'cover',
        'thumbnail',
        // Portuguese Spotify exports
        'URL da imagem do álbum',
        // English Spotify exports
        'Album Image URL',
      ]),
    );

    if (image.isEmpty && track['album'] is Map) {
      final images = (track['album'] as Map)['images'];
      if (images is List && images.isNotEmpty && images.first is Map) {
        image = textValue((images.first as Map)['url']);
      }
    }

    for (final allowed in DemoCatalogService.tracks) {
      if (allowed['track_name']!.toLowerCase() == title.toLowerCase() &&
          (artist.isEmpty || allowed['artist']!.toLowerCase().contains(artist.toLowerCase()))) {
        return Map<String, String>.from(allowed);
      }
    }
    return null;
  }

  List<Map<String, String>> _normalizeImportedTracks(
    List<dynamic> rawTracks,
  ) {
    return rawTracks
        .map(_normalizeImportedTrack)
        .whereType<Map<String, String>>()
        .toList();
  }

  Future<void> _renamePlaylist(
      BuildContext context, String oldName, FluxProvider provider) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Renomear Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Novo nome...",
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Salvar",
                style: TextStyle(color: FluxApp.accentColor)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      provider.renamePlaylist(oldName, newName);
    }
  }

  Future<String?> _showNameDialog(
      BuildContext context, String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Nome da Playlist"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Digite o nome aqui...",
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FluxApp.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(
              "Importar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, FluxProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nova Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome da playlist...',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createPlaylist(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Criar',
                style: TextStyle(color: FluxApp.accentColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _importJsonPlaylist(
    BuildContext context,
    FluxProvider provider,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null) {
        String jsonString;
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes == null) throw Exception("Erro ao ler bytes");
          jsonString = utf8.decode(bytes);
        } else {
          final path = result.files.single.path;
          if (path == null) throw Exception("Caminho não encontrado");
          jsonString = await File(path).readAsString();
        }

        final dynamic decodedData = json.decode(jsonString);

        int importedCount = 0;
        int rejectedCount = 0;

        if (decodedData is Map<String, dynamic>) {
          final Map<String, List<Map<String, String>>> importData = {};
          decodedData.forEach((key, value) {
            if (value is List) {
              final tracks = _normalizeImportedTracks(value);
              rejectedCount += value.length - tracks.length;
              if (tracks.isNotEmpty) {
                importData[key] = tracks;
                importedCount += tracks.length;
              }
            }
          });
          if (importData.isEmpty) {
            throw const FormatException(
              'Nenhuma música válida. Verifique track_name/title e artist.',
            );
          }
          provider.importPlaylistsData(importData);
        } else if (decodedData is List) {
          final fileName = result.files.single.name.replaceAll('.json', '');
          if (!context.mounted) return;
          final String? playlistName =
              await _showNameDialog(context, fileName);

          if (playlistName != null && playlistName.isNotEmpty) {
            final tracks = _normalizeImportedTracks(decodedData);
            rejectedCount = decodedData.length - tracks.length;
            if (tracks.isEmpty) {
              throw const FormatException(
                'Nenhuma música válida. Verifique track_name/title e artist.',
              );
            }

            provider.importPlaylistsData({playlistName: tracks});
            importedCount = tracks.length;
          } else {
            return;
          }
        } else {
          throw const FormatException('Formato de JSON não reconhecido.');
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rejectedCount > 0
                  ? '$importedCount músicas importadas; $rejectedCount inválidas ignoradas.'
                  : '$importedCount músicas importadas com sucesso.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro: $e"),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FluxProvider>(context);

    var playlistNames = provider.playlists.keys.toList();
    if (_searchQuery.isNotEmpty) {
      playlistNames = playlistNames.where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    playlistNames.sort((a, b) {
      final aPinned = provider.isPinned(a);
      final bPinned = provider.isPinned(b);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      
      if (_sortMode == 'A-Z') {
        return a.toLowerCase().compareTo(b.toLowerCase());
      } else {
        return b.toLowerCase().compareTo(a.toLowerCase());
      }
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // --- SEARCH BAR AND SORT ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Buscar playlist...",
                    hintStyle: const TextStyle(color: FluxApp.secondaryTextColor),
                    prefixIcon: const Icon(Icons.search, color: FluxApp.secondaryTextColor),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortMode,
                dropdownColor: FluxApp.cardColor,
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                icon: const Icon(Icons.sort, color: FluxApp.secondaryTextColor),
                items: const [
                  DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
                  DropdownMenuItem(value: 'Z-A', child: Text('Z-A')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortMode = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // --- ACTION BUTTONS ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_rounded,
                  label: "Criar Playlist",
                  onPressed: () =>
                      _showCreatePlaylistDialog(context, provider),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.file_upload_outlined,
                  label: "Importar JSON",
                  onPressed: () => _importJsonPlaylist(context, provider),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
              height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ),
        if (provider.playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.library_music_outlined,
                      size: 64,
                      color: FluxApp.secondaryTextColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    "Nenhuma playlist ainda.\nCrie uma nova ou importe um .json!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FluxApp.secondaryTextColor),
                  ),
                ],
              ),
            ),
          )
        else
          ...playlistNames.map((name) {
            final tracks = provider.playlists[name]!;
            final String? imageUrl = provider.getPlaylistCover(name);
            final isPinned = provider.isPinned(name);

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? _buildCoverImage(imageUrl)
                      : const _LibraryPlaceholder(),
                ),
              ),
              title: Row(
                children: [
                  if (isPinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 14, color: FluxApp.accentColor)),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                "${tracks.length} música${tracks.length != 1 ? 's' : ''}",
                style: const TextStyle(
                  color: FluxApp.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                color: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'rename') {
                    _renamePlaylist(context, name, provider);
                  } else if (value == 'delete') {
                    provider.deletePlaylist(name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Playlist '\$name' apagada"),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else if (value == 'pin') {
                    provider.togglePin(name);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: ListTile(
                      leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 20),
                      title: Text(isPinned ? 'Desafixar' : 'Fixar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined, size: 20),
                      title: Text('Renomear'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      title: Text('Apagar',
                          style: TextStyle(color: Colors.redAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailScreen(
                      playlistName: name,
                      tracks: tracks,
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }
  Widget _buildCoverImage(String url) {
    if (!url.startsWith('https://')) {
      return const _LibraryPlaceholder();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _LibraryPlaceholder(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FluxApp.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: FluxApp.accentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: FluxApp.primaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryPlaceholder extends StatelessWidget {
  const _LibraryPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FluxApp.cardColor,
            FluxApp.accentColor.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: const Icon(Icons.library_music_rounded,
          color: FluxApp.accentColor, size: 24),
    );
  }
}
