


# UML for Serverpod

Generate PlantUML diagrams from your serverpod `.spy.yaml` model files.

![Example UML Diagram with Colored Arrows](https://github.com/dabblingwithcode/uml_for_serverpod/blob/main/images/diagram_color_arrows.png)

## Installation

```bash
dart pub global activate uml_for_serverpod
```

Or add to your project's pubspec.yaml:

```yaml
dependencies:
  uml_generator: ^0.0.2
```

## Usage

### As a command-line tool

```bash
dart run uml_for_serverpod --dir=lib/src/models --output=er_diagram.puml
```

### As a library

```dart
import 'dart:io';
import 'package:uml_for_serverpod/uml_for_serverpod.dart';

Future<void> main() async {
  final generator = UmlGenerator(
    modelsDir: Directory('lib/src/models'),
    yamlOutputFile: File('all_yaml_content.txt'),
    umlOutputFile: File('er_diagram.puml'),
    // Optional customization
    classHexColor: '#800080',
    manyHexColor: '#008000',
  );
  
  await generator.generate();
}
```
## Configuration

You can customize the UML generation by providing a YAML configuration file:

```bash
dart run uml_for_serverpod --config=uml_config.yaml
```

Example configuration file `uml_config.yaml`:

```yaml
printComments: true
commentHexColor: '#93c47d'
manyHexColor: '#27ae60'
manyString: 'N'
oneHexColor: '#9b59b6'
oneString: '1'
relationHexColor: '#0164aa'
classHexColor: '#ff962f'
```

## Options

- `--dir, -d`: Directory containing .spy.yaml files (default: "lib/src/models")
- `--output, -o`: Output PlantUML file (default: "er_diagram.puml")
- `--yaml-output`: Output file for concatenated YAML content (default: "all_yaml_content.txt")
- `--help, -h`: Show usage information


## Visualize your .puml file

You can visualize your .puml file pasting the code here:

https://editor.plantuml.com/

If you are using vscode, there is also an extension:

https://marketplace.visualstudio.com/items/?itemName=jebbs.plantuml


## Customize / contribute

There are many uml customization options available, you can play around with them:

https://plantuml.com/en-dark/class-diagram

You found a way to improve this package? Contributions are very welcome!
