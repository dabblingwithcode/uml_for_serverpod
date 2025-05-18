import 'dart:io';

import 'package:args/args.dart';
import 'package:uml_for_serverpod/uml_for_serverpod.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('dir',
        abbr: 'd',
        defaultsTo: 'lib/src/models',
        help: 'Directory containing .spy.yaml files')
    ..addOption('output',
        abbr: 'o', defaultsTo: 'er_diagram.puml', help: 'Output PlantUML file')
    ..addOption('yaml-output',
        defaultsTo: 'all_yaml_content.txt',
        help: 'Output file for concatenated YAML content')
    ..addOption('config', abbr: 'c', help: 'Path to configuration YAML file')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information');

  try {
    final results = parser.parse(args);

    if (results['help']) {
      printUsage(parser);
      return;
    }

    // Default configuration
    UmlConfig config = UmlConfig();

    // Load configuration from file if provided
    final configPath = results['config'];
    if (configPath != null) {
      final configFile = File(configPath);
      if (await configFile.exists()) {
        final configYaml = loadYaml(await configFile.readAsString());
        if (configYaml is Map) {
          config = UmlConfig.fromMap(Map<String, dynamic>.from(configYaml));
          stdout.writeln('📄 Configuration loaded from $configPath');
        } else {
          stdout.writeln(
              '⚠️ Warning: Invalid configuration format in $configPath');
        }
      } else {
        stdout.writeln('⚠️ Warning: Configuration file not found: $configPath');
      }
    }

    final generator = UmlGenerator(
      modelsDir: Directory(results['dir']),
      yamlOutputFile: File(results['yaml-output']),
      umlOutputFile: File(results['output']),
      printComments: config.printComments,
      commentHexColor: config.commentHexColor,
      manyHexColor: config.manyHexColor,
      manyString: config.manyString,
      oneHexColor: config.oneHexColor,
      oneString: config.oneString,
      relationHexColor: config.relationHexColor,
      classHexColor: config.classHexColor,
    );

    await generator.generate();
    stdout.writeln('✅ Done! UML diagram created at ${results['output']}');
  } catch (e) {
    stdout.writeln('❌ Error: $e');
    printUsage(parser);
    exit(1);
  }
}

void printUsage(ArgParser parser) {
  stdout.writeln('UML Generator for Serverpod YAML models\n');
  stdout.writeln('Usage:');
  stdout.writeln(parser.usage);
}
