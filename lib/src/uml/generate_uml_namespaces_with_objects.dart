import 'package:collection/collection.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/uml/generate_uml_object.dart';

({String renderedNamespaces, List<ObjectRelation> relations})
    generateNameSpacesAndRelationsFromObjects(
  List<UmlObject> objects,
  UmlConfig config,
) {
  final namespaceUmlBuffer = StringBuffer();
  List<String> namespaceHexColors = [
    config.rootNamespaceBackgroundHexColor,
    config.secondLevelNamespaceBackgroundHexColor,
    config.thirdLevelNamespaceBackgroundHexColor
  ];
  List<UmlNamespace> namespaces = [];
  List<ObjectRelation> relations = [];
  // First pass: Collect all namespaces
  for (UmlObject object in objects) {
    // first deal with the relations

    // Add the object to the list of relations
    for (final ObjectRelation relation in object.relations ?? []) {
      // If the other side of the relation is not in the list, add it
      if (!relations.any((r) =>
          r.objectName == relation.relatedObject &&
          r.relatedObject == relation.objectName)) {
        relations.add(relation);
      }
    }
    final pathParts = object.filepath!.substring(1).split('/');

    switch (pathParts.length) {
      case 1:
        // This object is in the root folder, write it directly
        namespaceUmlBuffer.writeln(generateUmlObject(object, config));
        break;
      case >= 2:
        final nameSpace = pathParts[pathParts.length - 2];
        final parentNameSpace =
            pathParts.length >= 3 ? pathParts[pathParts.length - 3] : null;

        // Skip if this is the root folder we want to ignore
        if (nameSpace == config.ignoreRootFolder) {
          namespaceUmlBuffer.writeln(generateUmlObject(object, config));
          break;
        }

        // Find or create this namespace
        UmlNamespace? namespace =
            namespaces.firstWhereOrNull((ns) => ns.name == nameSpace);

        if (namespace == null) {
          namespace = UmlNamespace(
            name: nameSpace,
            parentNameSpace: parentNameSpace != config.ignoreRootFolder
                ? parentNameSpace
                : null,
            children: [],
          );
          namespaces.add(namespace);
        }

        // Add the object to this namespace
        namespace.children.add(object);
        break;
      default:
        break;
    }
  }

  // Group namespaces by their parents
  Map<String, List<UmlNamespace>> parentChildMap = {};

  for (var namespace in namespaces) {
    final parent = namespace.parentNameSpace ?? 'none';
    if (!parentChildMap.containsKey(parent)) {
      parentChildMap[parent] = [];
    }
    parentChildMap[parent]!.add(namespace);
  }

  // Add a Set to keep track of processed namespaces
  Set<String> processedNamespaces = {};

  void writeNamespace(String parent, String indent, int colorIndex) {
    // Check if this namespace has already been processed to avoid circular references
    if (!parentChildMap.containsKey(parent) ||
        processedNamespaces.contains(parent)) {
      return;
    }

    // Mark this namespace as being processed
    processedNamespaces.add(parent);

    for (var namespace in parentChildMap[parent]!) {
      // using [package] (namespace won't work) and adding 'as " $name "' to improve readability
      namespaceUmlBuffer.writeln(
          '${indent}package ${namespace.name} as " ${namespace.name} "  ${namespaceHexColors[colorIndex]} {');

      // Write objects in this namespace
      for (var object in namespace.children) {
        namespaceUmlBuffer
            .writeln('$indent  ${generateUmlObject(object, config)}');
      }

      // Write child namespaces recursively
      writeNamespace(
          namespace.name, '$indent  ', colorIndex == 2 ? 0 : colorIndex + 1);

      namespaceUmlBuffer.writeln('$indent}');
    }
  }

  // Start with root namespaces (those with empty parent)
  writeNamespace('none', '', 0);

  return (
    renderedNamespaces: namespaceUmlBuffer.toString(),
    relations: relations
  );
}
