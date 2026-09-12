/// Catálogo curado da demonstração pública.
///
/// Busca e reprodução são limitadas a esta lista de permissão. Cada gravação
/// inclui sua página de origem e a licença aplicável.
class DemoCatalogService {
  static const String publicDomainMark =
      'https://creativecommons.org/publicdomain/mark/1.0/';

  static const List<Map<String, String>> tracks = [
    {
      'media_id': 'olympic-anthem',
      'track_name': 'Olympic Hymn',
      'artist': 'Spyridon Samaras',
      'album_image_url': '',
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Olympic_Anthem.ogg',
      'source_url': 'https://commons.wikimedia.org/wiki/File:Olympic_Anthem.ogg',
      'license_name': 'Public Domain',
      'license_url': publicDomainMark,
    },
    {
      'media_id': 'oh-susanna',
      'track_name': 'Oh! Susanna',
      'artist': 'Stephen Foster / United States Navy Band',
      'album_image_url': '',
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/c/c3/Oh_Susanna.ogg',
      'source_url': 'https://commons.wikimedia.org/wiki/File:Oh_Susanna.ogg',
      'license_name': 'Public Domain - U.S. Government Work',
      'license_url': publicDomainMark,
    },
    {
      'media_id': 'douglas-munro-march',
      'track_name': 'Douglas Munro March',
      'artist': 'United States Coast Guard Band',
      'album_image_url': '',
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/8/88/Douglas_Munro_March.ogg',
      'source_url': 'https://commons.wikimedia.org/wiki/File:Douglas_Munro_March.ogg',
      'license_name': 'Public Domain - U.S. Government Work',
      'license_url': publicDomainMark,
    },
    {
      'media_id': 'gnossienne-6',
      'track_name': 'Gnossienne No. 6',
      'artist': 'Erik Satie / La Pianista',
      'album_image_url': '',
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/2/2b/Gnossienne_6_%28Satie%29.ogg',
      'source_url': 'https://commons.wikimedia.org/wiki/File:Gnossienne_6_(Satie).ogg',
      'license_name': 'CC BY-SA 3.0 performance; composition in Public Domain',
      'license_url': 'https://creativecommons.org/licenses/by-sa/3.0/',
    },
    {
      'media_id': 'little-maid-of-arcadee',
      'track_name': 'Little Maid of Arcadee',
      'artist': 'Gilbert and Sullivan / community performance',
      'album_image_url': '',
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Little_Maid_of_Arcadee.ogg',
      'source_url': 'https://commons.wikimedia.org/wiki/File:Little_Maid_of_Arcadee.ogg',
      'license_name': 'Public Domain',
      'license_url': publicDomainMark,
    },
    {
      'media_id': 'that-baseball-rag',
      'track_name': 'That Baseball Rag',
      'artist': 'Arthur Collins (1913 recording)',
      'album_image_url': '',
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/b/bd/That_Baseball_Rag_by_Arthur_Collins_%281913%29.ogg',
      'source_url': 'https://commons.wikimedia.org/wiki/File:That_Baseball_Rag_by_Arthur_Collins_(1913).ogg',
      'license_name': 'Public Domain',
      'license_url': publicDomainMark,
    },
  ];

  static List<Map<String, String>> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return tracks.map(Map<String, String>.from).toList();
    }
    return tracks
        .where((track) =>
            track['track_name']!.toLowerCase().contains(normalized) ||
            track['artist']!.toLowerCase().contains(normalized))
        .map(Map<String, String>.from)
        .toList();
  }

  static bool isAllowed(Map<String, String> track) => tracks.any(
        (item) =>
            item['media_id'] == track['media_id'] &&
            item['audio_url'] == track['audio_url'],
      );
}
