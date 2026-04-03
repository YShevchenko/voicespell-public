import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/spell_provider.dart';
import '../../core/services/iap_service.dart';
import '../../domain/models/spell.dart';
import 'package:uuid/uuid.dart';

class SpellbookScreen extends StatefulWidget {
  const SpellbookScreen({super.key});

  @override
  State<SpellbookScreen> createState() => _SpellbookScreenState();
}

class _SpellbookScreenState extends State<SpellbookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpellProvider>().loadSpells();
    });
  }

  void _showPremiumPaywall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PremiumPaywall(),
    );
  }

  Future<void> _showAddSpellDialog(SpellProvider provider) async {
    final iap = IAPService.instance;
    final totalSpells = provider.totalSpellCount;

    // Free limit: 5 default spells. Custom spells require premium.
    if (!iap.isPremium) {
      _showPremiumPaywall();
      return;
    }

    // Premium limit: 20 active spells
    if (totalSpells >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maximum 20 spells reached (Premium limit).')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _AddSpellDialog(provider: provider),
    );
  }

  Future<void> _showEditSpellDialog(
      SpellProvider provider, Spell spell) async {
    final iap = IAPService.instance;
    if (!iap.isPremium) {
      _showPremiumPaywall();
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _EditSpellDialog(provider: provider, spell: spell),
    );
  }

  Future<void> _confirmDelete(SpellProvider provider, Spell spell) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Spell'),
        content: Text(
            'Delete "${spell.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await provider.deleteSpell(spell);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SpellProvider, IAPService>(
      builder: (context, provider, iap, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D1A),
            title: const Text(
              'Spellbook',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (!iap.isPremium)
                TextButton.icon(
                  onPressed: _showPremiumPaywall,
                  icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                  label: const Text(
                    'Upgrade',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionHeader(
                      title: 'Free Spells',
                      count: provider.freeSpells.length,
                    ),
                    ...provider.freeSpells.map((spell) => _SpellCard(
                          spell: spell,
                          isLocked: false,
                          onToggle: () => provider.toggleEnabled(spell),
                          onEdit: () =>
                              _showEditSpellDialog(provider, spell),
                          onDelete: null, // Default spells cannot be deleted
                        )),

                    if (provider.premiumSpells.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Premium Spells',
                        count: provider.premiumSpells.length,
                        locked: !iap.isPremium,
                      ),
                      ...provider.premiumSpells.map((spell) => _SpellCard(
                            spell: spell,
                            isLocked: !iap.isPremium,
                            onToggle: iap.isPremium
                                ? () => provider.toggleEnabled(spell)
                                : null,
                            onEdit: () =>
                                _showEditSpellDialog(provider, spell),
                            onDelete: (!spell.isDefault && iap.isPremium)
                                ? () => _confirmDelete(provider, spell)
                                : null,
                          )),
                    ],

                    if (provider.customSpells.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Custom Spells',
                        count: provider.customSpells.length,
                      ),
                      ...provider.customSpells.map((spell) => _SpellCard(
                            spell: spell,
                            isLocked: false,
                            onToggle: () => provider.toggleEnabled(spell),
                            onEdit: () =>
                                _showEditSpellDialog(provider, spell),
                            onDelete: () =>
                                _confirmDelete(provider, spell),
                          )),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSpellDialog(provider),
            backgroundColor: const Color(0xFF6B4EFF),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Spell',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool locked;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          if (locked)
            const Icon(Icons.lock, size: 14, color: Colors.amber),
          const Spacer(),
          Text(
            '$count',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Spell Card ────────────────────────────────────────────────────────────

class _SpellCard extends StatelessWidget {
  final Spell spell;
  final bool isLocked;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SpellCard({
    required this.spell,
    required this.isLocked,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  IconData _actionIcon(SpellAction action) {
    switch (action) {
      case SpellAction.toggleFlashlight:
        return Icons.flashlight_on;
      case SpellAction.revelio:
        return Icons.light_mode;
      case SpellAction.adjustBrightness:
        return Icons.brightness_medium;
      case SpellAction.setTimer:
        return Icons.timer;
      case SpellAction.muteUnmute:
        return Icons.volume_off;
      case SpellAction.customIntent:
        return Icons.open_in_new;
    }
  }

  String _actionLabel(SpellAction action) {
    switch (action) {
      case SpellAction.toggleFlashlight:
        return 'Toggle Flashlight';
      case SpellAction.revelio:
        return 'Flash 3 seconds';
      case SpellAction.adjustBrightness:
        return 'Toggle Brightness';
      case SpellAction.setTimer:
        return '5-min Timer';
      case SpellAction.muteUnmute:
        return 'Mute / Unmute';
      case SpellAction.customIntent:
        return 'Intent URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isLocked
              ? Colors.grey.shade800
              : const Color(0xFF6B4EFF).withValues(alpha: 0.3),
          child: Icon(
            isLocked ? Icons.lock : _actionIcon(spell.actionType),
            color: isLocked ? Colors.grey : const Color(0xFF6B4EFF),
            size: 20,
          ),
        ),
        title: Text(
          spell.name,
          style: TextStyle(
            color: isLocked ? Colors.white38 : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${spell.triggerPhrase}"',
              style: TextStyle(
                color: isLocked
                    ? Colors.white24
                    : const Color(0xFF9B7FFF),
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
            Text(
              _actionLabel(spell.actionType),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white38),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            Switch(
              value: spell.isEnabled && !isLocked,
              onChanged: isLocked ? null : (_) => onToggle?.call(),
              activeThumbColor: const Color(0xFF6B4EFF),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Spell Dialog ──────────────────────────────────────────────────────

class _AddSpellDialog extends StatefulWidget {
  final SpellProvider provider;
  const _AddSpellDialog({required this.provider});

  @override
  State<_AddSpellDialog> createState() => _AddSpellDialogState();
}

class _AddSpellDialogState extends State<_AddSpellDialog> {
  final _nameCtrl = TextEditingController();
  final _triggerCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  SpellAction _selectedAction = SpellAction.customIntent;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _triggerCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _triggerCtrl.text.trim().isEmpty) {
      return;
    }

    final spell = Spell(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      triggerPhrase: _triggerCtrl.text.toLowerCase().trim(),
      actionType: _selectedAction,
      intentUrl: _selectedAction == SpellAction.customIntent
          ? _urlCtrl.text.trim()
          : null,
      isDefault: false,
      isEnabled: true,
      isPremiumRequired: false,
    );

    await widget.provider.addCustomSpell(spell);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Spell'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Spell Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _triggerCtrl,
              decoration: const InputDecoration(
                  labelText: 'Trigger Phrase (what you say)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SpellAction>(
              initialValue: _selectedAction,
              decoration: const InputDecoration(labelText: 'Action'),
              items: SpellAction.values
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(_actionName(a)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedAction = v);
              },
            ),
            if (_selectedAction == SpellAction.customIntent) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Android Intent URL',
                  hintText: 'intent://...',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _actionName(SpellAction action) {
    switch (action) {
      case SpellAction.toggleFlashlight:
        return 'Toggle Flashlight';
      case SpellAction.revelio:
        return 'Flash 3 seconds (Revelio)';
      case SpellAction.adjustBrightness:
        return 'Toggle Brightness';
      case SpellAction.setTimer:
        return '5-min Timer';
      case SpellAction.muteUnmute:
        return 'Mute / Unmute';
      case SpellAction.customIntent:
        return 'Android Intent URL';
    }
  }
}

// ─── Edit Spell Dialog ─────────────────────────────────────────────────────

class _EditSpellDialog extends StatefulWidget {
  final SpellProvider provider;
  final Spell spell;
  const _EditSpellDialog(
      {required this.provider, required this.spell});

  @override
  State<_EditSpellDialog> createState() => _EditSpellDialogState();
}

class _EditSpellDialogState extends State<_EditSpellDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _triggerCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.spell.name);
    _triggerCtrl = TextEditingController(text: widget.spell.triggerPhrase);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _triggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.provider.updateSpellName(
        widget.spell, _nameCtrl.text.trim());
    await widget.provider.updateSpellTrigger(
        widget.spell.copyWith(name: _nameCtrl.text.trim()),
        _triggerCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Spell'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Spell Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _triggerCtrl,
            decoration:
                const InputDecoration(labelText: 'Trigger Phrase'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Premium Paywall ───────────────────────────────────────────────────────

class _PremiumPaywall extends StatelessWidget {
  const _PremiumPaywall();

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Unlock Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Up to 20 active spells\n'
            '• Rename trigger phrases\n'
            '• Create custom Android Intent spells\n'
            '• One-time purchase — no subscription',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: iap.isPurchasing
                ? null
                : () async {
                    final ok = await IAPService.instance.purchase();
                    if (ok && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Premium unlocked!')),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: iap.isPurchasing
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Text(
                    'Upgrade for ${iap.priceString}',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await IAPService.instance.restorePurchases();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Restore Purchase',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
