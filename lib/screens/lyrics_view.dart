import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flux_provider.dart';
import '../providers/lyrics.dart';
import '../main.dart';

class LyricLine {
  final Duration time;
  final String text;
  LyricLine(this.time, this.text);
}

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;
  bool _showTranslation = false;
  String _translationLanguage = 'en';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<LyricLine> _parseLyrics(String lyricsStr) {
    List<LyricLine> lines = [];
    final RegExp regex = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');
    for (var line in lyricsStr.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();
        final time = Duration(milliseconds: (minutes * 60000 + seconds * 1000).round());
        if (text.isNotEmpty) {
          lines.add(LyricLine(time, text));
        }
      }
    }
    return lines;
  }

  int _getActiveLineIndex(Duration pos, List<LyricLine> lines) {
    for (int i = lines.length - 1; i >= 0; i--) {
      if (pos >= lines[i].time) {
        return i;
      }
    }
    return -1;
  }

  void _scrollToIndex(int index, int totalLines) {
    if (index == _lastActiveIndex || index < 0 || !_scrollController.hasClients) return;
    _lastActiveIndex = index;
    
    // Approximate scroll position to center the line
    final targetOffset = (index * 70.0) - (MediaQuery.of(context).size.height / 2) + 100;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FluxProvider>(context);
    final track = provider.currentTrack;

    if (track == null) return const Scaffold(body: Center(child: Text("Sem música")));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              track['track_name'] ?? 'Letras',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track['artist'] ?? '',
              style: TextStyle(fontSize: 11, color: FluxApp.secondaryTextColor),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Translation toggle
          PopupMenuButton<String>(
            icon: Icon(
              Icons.translate_rounded,
              color: _showTranslation ? FluxApp.accentColor : FluxApp.secondaryTextColor,
            ),
            color: FluxApp.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (code) {
              setState(() {
                if (code == 'off') {
                  _showTranslation = false;
                } else {
                  _showTranslation = true;
                  _translationLanguage = code;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'off',
                child: Row(
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: !_showTranslation ? FluxApp.accentColor : FluxApp.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    const Text('Original'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ..._languages.map((lang) => PopupMenuItem(
                value: lang['code'],
                child: Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 18,
                      color: _showTranslation && _translationLanguage == lang['code']
                          ? FluxApp.accentColor
                          : FluxApp.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(lang['name']!),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              provider.dominantColor.withValues(alpha: 0.5),
              FluxApp.backgroundColor.withValues(alpha: 0.95),
              FluxApp.backgroundColor,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: Lyrics().getLyrics(
            mediaId: track['media_id'] ?? '',
            title: track['track_name'] ?? '',
            durationInSeconds: provider.player.duration?.inSeconds ?? 0,
            artist: track['artist'],
            translation: _showTranslation ? _translationLanguage : null,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: FluxApp.accentColor));
            }
            if (!snapshot.hasData || snapshot.data!['success'] == false) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lyrics_outlined, size: 48, color: FluxApp.secondaryTextColor.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text(
                      "Letras não encontradas.",
                      style: TextStyle(color: FluxApp.secondaryTextColor, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final lyricsData = snapshot.data!;
            final String syncedLyrics = lyricsData['syncedLyrics'] ?? "";
            final String plainLyrics = lyricsData['plainLyrics'] ?? "";
            final String transLyrics = lyricsData['transLyrics'] ?? "";

            // Synced lyrics with translation support
            if (syncedLyrics.isNotEmpty && syncedLyrics.contains('[')) {
              final lines = _parseLyrics(syncedLyrics);
              final transLines = _showTranslation && transLyrics.isNotEmpty
                  ? _parseLyrics(transLyrics)
                  : <LyricLine>[];

              if (lines.isNotEmpty) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: StreamBuilder<Duration>(
                    stream: provider.player.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final activeIndex = _getActiveLineIndex(position, lines);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToIndex(activeIndex, lines.length);
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: MediaQuery.of(context).size.height / 2 - 80,
                        ),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final isActive = index == activeIndex;
                          final isPast = index < activeIndex;

                          return GestureDetector(
                            onTap: () {
                              // Tap to seek to this line
                              provider.player.seek(lines[index].time);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  // Original lyric line
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      fontSize: isActive ? 26 : 18,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : (isPast ? Colors.white24 : Colors.white54),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                    child: Text(
                                      lines[index].text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Translation line
                                  if (_showTranslation && index < transLines.length)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 300),
                                        style: TextStyle(
                                          fontSize: isActive ? 16 : 13,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                          color: isActive
                                              ? FluxApp.accentColor.withValues(alpha: 0.8)
                                              : (isPast
                                                  ? FluxApp.accentColor.withValues(alpha: 0.15)
                                                  : FluxApp.accentColor.withValues(alpha: 0.35)),
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                        child: Text(
                                          transLines[index].text,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }
            }

            // Fallback plain lyrics
            return FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
                child: Text(
                  plainLyrics,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.8, color: Colors.white70),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
