/// How a model implicitly refers to another model through its fields.
enum ImplicitLink { inheritance, fieldType }

final _typeToken = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

/// The implicit link from a model with [fields] to the model named [target],
/// or null when no field refers to it.
///
/// Field types are matched as whole type tokens, so `JobStatus` does not link
/// to `Job`. `extends: X` is inheritance. Relation fields are drawn as
/// relations elsewhere and are skipped here.
ImplicitLink? implicitLinkKind(Map<String, String> fields, String target) {
  ImplicitLink? link;
  for (final field in fields.entries) {
    final value = field.value;
    if (value.isEmpty || value.contains('relation')) continue;
    final type = value.split(',').first;
    final refersToTarget =
        _typeToken.allMatches(type).any((token) => token.group(0) == target);
    if (!refersToTarget) continue;
    if (field.key == 'extends') return ImplicitLink.inheritance;
    link = ImplicitLink.fieldType;
  }
  return link;
}
