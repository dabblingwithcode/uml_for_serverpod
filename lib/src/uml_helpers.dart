import 'package:uml_for_serverpod/src/models.dart';

class UmlHelpers {
  static String getObjectNameWithNameSpace(UmlObject object) {
    final pathParts = object.filepath?.split('/') ?? [];
    final firstNameSpace =
        pathParts.isNotEmpty ? pathParts[pathParts.length - 3] : null;

    final secondNameSpace =
        pathParts.isNotEmpty ? pathParts[pathParts.length - 2] : null;
    return '${firstNameSpace != null ? '$firstNameSpace.' : ''}${secondNameSpace != null ? '$secondNameSpace.' : ''}${object.name}';
  }

  static String getObjectDeclaration(UmlObject object, bool useNameSpace) {
    final objectName =
        useNameSpace ? getObjectNameWithNameSpace(object) : object.name;
    final objectType = object.objectType;
    if (objectType == null) {
      throw Exception('Object type is null');
    }
    // the database class is a special case
    if (objectType == ObjectType.databaseClassType) {
      return '${objectType.value} $objectName <<table: <b>${object.tableName}</b>>> ##[bold] {';
    } else {
      return '${objectType.value} $objectName ##[bold] {';
    }
  }
}
