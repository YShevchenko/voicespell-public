import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/iap_service.dart';

/// Spellbook list screen
class SpellbookScreen extends ConsumerStatefulWidget {
  const SpellbookScreen({super.key});

  @override
  ConsumerState<SpellbookScreen> createState() => _SpellbookScreenState();
}

class _SpellbookScreenState extends ConsumerState<SpellbookScreen> {
  List<Map<String, dynamic>> _spells = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpells();
  }

  Future<void> _loadSpells() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final spells = await db.query(
      'spells',
      orderBy: 'sort_order ASC',
    );
    setState(() {
      _spells = spells;
      _isLoading = false;
    });
  }

  Future<void> _toggleSpell(Map<String, dynamic> spell) async {
    final db = await DatabaseHelper.instance.database;
    final newState = spell['is_active'] == 1 ? 0 : 1;
    await db.update(
      'spells',
      {'is_active': newState},
      where: 'id = ?',
      whereArgs: [spell['id']],
    );
    await _loadSpells();
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Upgrade to Premium for \$3.99 to unlock 20+ spells and create custom spells!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await IAPService.instance.purchase();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium unlocked!')),
                );
                await _loadSpells();
              }
            },
            child: const Text('UPGRADE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Spellbook')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPremium = IAPService.instance.isPremium;
    final freeSpells = _spells.where((s) => s['is_premium'] == 0).toList();
    final premiumSpells = _spells.where((s) => s['is_premium'] == 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Spellbook'),
        actions: [
          if (!isPremium)
            TextButton.icon(
              onPressed: _showPremiumDialog,
              icon: const Icon(Icons.star, color: Colors.amber),
              label: const Text('UPGRADE'),
              style: TextButton.styleFrom(foregroundColor: Colors.amber),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Free spells section
          Text(
            'Free Spells',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...freeSpells.map((spell) => _buildSpellCard(spell, false)),

          const SizedBox(height: 24),

          // Premium spells section
          Row(
            children: [
              Text(
                'Premium Spells',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              if (!isPremium)
                const Icon(Icons.lock, size: 20, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          ...premiumSpells.map((spell) => _buildSpellCard(spell, !isPremium)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isPremium) {
            // Show create custom spell dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Custom spell creation coming soon!')),
            );
          } else {
            _showPremiumDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Spell'),
      ),
    );
  }

  Widget _buildSpellCard(Map<String, dynamic> spell, bool isLocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLocked
              ? Colors.grey
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            isLocked ? Icons.lock : Icons.auto_fix_high,
            color: isLocked
                ? Colors.white
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(spell['name'] as String),
        subtitle: Text(
          '"${spell['incantation']}"',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: isLocked
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        trailing: Switch(
          value: spell['is_active'] == 1,
          onChanged: isLocked
              ? null
              : (value) => _toggleSpell(spell),
        ),
        onTap: isLocked ? _showPremiumDialog : null,
      ),
    );
  }
}
