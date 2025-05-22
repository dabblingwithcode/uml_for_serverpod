import 'dart:io';

import 'package:args/args.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/yaml/yaml_config_decoder.dart';
import 'package:uml_for_serverpod/uml_for_serverpod.dart';

void main(List<String> args) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('dir', abbr: 'd', help: 'Directory containing .spy.yaml files')
    ..addOption('output', abbr: 'o', help: 'Output PlantUML file')
    ..addOption('config', abbr: 'c', help: 'Path to configuration YAML file')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information');

  try {
    stdout.writeln(
        '\n\x1B[1mUML Diagram Generator for Serverpod YAML models\x1B[0m \n');

    final results = parser.parse(args);

    if (results['help']) {
      printUsage(parser);
      return;
    }

    UmlConfig config;

    // Load configuration from file if provided
    final configPath = results['config'];
    if (configPath != null) {
      final configFile = File(configPath);
      if (await configFile.exists()) {
        try {
          stdout.writeln('📄 Loading configuration from $configPath');
          config = await UmlConfigParser.getYamlConfigFromFile(configFile);
          stdout.writeln('📄 Configuration loaded from $configPath');
        } catch (e) {
          stdout.writeln(
              '⚠️ Warning: Error parsing configuration file: $e - using default values...');
          config = UmlConfig();
        }
      } else {
        stdout.writeln(
            '⚠️ Warning: Configuration file not found at: $configPath - using default values...');
        config = UmlConfig();
      }
    } else {
      config = UmlConfig();
    }
    if (results['dir'] != null) {
      config = config.copyWith(modelsDirPath: results['dir']);
    }
    if (results['output'] != null) {
      config = config.copyWith(umlOutputFile: results['output']);
    }

    final generator = UmlGenerator(config: config);

    await generator.generate();

    stdout
        .writeln('✅ Done! UML diagram created at ${config.umlOutputFile} 🗺️');
  } catch (e, stackTrace) {
    stdout.writeln('❌ Error: $e');
    printUsage(parser);
    stdout.write(stackTrace);
    exit(1);
  }
}

void printUsage(ArgParser parser) {
  stdout.writeln('UML Generator for Serverpod YAML models\n');
  stdout.writeln('Usage:');
  stdout.writeln(parser.usage);
}
