import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/flux_provider.dart';
import 'lyrics_view.dart';
import 'queue_screen.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FluxProvider>();
    final track = provider.currentTrack;
    if (track == null) {
      return const Scaffold(body: Center(child: Text('Escolha uma faixa do catálogo demo.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPRODUZINDO'),
        centerTitle: true,
        actions: [IconButton(
          tooltip: 'Fila', icon: const Icon(Icons.queue_music),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())),
        )],
      ),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const Spacer(),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
            decoration: BoxDecoration(
              color: FluxApp.cardColor,
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF1E1E2E)]),
            ),
            child: const AspectRatio(aspectRatio: 1, child: Icon(Icons.music_note, size: 120, color: FluxApp.accentColor)),
          ),
          const Spacer(),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track['track_name']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(track['artist']!, style: const TextStyle(color: FluxApp.secondaryTextColor, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            IconButton(
              icon: Icon(provider.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
                color: provider.isFavorite(track) ? FluxApp.accentColor : Colors.white),
              onPressed: () => provider.toggleFavorite(track),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.verified_outlined, color: FluxApp.accentColor, size: 18),
            const SizedBox(width: 6),
            Text(track['license_name']!, style: const TextStyle(color: FluxApp.secondaryTextColor)),
          ]),
          const SizedBox(height: 20),
          StreamBuilder<Duration?>(
            stream: provider.player.durationStream,
            builder: (_, durationSnapshot) => StreamBuilder<Duration>(
              stream: provider.player.positionStream,
              builder: (_, positionSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                final position = positionSnapshot.data ?? Duration.zero;
                final max = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity).toDouble();
                return Column(children: [
                  Slider(
                    value: position.inMilliseconds.toDouble().clamp(0.0, max).toDouble(), max: max,
                    onChanged: (value) => provider.player.seek(Duration(milliseconds: value.round())),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(_time(position)), Text(_time(duration))]),
                ]);
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(icon: Icon(Icons.shuffle, color: provider.isShuffled ? FluxApp.accentColor : Colors.white70),
              onPressed: provider.toggleShuffle),
            IconButton(iconSize: 44, icon: const Icon(Icons.skip_previous), onPressed: provider.skipPrevious),
            StreamBuilder<bool>(
              stream: provider.player.playingStream,
              builder: (_, snapshot) => FloatingActionButton.large(
                backgroundColor: FluxApp.accentColor,
                onPressed: () => snapshot.data == true ? provider.player.pause() : provider.player.play(),
                child: Icon(snapshot.data == true ? Icons.pause : Icons.play_arrow, size: 44),
              ),
            ),
            IconButton(iconSize: 44, icon: const Icon(Icons.skip_next), onPressed: provider.skipNext),
            IconButton(
              icon: Icon(provider.repeatMode == PlaybackRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                color: provider.repeatMode == PlaybackRepeatMode.off ? Colors.white70 : FluxApp.accentColor),
              onPressed: provider.toggleRepeatMode,
            ),
          ]),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LyricsView())),
            icon: const Icon(Icons.lyrics_outlined), label: const Text('Ver letras e créditos'),
          ),
        ]),
      )),
    );
  }
}
