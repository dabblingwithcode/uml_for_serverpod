class SpyYamlParseHelpers {
  static ({String? nameSpace, String? subNameSpace}) getNameSpacesFromPath(
      String filePath, String? ignoreRootFolder) {
    final pathParts = filePath.split('/');
    final firstNameSpace =
        pathParts.isNotEmpty ? pathParts[pathParts.length - 3] : '';
    final secondNameSpace =
        pathParts.isNotEmpty ? pathParts[pathParts.length - 2] : '';
    return (
      nameSpace: firstNameSpace == ignoreRootFolder ? null : firstNameSpace,
      subNameSpace: secondNameSpace == ignoreRootFolder ? null : secondNameSpace
    );
  }
}
