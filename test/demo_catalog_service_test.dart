import 'package:flutter_test/flutter_test.dart';
import 'package:flux/services/demo_catalog_service.dart';

void main() {
  test('catalog has unique, licensed HTTPS entries', () {
    final ids = <String>{};
    expect(DemoCatalogService.tracks, isNotEmpty);

    for (final track in DemoCatalogService.tracks) {
      expect(ids.add(track['media_id']!), isTrue);
      for (final field in [
        'track_name',
        'artist',
        'audio_url',
        'source_url',
        'license_name',
        'license_url',
      ]) {
        expect(track[field], isNotEmpty, reason: '$field em ${track['media_id']}');
      }
      expect(Uri.parse(track['audio_url']!).scheme, 'https');
      expect(Uri.parse(track['source_url']!).scheme, 'https');
      expect(Uri.parse(track['license_url']!).scheme, 'https');
      expect(DemoCatalogService.isAllowed(track), isTrue);
    }
  });

  test('search only returns entries from the allowlist', () {
    final results = DemoCatalogService.search('satie');
    expect(results, hasLength(1));
    expect(results.single['media_id'], 'gnossienne-6');
    expect(results.every(DemoCatalogService.isAllowed), isTrue);
  });

  test('tampered media URL is rejected', () {
    final track = Map<String, String>.from(DemoCatalogService.tracks.first)
      ..['audio_url'] = 'https://example.com/unapproved.ogg';
    expect(DemoCatalogService.isAllowed(track), isFalse);
  });
}
