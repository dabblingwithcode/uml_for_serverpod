import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/uml/uml_object_helpers.dart';

String generateUmlObject(
  UmlObject object,
  UmlConfig config,
) {
  final objectBuffer = StringBuffer();
  final objectType = object.objectType;
  final filepath = object.filepath!;

  // declare the object type and name
  final objectDeclaration =
      UmlObjectHelpers.renderUmlObjectDeclaration(object, config);
  objectBuffer.writeln(objectDeclaration);

  // Add the filepath
  objectBuffer.writeln('<size:14>📁</size> <b><size:12> $filepath</size></b>');
  // Add a separator
  objectBuffer.writeln('--');

  // Add fields
  switch (objectType) {
    case ObjectType.classType:
    case ObjectType.databaseClassType:
    case ObjectType.exceptionType:
      if (object.fields != null) {
        for (var entry in object.fields!.entries) {
          final key = entry.key;
          final value = entry.value;
          final fieldLine =
              UmlObjectHelpers.renderUmlObjectFieldLine(key, value, config);
          if (fieldLine != null) {
            objectBuffer.writeln(fieldLine);
          }
        }
      }
      objectBuffer.writeln();
      objectBuffer.writeln('}');

      break;

    case ObjectType.enumType:
      if (object.enumSerialized != null) {
        objectBuffer.writeln('  serialized: ${object.enumSerialized}');
      }
      if (object.enumValues != null) {
        objectBuffer.writeln('  values: ${object.enumValues}');
      }
      objectBuffer.writeln();
      objectBuffer.writeln('}');
      break;

    case null:
      throw Exception('Object type is null for object: ${object.name}');
  }
  return objectBuffer.toString();
}
