import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/flux_provider.dart';
import '../main.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FluxApp.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FluxApp.secondaryTextColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fila de Reprodução',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: FluxApp.secondaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<FluxProvider>(
              builder: (context, provider, child) {
                final queue = provider.currentQueue;
                if (queue.isEmpty) {
                  return Center(
                    child: Text(
                      'A fila está vazia',
                      style: GoogleFonts.inter(color: FluxApp.secondaryTextColor),
                    ),
                  );
                }

                final currentIndex = provider.player.currentIndex ?? 0;

                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  onReorderItem: (oldIndex, newIndex) {
                    provider.reorderQueue(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FluxApp.cardColor.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final track = queue[index];
                    final isCurrent = index == currentIndex;
                    final isPast = index < currentIndex;

                    // Criar chave única para cada item na lista
                    final uniqueKey = '${track['media_id'] ?? track['track_name']}_$index';

                    return Dismissible(
                      key: ValueKey('dismiss_$uniqueKey'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        provider.removeFromQueue(index);
                      },
                      child: ListTile(
                        key: ValueKey(uniqueKey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: track['album_image_url'] != null && track['album_image_url']!.isNotEmpty
                                ? Image.network(
                                    track['album_image_url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholderArt(),
                                  )
                                : _placeholderArt(),
                          ),
                        ),
                        title: Text(
                          track['track_name'] ?? 'Música Desconhecida',
                          style: GoogleFonts.inter(
                            color: isCurrent ? FluxApp.accentColor : (isPast ? FluxApp.secondaryTextColor : Colors.white),
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track['artist'] ?? 'Artista Desconhecido',
                          style: GoogleFonts.inter(
                            color: isPast ? FluxApp.secondaryTextColor.withValues(alpha: 0.5) : FluxApp.secondaryTextColor,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCurrent)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.volume_up_rounded, color: FluxApp.accentColor, size: 20),
                              ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: FluxApp.secondaryTextColor.withValues(alpha: 0.5),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Allow skipping to this track
                          if (provider.player.currentIndex != index) {
                            provider.player.seek(Duration.zero, index: index);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      color: FluxApp.cardColor,
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: FluxApp.secondaryTextColor,
        ),
      ),
    );
  }
}
