import 'dart:convert';

enum SpellAction {
  toggleFlashlight,
  revelio, // flash for 3 seconds then off
  adjustBrightness,
  setTimer,
  muteUnmute,
  customIntent,
}

class Spell {
  final String id;
  final String name;
  final String triggerPhrase;
  final SpellAction actionType;
  final String? intentUrl;
  final bool isDefault;
  final bool isEnabled;
  final bool isPremiumRequired;

  const Spell({
    required this.id,
    required this.name,
    required this.triggerPhrase,
    required this.actionType,
    this.intentUrl,
    required this.isDefault,
    required this.isEnabled,
    required this.isPremiumRequired,
  });

  Spell copyWith({
    String? id,
    String? name,
    String? triggerPhrase,
    SpellAction? actionType,
    String? intentUrl,
    bool? isDefault,
    bool? isEnabled,
    bool? isPremiumRequired,
  }) {
    return Spell(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerPhrase: triggerPhrase ?? this.triggerPhrase,
      actionType: actionType ?? this.actionType,
      intentUrl: intentUrl ?? this.intentUrl,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      isPremiumRequired: isPremiumRequired ?? this.isPremiumRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'trigger_phrase': triggerPhrase,
      'action_type': actionType.name,
      'intent_url': intentUrl,
      'is_default': isDefault ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'is_premium_required': isPremiumRequired ? 1 : 0,
    };
  }

  factory Spell.fromMap(Map<String, dynamic> map) {
    return Spell(
      id: map['id'] as String,
      name: map['name'] as String,
      triggerPhrase: map['trigger_phrase'] as String,
      actionType: SpellAction.values.firstWhere(
        (e) => e.name == map['action_type'],
        orElse: () => SpellAction.customIntent,
      ),
      intentUrl: map['intent_url'] as String?,
      isDefault: (map['is_default'] as int) == 1,
      isEnabled: (map['is_enabled'] as int) == 1,
      isPremiumRequired: (map['is_premium_required'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'trigger_phrase': triggerPhrase,
      'action_type': actionType.name,
      'intent_url': intentUrl,
      'is_default': isDefault,
      'is_enabled': isEnabled,
      'is_premium_required': isPremiumRequired,
    };
  }

  factory Spell.fromJson(Map<String, dynamic> json) {
    return Spell(
      id: json['id'] as String,
      name: json['name'] as String,
      triggerPhrase: json['trigger_phrase'] as String,
      actionType: SpellAction.values.firstWhere(
        (e) => e.name == json['action_type'],
        orElse: () => SpellAction.customIntent,
      ),
      intentUrl: json['intent_url'] as String?,
      isDefault: json['is_default'] as bool,
      isEnabled: json['is_enabled'] as bool,
      isPremiumRequired: json['is_premium_required'] as bool,
    );
  }

  static List<Map<String, dynamic>> listToJson(List<Spell> spells) {
    return spells.map((s) => s.toJson()).toList();
  }

  static List<Spell> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => Spell.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Spell && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
