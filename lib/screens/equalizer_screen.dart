import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/equalizer_service.dart';
import '../main.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<EqualizerService>(context),
      child: const _EqualizerScreenContent(),
    );
  }
}

class _EqualizerScreenContent extends StatefulWidget {
  const _EqualizerScreenContent();

  @override
  State<_EqualizerScreenContent> createState() => _EqualizerScreenContentState();
}

class _EqualizerScreenContentState extends State<_EqualizerScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqService = Provider.of<EqualizerService>(context);

    return Scaffold(
      backgroundColor: FluxApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'EQUALIZER',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: FluxApp.secondaryTextColor),
            tooltip: 'Reset to Flat',
            onPressed: () => eqService.resetToFlat(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // --- Enable/Disable Toggle ---
            _buildToggleCard(eqService),
            const SizedBox(height: 20),

            // --- EQ Visualizer Bands ---
            AnimatedOpacity(
              opacity: eqService.isEnabled ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 300),
              child: AbsorbPointer(
                absorbing: !eqService.isEnabled,
                child: Column(
                  children: [
                    _buildEqualizerBands(eqService),
                    const SizedBox(height: 24),

                    // --- Presets Grid ---
                    _buildPresetsSection(eqService),
                    const SizedBox(height: 24),

                    // --- Volume Normalization ---
                    _buildNormalizationCard(eqService),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(EqualizerService eqService) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: eqService.isEnabled
            ? LinearGradient(
                colors: [
                  FluxApp.accentColor.withValues(alpha: 0.2),
                  FluxApp.accentColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: eqService.isEnabled ? null : FluxApp.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: eqService.isEnabled
              ? FluxApp.accentColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: eqService.isEnabled
                  ? FluxApp.accentColor.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.equalizer_rounded,
              color: eqService.isEnabled ? FluxApp.accentColor : FluxApp.secondaryTextColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Equalizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eqService.isEnabled
                      ? (eqService.isCustom ? 'Custom' : eqService.selectedPreset.name)
                      : 'Disabled',
                  style: TextStyle(
                    color: FluxApp.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: eqService.isEnabled,
            onChanged: (_) => eqService.toggleEnabled(),
            activeThumbColor: FluxApp.accentColor,
            inactiveThumbColor: FluxApp.secondaryTextColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizerBands(EqualizerService eqService) {
    final bands = eqService.currentBands;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: FluxApp.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // dB labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('+12dB', style: TextStyle(fontSize: 10, color: FluxApp.secondaryTextColor.withValues(alpha: 0.6))),
                Text('0dB', style: TextStyle(fontSize: 10, color: FluxApp.secondaryTextColor.withValues(alpha: 0.6))),
                Text('-12dB', style: TextStyle(fontSize: 10, color: FluxApp.secondaryTextColor.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sliders
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (i) {
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              activeTrackColor: _getBandColor(bands[i]),
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                              thumbColor: _getBandColor(bands[i]),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              overlayColor: FluxApp.accentColor.withValues(alpha: 0.1),
                            ),
                            child: Slider(
                              value: bands[i],
                              min: -12.0,
                              max: 12.0,
                              onChanged: (val) => eqService.setBand(i, val),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        EqualizerService.bandLabels[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: FluxApp.secondaryTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBandColor(double value) {
    if (value.abs() < 1) return FluxApp.secondaryTextColor;
    if (value > 0) {
      final t = (value / 12.0).clamp(0.0, 1.0);
      return Color.lerp(FluxApp.accentColor, const Color(0xFF06B6D4), t)!;
    } else {
      final t = (value.abs() / 12.0).clamp(0.0, 1.0);
      return Color.lerp(FluxApp.accentColor, const Color(0xFFF59E0B), t)!;
    }
  }

  Widget _buildPresetsSection(EqualizerService eqService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRESETS',
          style: TextStyle(
            color: FluxApp.secondaryTextColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: EqualizerService.presets.length,
          itemBuilder: (context, index) {
            final preset = EqualizerService.presets[index];
            final isSelected = !eqService.isCustom && eqService.selectedPresetIndex == index;

            return GestureDetector(
              onTap: () => eqService.selectPreset(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected
                      ? FluxApp.accentColor.withValues(alpha: 0.15)
                      : FluxApp.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? FluxApp.accentColor.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.05),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      preset.icon,
                      size: 16,
                      color: isSelected ? FluxApp.accentColor : FluxApp.secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? FluxApp.accentColor : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNormalizationCard(EqualizerService eqService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: FluxApp.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: eqService.volumeNormalization
                  ? FluxApp.accentColor.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.volume_up_rounded,
              color: eqService.volumeNormalization ? FluxApp.accentColor : FluxApp.secondaryTextColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volume Normalization',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consistent loudness across all tracks',
                  style: TextStyle(
                    color: FluxApp.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: eqService.volumeNormalization,
            onChanged: (_) => eqService.toggleVolumeNormalization(),
            activeThumbColor: FluxApp.accentColor,
            inactiveThumbColor: FluxApp.secondaryTextColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}
