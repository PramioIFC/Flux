import 'package:flux/services/demo_catalog_service.dart';

void main() {
  final ids = <String>{};
  for (final track in DemoCatalogService.tracks) {
    const requiredFields = [
      'media_id',
      'track_name',
      'artist',
      'audio_url',
      'source_url',
      'license_name',
      'license_url',
    ];
    for (final field in requiredFields) {
      if ((track[field] ?? '').trim().isEmpty) {
        throw StateError('Campo $field ausente em ${track['media_id']}');
      }
    }
    if (!ids.add(track['media_id']!)) {
      throw StateError('Identificador duplicado: ${track['media_id']}');
    }
    for (final field in ['audio_url', 'source_url', 'license_url']) {
      final uri = Uri.parse(track[field]!);
      if (uri.scheme != 'https' || uri.host.isEmpty) {
        throw StateError('URL não segura em ${track['media_id']}: $field');
      }
    }
    if (!DemoCatalogService.isAllowed(track)) {
      throw StateError('Faixa rejeitada pela própria lista de permissão.');
    }
  }
}
