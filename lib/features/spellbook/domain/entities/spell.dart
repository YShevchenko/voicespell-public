/// Spell entity
class Spell {
  final String id;
  final String name;
  final String incantation;
  final String actionType;
  final String? actionParams;
  final bool isCustom;
  final bool isActive;
  final int sortOrder;

  const Spell({
    required this.id,
    required this.name,
    required this.incantation,
    required this.actionType,
    this.actionParams,
    required this.isCustom,
    required this.isActive,
    required this.sortOrder,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Spell && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
