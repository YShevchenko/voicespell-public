import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/spell_provider.dart';
import '../../core/services/iap_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportSpells(BuildContext context) async {
    final provider = context.read<SpellProvider>();
    final customs = provider.customSpells;
    if (customs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No custom spells to export.')),
      );
      return;
    }
    await provider.exportCustomSpells();
  }

  Future<void> _importSpells(BuildContext context) async {
    final provider = context.read<SpellProvider>();
    final count = await provider.importSpells();
    if (!context.mounted) return;
    if (count < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Import failed. Check the file format.')),
      );
    } else if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No spells imported.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count spell(s).')),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Spellbook'),
        content: const Text(
          'This will delete all custom spells and re-enable all default spells. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<SpellProvider>().resetToStarterSpellbook();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Spellbook reset to starter spells.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // ── Premium ───────────────────────────────────────────────────
          _SectionTitle('Premium'),
          if (iap.isPremium)
            _SettingsTile(
              icon: Icons.star,
              iconColor: Colors.amber,
              title: 'VoiceSpell Premium',
              subtitle: 'Active — thank you!',
            )
          else ...[
            _SettingsTile(
              icon: Icons.star_border,
              iconColor: Colors.amber,
              title: 'Upgrade to Premium',
              subtitle: '${iap.priceString} — one-time, no subscription',
              onTap: () async {
                final ok = await IAPService.instance.purchase();
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Premium unlocked!')),
                  );
                }
              },
            ),
            _SettingsTile(
              icon: Icons.restore,
              title: 'Restore Purchase',
              onTap: () async {
                await IAPService.instance.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Purchase restore attempted.')),
                  );
                }
              },
            ),
          ],

          const Divider(color: Colors.white12),

          // ── Data ──────────────────────────────────────────────────────
          _SectionTitle('Data'),
          _SettingsTile(
            icon: Icons.upload,
            title: 'Export Custom Spells',
            subtitle: 'Save as JSON and share',
            onTap: () => _exportSpells(context),
          ),
          _SettingsTile(
            icon: Icons.download,
            title: 'Import Spells',
            subtitle: 'Load from JSON file',
            onTap: () => _importSpells(context),
          ),
          _SettingsTile(
            icon: Icons.restart_alt,
            iconColor: Colors.redAccent,
            title: 'Reset to Starter Spellbook',
            subtitle: 'Remove custom spells, restore defaults',
            onTap: () => _confirmReset(context),
          ),

          const Divider(color: Colors.white12),

          // ── About ─────────────────────────────────────────────────────
          _SectionTitle('About'),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'VoiceSpell',
            subtitle: 'v1.0.1 — by Heldig Lab',
          ),
          const _SettingsTile(
            icon: Icons.security,
            title: 'Privacy',
            subtitle: 'Zero backend — all processing on-device.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white54),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
      onTap: onTap,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.white24)
          : null,
    );
  }
}
