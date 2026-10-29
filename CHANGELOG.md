## 0.0.7

* New Graphviz backend: `--format dot` / `output.format: dot` renders an SVG in two passes (packages laid out alone with `dot`, placed on a grid in Dart, then rendered pinned with `neato -n2` so edges curve between the blocks). Balanced layout and curved edges together.
* Grid options `layout.grid.columns`, `aspectRatio`, `gap`, `mode` (`rows` | `cells`), `order`; edge routing `layout.splines` (`true` | `curved`); Graphviz location `output.graphvizBinDir`.
* Wide fans inside a package are spread over several ranks with Graphviz' `unflatten` when that is more balanced.
* Card text wraps at `style.class.maxWidth` in Dart; the SVG is sanitised to static, inert elements.
* PlantUML output (the default) is unchanged.

## 0.0.6

* Optional `style.class.maxWidth`: class cards wrap their text beyond this width (PlantUML `MaximumWidth`).
* Optional `layout.engine` (`elk` or `smetana`, PlantUML `!pragma layout`): `elk` gives large diagrams a balanced width and height.
* Optional `style.relations.colorfullTypeLinks`: field-type and inheritance links are coloured too.
* Field types are matched as whole type names (`JobStatus` no longer links to `Job`); `extends` is drawn as inheritance (`<|--`).
* Optional `layout.flatPackages` (`set separator none`): dotted package names stay flat instead of nesting.

## 0.0.5

* added example models
* added makefile
* additional namespace styling options
* refactor yaml config file structure
* refactor uml namespace generation

## 0.0.4+1

* Fix namespace orphan dot.
* Add namespace border color to config.
* Refactor.
* Update `README.md`

## 0.0.4

* Added exceptions.
* Refactor.
* Update `README.md`

## 0.0.3

* Added color configuration options.
* Added namespace feature.
* Refactor (WIP).

## 0.0.2+1

* More readme fixes.

## 0.0.2

* Readme fixes, refactoring.

## 0.0.1

* Initial release.
