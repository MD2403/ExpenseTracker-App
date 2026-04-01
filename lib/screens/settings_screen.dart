import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _provider = ThemeProvider.instance;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _provider.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = _provider.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Theme Mode ──────────────────────────────
          _SectionHeader(title: 'Theme'),
          const SizedBox(height: 12),
          Row(
            children: [
              _ThemeModeCard(
                icon: Icons.light_mode,
                label: 'Light',
                selected: _provider.themeMode == ThemeMode.light,
                onTap: () => _provider.setThemeMode(ThemeMode.light),
                accent: accent,
              ),
              const SizedBox(width: 10),
              _ThemeModeCard(
                icon: Icons.dark_mode,
                label: 'Dark',
                selected: _provider.themeMode == ThemeMode.dark,
                onTap: () => _provider.setThemeMode(ThemeMode.dark),
                accent: accent,
              ),
              const SizedBox(width: 10),
              _ThemeModeCard(
                icon: Icons.phone_android,
                label: 'System',
                selected: _provider.themeMode == ThemeMode.system,
                onTap: () => _provider.setThemeMode(ThemeMode.system),
                accent: accent,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Accent Color ────────────────────────────
          _SectionHeader(title: 'Accent color'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current color preview
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Selected color',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * _provider.fontScale,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Color presets
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ThemeProvider.presetColors
                      .map((color) => GestureDetector(
                            onTap: () =>
                                _provider.setAccentColor(color),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: accent == color
                                    ? Border.all(
                                        color: scheme.onSurface,
                                        width: 3)
                                    : null,
                              ),
                              child: accent == color
                                  ? const Icon(Icons.check,
                                      color: Colors.white,
                                      size: 20)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Card Style ──────────────────────────────
          _SectionHeader(title: 'Card style'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: CardStyle.values.map((style) {
                final labels = {
                  CardStyle.rounded: 'Rounded',
                  CardStyle.sharp: 'Sharp',
                  CardStyle.glassmorphism: 'Glassmorphism',
                };
                final descriptions = {
                  CardStyle.rounded: 'Smooth rounded corners',
                  CardStyle.sharp: 'Clean sharp edges',
                  CardStyle.glassmorphism: 'Frosted glass effect',
                };
                final icons = {
                  CardStyle.rounded: Icons.rounded_corner,
                  CardStyle.sharp: Icons.crop_square,
                  CardStyle.glassmorphism: Icons.blur_on,
                };
                final isSelected = _provider.cardStyle == style;
                return GestureDetector(
                  onTap: () => _provider.setCardStyle(style),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.1)
                          : scheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? accent.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icons[style],
                            color: isSelected
                                ? accent
                                : scheme.onSurface.withOpacity(0.5),
                            size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(labels[style]!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14 *
                                        _provider.fontScale,
                                    color: isSelected
                                        ? accent
                                        : scheme.onSurface,
                                  )),
                              Text(descriptions[style]!,
                                  style: TextStyle(
                                    fontSize: 12 *
                                        _provider.fontScale,
                                    color: scheme.onSurface
                                        .withOpacity(0.5),
                                  )),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: accent, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // ── Font Size ───────────────────────────────
          _SectionHeader(title: 'Font size'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                Row(
                  children: FontSize.values.map((size) {
                    final labels = {
                      FontSize.small: 'Small',
                      FontSize.medium: 'Medium',
                      FontSize.large: 'Large',
                    };
                    final isSelected = _provider.fontSize == size;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _provider.setFontSize(size),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: size != FontSize.large ? 8 : 0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : scheme.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Aa',
                                style: TextStyle(
                                  fontSize: size == FontSize.small
                                      ? 14
                                      : size == FontSize.medium
                                          ? 18
                                          : 22,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                labels[size]!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white70
                                      : scheme.onSurface
                                          .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Preview
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preview',
                          style: TextStyle(
                              fontSize: 11 * _provider.fontScale,
                              color:
                                  scheme.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 4),
                      Text('Grocery — ₹450',
                          style: TextStyle(
                              fontSize: 15 * _provider.fontScale,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface)),
                      Text('Food · 25 Mar 2026',
                          style: TextStyle(
                              fontSize: 12 * _provider.fontScale,
                              color:
                                  scheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Background ──────────────────────────────
          _SectionHeader(title: 'App background'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: AppBackground.values.map((bg) {
                final labels = {
                  AppBackground.solid: 'Solid',
                  AppBackground.gradient: 'Gradient',
                  AppBackground.mesh: 'Mesh',
                };
                final descriptions = {
                  AppBackground.solid: 'Clean solid background',
                  AppBackground.gradient: 'Subtle gradient effect',
                  AppBackground.mesh: 'Colorful mesh pattern',
                };
                final isSelected = _provider.background == bg;
                return GestureDetector(
                  onTap: () => _provider.setBackground(bg),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.1)
                          : scheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? accent.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Background preview circle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bg == AppBackground.solid
                                ? (isDark
                                    ? const Color(0xFF0A0A0F)
                                    : Colors.white)
                                : null,
                            gradient: bg == AppBackground.gradient
                                ? LinearGradient(
                                    colors: [
                                      accent.withOpacity(0.3),
                                      accent.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : bg == AppBackground.mesh
                                    ? LinearGradient(
                                        colors: [
                                          accent.withOpacity(0.4),
                                          Colors.blue.withOpacity(0.3),
                                          Colors.pink.withOpacity(0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                            border: Border.all(
                              color: scheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(labels[bg]!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14 * _provider.fontScale,
                                    color: isSelected
                                        ? accent
                                        : scheme.onSurface,
                                  )),
                              Text(descriptions[bg]!,
                                  style: TextStyle(
                                    fontSize: 12 * _provider.fontScale,
                                    color: scheme.onSurface
                                        .withOpacity(0.5),
                                  )),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: accent, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // ── Reset ───────────────────────────────────
          GestureDetector(
            onTap: () async {
              await _provider.setThemeMode(ThemeMode.system);
              await _provider.setAccentColor(
                  const Color(0xFF7C3AED));
              await _provider.setCardStyle(CardStyle.rounded);
              await _provider.setFontSize(FontSize.medium);
              await _provider.setBackground(AppBackground.solid);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Settings reset to default'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.red.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Reset to defaults',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13 * ThemeProvider.instance.fontScale,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius:
            BorderRadius.circular(ThemeProvider.instance.cardRadius),
        border: Border.all(
            color: scheme.onSurface.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(0.12)
                : scheme.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.4)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? accent
                      : scheme.onSurface.withOpacity(0.4),
                  size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? accent
                        : scheme.onSurface.withOpacity(0.5),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}