import 'dart:io';

import 'package:args/args.dart';
import 'package:uml_for_serverpod/uml_for_serverpod.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('dir',
        abbr: 'd',
        defaultsTo: 'lib',
        help: 'Directory containing .spy.yaml files')
    ..addOption('output',
        abbr: 'o', defaultsTo: 'er_diagram.puml', help: 'Output PlantUML file')
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
      config: config,
      // TODO: Fix this
      modelsDirPath: (results['dir'] != config.modelsDirPath)
          ? results['dir']
          : config.modelsDirPath,

      umlOutputFile: File(results['output']),
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
