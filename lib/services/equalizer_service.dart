import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single equalizer preset with 10 frequency bands.
class EQPreset {
  final String name;
  final IconData icon;
  final List<double> bands; // 10 bands: 31Hz, 62Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz

  const EQPreset({
    required this.name,
    required this.icon,
    required this.bands,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'bands': bands,
  };
}

class EqualizerService extends ChangeNotifier {
  static const List<String> bandLabels = [
    '31', '62', '125', '250', '500', '1K', '2K', '4K', '8K', '16K'
  ];

  // --- Built-in presets ---
  static const List<EQPreset> presets = [
    EQPreset(
      name: 'Flat',
      icon: Icons.horizontal_rule_rounded,
      bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    EQPreset(
      name: 'Bass Boost',
      icon: Icons.speaker_rounded,
      bands: [6, 5, 4, 3, 1, 0, 0, 0, 0, 0],
    ),
    EQPreset(
      name: 'Treble Boost',
      icon: Icons.graphic_eq_rounded,
      bands: [0, 0, 0, 0, 0, 1, 2, 4, 5, 6],
    ),
    EQPreset(
      name: 'Rock',
      icon: Icons.music_note_rounded,
      bands: [5, 4, 3, 1, -1, -1, 1, 3, 4, 5],
    ),
    EQPreset(
      name: 'Pop',
      icon: Icons.star_rounded,
      bands: [-1, -1, 0, 2, 4, 4, 2, 0, -1, -1],
    ),
    EQPreset(
      name: 'Jazz',
      icon: Icons.piano_rounded,
      bands: [3, 2, 1, 2, -1, -1, 0, 1, 2, 3],
    ),
    EQPreset(
      name: 'Classical',
      icon: Icons.library_music_rounded,
      bands: [4, 3, 2, 1, -1, -1, 0, 2, 3, 4],
    ),
    EQPreset(
      name: 'Hip Hop',
      icon: Icons.headphones_rounded,
      bands: [5, 4, 1, 3, -1, -1, 1, 0, 1, 3],
    ),
    EQPreset(
      name: 'Electronic',
      icon: Icons.bolt_rounded,
      bands: [4, 3, 1, 0, -2, -1, 0, 3, 4, 5],
    ),
    EQPreset(
      name: 'R&B',
      icon: Icons.nightlife_rounded,
      bands: [3, 6, 4, 1, -2, -1, 2, 3, 2, 3],
    ),
    EQPreset(
      name: 'Acoustic',
      icon: Icons.forest_rounded,
      bands: [3, 2, 0, 1, 2, 2, 2, 3, 2, 1],
    ),
    EQPreset(
      name: 'Vocal',
      icon: Icons.mic_rounded,
      bands: [-2, -1, 0, 2, 5, 5, 3, 1, 0, -1],
    ),
  ];

  // --- State ---
  bool _isEnabled = false;
  int _selectedPresetIndex = 0;
  List<double> _customBands = List.filled(10, 0.0);
  bool _isCustom = false;

  // --- Volume Normalization ---
  bool _volumeNormalization = false;

  // --- Getters ---
  bool get isEnabled => _isEnabled;
  int get selectedPresetIndex => _selectedPresetIndex;
  EQPreset get selectedPreset => presets[_selectedPresetIndex];
  List<double> get currentBands => _isCustom ? List.from(_customBands) : List.from(presets[_selectedPresetIndex].bands);
  bool get isCustom => _isCustom;
  bool get volumeNormalization => _volumeNormalization;

  EqualizerService() {
    _loadSettings();
  }

  // --- Actions ---
  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    _saveSettings();
    notifyListeners();
  }

  void selectPreset(int index) {
    if (index < 0 || index >= presets.length) return;
    _selectedPresetIndex = index;
    _isCustom = false;
    _customBands = List.from(presets[index].bands);
    _saveSettings();
    notifyListeners();
  }

  void setBand(int bandIndex, double value) {
    if (bandIndex < 0 || bandIndex >= 10) return;
    _isCustom = true;
    _customBands[bandIndex] = value.clamp(-12.0, 12.0);
    _saveSettings();
    notifyListeners();
  }

  void resetToFlat() {
    _isCustom = false;
    _selectedPresetIndex = 0;
    _customBands = List.filled(10, 0.0);
    _saveSettings();
    notifyListeners();
  }

  void toggleVolumeNormalization() {
    _volumeNormalization = !_volumeNormalization;
    _saveSettings();
    notifyListeners();
  }

  // --- Persistence ---
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eq_enabled', _isEnabled);
    await prefs.setInt('eq_preset_index', _selectedPresetIndex);
    await prefs.setString('eq_custom_bands', json.encode(_customBands));
    await prefs.setBool('eq_is_custom', _isCustom);
    await prefs.setBool('eq_volume_normalization', _volumeNormalization);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('eq_enabled') ?? false;
    _selectedPresetIndex = prefs.getInt('eq_preset_index') ?? 0;
    _isCustom = prefs.getBool('eq_is_custom') ?? false;
    _volumeNormalization = prefs.getBool('eq_volume_normalization') ?? false;

    final bandsJson = prefs.getString('eq_custom_bands');
    if (bandsJson != null) {
      try {
        final decoded = json.decode(bandsJson) as List;
        _customBands = decoded.map((e) => (e as num).toDouble()).toList();
      } catch (_) {
        _customBands = List.filled(10, 0.0);
      }
    }

    if (_selectedPresetIndex >= presets.length) _selectedPresetIndex = 0;
    notifyListeners();
  }
}
