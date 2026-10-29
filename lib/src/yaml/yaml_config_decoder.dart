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
          // output backend
          outputFormat: configYaml['output']?['format'],
          graphvizBinDir: configYaml['output']?['graphvizBinDir'],
          // diagram options
          printComments: configYaml['options']?['printComments'],
          ignoreRootFolder: configYaml['options']?['ignoreRootFolder'],
          useNameSpace: configYaml['options']?['useNameSpace'],

          // layout options
          skinparamNodesep: configYaml['layout']?['skinparamNodesep'],
          skinparamRanksep: configYaml['layout']?['skinparamRanksep'],
          layoutEngine: configYaml['layout']?['engine'],
          flatPackages: configYaml['layout']?['flatPackages'],
          gridColumns: configYaml['layout']?['grid']?['columns'],
          gridAspectRatio:
              (configYaml['layout']?['grid']?['aspectRatio'] as num?)
                  ?.toDouble(),
          gridGap: configYaml['layout']?['grid']?['gap'],
          gridMode: configYaml['layout']?['grid']?['mode'],
          gridOrder: (configYaml['layout']?['grid']?['order'] as List?)
              ?.map((e) => '$e')
              .toList(),
          splines: configYaml['layout']?['splines']?.toString(),

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
