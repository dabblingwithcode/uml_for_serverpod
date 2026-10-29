import 'dart:io';

import 'package:uml_for_serverpod/src/models.dart';
import 'package:yaml/yaml.dart';

class UmlConfigParser {
  static Future<UmlConfig> getYamlConfigFromFile(File configFile) async {
    final config = UmlConfig();
    final configYaml = loadYaml(await configFile.readAsString());
    if (configYaml is Map) {
      try {
        final yamlConfig = config.copyWith(
          // path config
          modelsDirPath:
              configYaml['paths']?['modelsDirPath'] ?? config.modelsDirPath,
          umlOutputFile:
              configYaml['paths']?['umlOutputFile'] ?? config.umlOutputFile,
          // diagram options
          printComments: configYaml['options']?['printComments'],
          ignoreRootFolder: configYaml['options']?['ignoreRootFolder'],
          useNameSpace: configYaml['options']?['useNameSpace'],

          // layout options
          skinparamNodesep: configYaml['layout']?['skinparamNodesep'],
          skinparamRanksep: configYaml['layout']?['skinparamRanksep'],
          layoutEngine: configYaml['layout']?['engine'],
          flatPackages: configYaml['layout']?['flatPackages'],

          // relations style
          colorfullArrows: configYaml['style']?['relations']
              ?['colorfullArrows'],
          colorfullTypeLinks: configYaml['style']?['relations']
              ?['colorfullTypeLinks'],
          oneString: configYaml['style']?['relations']?['oneString'],
          oneHexColor: configYaml['style']?['relations']?['oneHexColor'],
          manyString: configYaml['style']?['relations']?['manyString'],
          manyHexColor: configYaml['style']?['relations']?['manyHexColor'],
          relationHexColor: configYaml['style']?['relations']
              ?['relationHexColor'],

          // class style
          classNameHexColor: configYaml['style']?['class']
              ?['classNameHexColor'],
          classBorderHexColor: configYaml['style']?['class']
              ?['classBorderHexColor'],
          classBackgroundHexColor: configYaml['style']?['class']
              ?['classBackgroundHexColor'],
          classMaxWidth: configYaml['style']?['class']?['maxWidth'],
          // comment style
          commentHexColor: configYaml['style']?['class']?['commentHexColor'],
          // namespace style
          namespaceBorderHexColor: configYaml['namespaceBorderHexColor'],
          rootNamespaceBackgroundHexColor: configYaml['style']?['namespace']
              ?['rootNamespaceBackgroundHexColor'],
          secondLevelNamespaceBackgroundHexColor: configYaml['style']
              ?['namespace']?['secondLevelNamespaceBackgroundHexColor'],
          thirdLevelNamespaceBackgroundHexColor: configYaml['style']
              ?['namespace']?['thirdLevelNamespaceBackgroundHexColor'],
        );
        stdout.writeln(
            '📄 Configuration loaded from ${configFile.path} - ${yamlConfig.toString()}');

        return yamlConfig;
      } catch (e) {
        stdout.writeln(
            '⚠️ Warning: Error parsing configuration file: $e - using default values...');
        return config;
      }
    }
    stdout.writeln(
        '⚠️ Warning: Invalid configuration file format. Expected a map. Returning default values...');
    return config;
  }
}
